//
//  SapphireTVShowDataMenu.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireTVShowDataMenu.h"
#import "SapphireMetaData.h"
#import "NSString-Extensions.h"
#include <regex.h>

#define TVRAGE_EPLIST_XPATH @"//*[@class='b']"
#define TVRAGE_EP_INFO @".//*[@class='b2']/*"
#define TVRAGE_SCREEN_CAP_XPATH @"//img[contains(@src, 'screencap')]"
#define TVRAGE_SEARCH_XPATH @"//*[@class='b1']/a"
#define TVRAGE_UNKNOWN_XPATH @"//*[contains(text(), 'Unknown Page')]"
 
#define EPISODE_KEY @"Episode"
#define SEASON_KEY @"Season"
#define SUMMARY_KEY @"Description"
#define TITLE_KEY @"Title"
#define LINK_KEY @"Link" 

@interface SapphireTVShowDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
}
- (id)initWithDest:(NSString *)dest;
@end

@implementation SapphireTVShowDataMenuDownloadDelegate
- (id)initWithDest:(NSString *)dest
{
	self = [super init];
	if(!self)
		return nil;
	
	destination = [dest retain];
	
	return self;
}

- (void)dealloc
{
	[destination release];
	[super dealloc];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
	[download setDestination:destination allowOverwrite:YES];
}
@end
 
@interface SapphireImporterDataMenu (private)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)importNextItem:(NSTimer *)timer;
- (void)setCurrentFile:(NSString *)theCurrentFile;
@end

@implementation SapphireTVShowDataMenu

- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData
{
	self = [super initWithScene:scene metaData:metaData];
	if(!self)
		return nil;
	
	showTranslations = [NSMutableDictionary new];
	showInfo = [NSMutableDictionary new];
	
	regcomp(&letterMarking, "[ -]?S[0-9]+E[0-9]+", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonByEpisode, "[ -]?[0-9]+x[0-9]+", REG_EXTENDED | REG_ICASE);
	
	return self;
}

- (void)dealloc
{
	[showTranslations release];
	[showInfo release];
	regfree(&letterMarking);
	regfree(&seasonByEpisode);
	[super dealloc];
}

- (NSString *)getScreencapUrl:(NSString *)epUrl
{
	NSURL *url = [NSURL URLWithString:epUrl];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	NSXMLElement *html = [document rootElement];
	NSArray *caps = [html objectsForXQuery:TVRAGE_SCREEN_CAP_XPATH error:&error];
	if([caps count])
		return [[(NSXMLElement *)[caps objectAtIndex:0] attributeForName:@"src"] stringValue];
	return nil;
}

- (void)addEp:(NSString *)epTitle season:(int)season epNum:(int)ep summary:(NSString *)summary link:(NSString *)epLink toDict:(NSMutableDictionary *)dict
{
	if(ep == 0)
		return;
	
	NSNumber *seasonNum = [NSNumber numberWithInt:season];
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	NSMutableDictionary *epDict = [dict objectForKey:epNum];
	if(epDict == nil)
	{
		epDict = [NSMutableDictionary new];
		[dict setObject:epDict forKey:epNum];
		[epDict release];
	}
	if(ep != 0)
		[epDict setObject:epNum forKey:EPISODE_KEY];
	if(season != 0)
		[epDict setObject:seasonNum forKey:SEASON_KEY];
	if(epTitle != nil)
		[epDict setObject:epTitle forKey:TITLE_KEY];
	if(epLink != nil)
		[epDict setObject:epLink forKey:LINK_KEY];
	if(summary != nil)
		[epDict setObject:summary forKey:SUMMARY_KEY];
}

- (NSMutableDictionary *)getMetaForSeries:(NSString *)seriesName inSeason:(int)season
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	NSCharacterSet *decimalSet = [NSCharacterSet decimalDigitCharacterSet];
	NSCharacterSet *skipSet = [NSCharacterSet characterSetWithCharactersInString:@"- "];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tvrage.com%@/episode_guide/%d", seriesName, season]];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	NSXMLElement *html = [document rootElement];
	NSArray *eps = [html objectsForXQuery:TVRAGE_EPLIST_XPATH error:&error];
	NSEnumerator *epEnum = [eps objectEnumerator];
	NSXMLNode *epNode = nil;
	while((epNode = [epEnum nextObject]) != nil)
	{
		NSString *epTitle = nil;
		NSString *link = nil;
		int season = 0;
		int ep = 0;
		int epNumber = 0;
		NSMutableString *summary = nil;
		
		NSArray *epInfos = [epNode objectsForXQuery:TVRAGE_EP_INFO error:&error];
		NSEnumerator *epInfoEnum = [epInfos objectEnumerator];
		NSXMLNode *epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			if([[epInfo name] isEqualToString:@"a"] && link == nil)
			{
				link = [[(NSXMLElement *)epInfo attributeForName:@"href"] stringValue];
				link = [NSString stringWithFormat:@"http://www.tvrage.com%@", link];
				NSString *epInfoStr = [[epInfo childAtIndex:0] stringValue];
				if(epInfoStr != nil)
				{
					NSScanner *scanner = [NSScanner scannerWithString:epInfoStr];
					if([epInfoStr rangeOfString:@" - " options:0].location != NSNotFound)
					{
						[scanner scanInt:&epNumber];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&season];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&ep];
						[scanner scanCharactersFromSet:skipSet intoString:nil];							
					}
					epTitle = [epInfoStr substringFromIndex:[scanner scanLocation]];
				}
			}
			else if([[epInfo name] isEqualToString:@"font"] && summary == nil)
			{
				NSArray *summarys = [epInfo objectsForXQuery:@"text()" error:&error];
				summary = [NSMutableString string];
				NSEnumerator *sumEnum = [summarys objectEnumerator];
				NSXMLNode *sum = nil;
				while((sum = [sumEnum nextObject]) != nil)
					[summary appendFormat:@"\n%@", [sum stringValue]];
				if([summary length])
					[summary deleteCharactersInRange:NSMakeRange(0,1)];
				else
					summary = nil;
			}
		}
		[self addEp:epTitle season:season epNum:ep summary:summary link:link toDict:ret];
	}
	return ret;
}

- (NSArray *)searchResultsForSeries:(NSString *)searchStr
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tvrage.com/search.php?search=%@&sonly=1", [searchStr URLEncode]]];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	NSXMLElement *root = [document rootElement];
	NSArray *results = [root objectsForXQuery:TVRAGE_SEARCH_XPATH error:&error];
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[results count]];
	if([results count])
	{
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			NSURL *resultURL = [NSURL URLWithString:[[result attributeForName:@"href"] stringValue]];
			if(resultURL == nil)
				continue;
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[[result childAtIndex:0] stringValue], @"name",
				[resultURL path], @"link",
				nil]];
		}
		return ret;
	}
	return nil;
}

- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episode:(int)ep
{
	NSMutableDictionary *showDict = [showInfo objectForKey:show];
	NSMutableDictionary *seasonDict = nil;
	NSMutableDictionary *epDict = nil;
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	NSNumber *seasonNum = [NSNumber numberWithInt:season];
	if(!showDict)
	{
		showDict = [NSMutableDictionary new];
		[showInfo setObject:showDict forKey:show];
		[showDict release];
	}
	else
		seasonDict = [showDict objectForKey:seasonNum];
	if(seasonDict)
		epDict = [seasonDict objectForKey:epNum];
	
	if(epDict == nil)
	{
		seasonDict = [self getMetaForSeries:show inSeason:season];
		if(seasonDict != nil)
			[showDict setObject:seasonDict forKey:seasonNum];
		epDict = [seasonDict objectForKey:epNum];
	}
	return epDict;
}


- (void)getItems
{
	importItems = [[meta subFileMetas] mutableCopy];
}

- (BOOL)doImport
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	if([fileMeta importedFromTV])
		return NO;
	NSString *path = [fileMeta path];
//	NSArray *pathComponents = [path pathComponents];
	NSString *fileName = [path lastPathComponent];
	
	int index = NSNotFound;
	regmatch_t matches[3];
	if(!regexec(&letterMarking, [fileName fileSystemRepresentation], 3, matches, 0))
	{
		index = matches[0].rm_so;
	}
	else if(!regexec(&seasonByEpisode, [fileName fileSystemRepresentation], 3, matches, 0))
	{
		index = matches[0].rm_so;
	}
	
	if(index == NSNotFound)
		return NO;
	
	NSString *searchStr = [fileName substringToIndex:index];
	NSString *show = [showTranslations objectForKey:searchStr];
	if(show == nil)
	{
		NSArray *shows = [self searchResultsForSeries:searchStr];
		show = [[shows objectAtIndex:0] objectForKey:@"link"];
		[showTranslations setObject:show forKey:searchStr];
	}
	
	int season = 0;
	int ep = 0;
	NSScanner *scanner = [NSScanner scannerWithString:[fileName substringFromIndex:index]];
	NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
	[scanner scanUpToCharactersFromSet:digits intoString:nil];
	[scanner scanInt:&season];
	[scanner scanUpToCharactersFromSet:digits intoString:nil];
	[scanner scanInt:&ep];
	if(season == 0 || ep == 0)
		return NO;
	
	NSMutableDictionary *info = [self getInfo:show forSeason:season episode:ep];
	
	NSString *showInfoUrl = [info objectForKey:LINK_KEY];
	NSString *image = nil;
	if(showInfoUrl)
		image = [self getScreencapUrl:showInfoUrl];
	if(image)
	{
		NSURL *imageURL = [NSURL URLWithString:image];
		NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
		NSString *fileName = [path lastPathComponent];
		NSString *coverArtDir = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"<Cover Art>"];
		NSString *newPath = [coverArtDir stringByAppendingPathComponent:fileName];
		[[NSFileManager defaultManager] createDirectoryAtPath:coverArtDir attributes:nil];
		NSString *destination = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
		SapphireTVShowDataMenuDownloadDelegate *myDelegate = [[SapphireTVShowDataMenuDownloadDelegate alloc] initWithDest:destination];
		[[NSURLDownload alloc] initWithRequest:request delegate:myDelegate];
		[myDelegate release];
	}
	
	[info removeObjectForKey:LINK_KEY];
	[info setObject:[NSNumber numberWithBool:YES] forKey:TVRAGE_IMPORT_KEY];
	[fileMeta importInfo:info];
	
	return YES;
}

- (void)setCompletionText
{
	[self setText:@"All availble TV Show data has been imported"];
}

- (void)importNextItem:(NSTimer *)timer
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	NSString * fileName=[[fileMeta path] lastPathComponent] ;
	[self setCurrentFile:[NSString stringWithFormat:@"Current File: %@",fileName]];
	[super importNextItem:timer];
}

- (void)resetUIElements
{
	[super resetUIElements];
	[title setTitle: @"Populate TV Show Data"];
	[self setText:@"This will attempt to fetch information about TV shows automatically.  This procedure may take quite some time and could ask you questions"];
	[button setTitle: @"Import TV Show Data"];
}
@end
