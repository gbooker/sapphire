//
//  SapphireTVShowDataMenu.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireTVShowDataMenu.h"
#import "SapphireMetaData.h"
#import "NSString-Extensions.h"
#import "SapphireShowChooser.h"

#define TVRAGE_EPLIST_XPATH @"//*[@class='b']"
#define TVRAGE_EP_INFO @".//*[@class='b2']/*"
#define TVRAGE_EP_TEXT @".//*[@class='b2']/text()"
#define TVRAGE_SCREEN_CAP_XPATH @"//img[contains(@src, 'screencap')]"
#define TVRAGE_SEARCH_XPATH @"//*[@class='b1']/a"
#define TVRAGE_UNKNOWN_XPATH @"//*[contains(text(), 'Unknown Page')]"
 
#define LINK_KEY @"Link" 

#define TRANSLATIONS_KEY		@"Translations"

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
- (void)pause;
- (void)resume;
- (void)skipNextItem;
@end

@interface SapphireTVShowDataMenu (private)
- (void)writeSettings;
@end

@implementation SapphireTVShowDataMenu

- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData savedSetting:(NSString *)path
{
	self = [super initWithScene:scene metaData:metaData];
	if(!self)
		return nil;
	
	settingsPath = [path retain];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	showTranslations = [[settings objectForKey:TRANSLATIONS_KEY] mutableCopy];
	if(showTranslations == nil)
		showTranslations = [NSMutableDictionary new];
	showInfo = [NSMutableDictionary new];
	
	regcomp(&letterMarking, "[\\. -]?S[0-9]+E[S0-9]+", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonByEpisode, "[\\. -]?[0-9]+x[S0-9]+", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonEpisodeTriple, "[\\. -][0-9]{1,3}[S0-9]{2}[\\. -]", REG_EXTENDED | REG_ICASE);	
	return self;
}

- (void)dealloc
{
	[showTranslations release];
	[showInfo release];
	[settingsPath release];
	regfree(&letterMarking);
	regfree(&seasonByEpisode);
	regfree(&seasonEpisodeTriple);
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

- (void)addEp:(NSString *)epTitle season:(int)season epNum:(int)ep summary:(NSString *)summary link:(NSString *)epLink  absEpNum:(int)epNumber airDate:(NSDate *)airDate toDict:(NSMutableDictionary *)dict
{
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	id key = epNum;
	if(ep == 0)
		key = [epTitle lowercaseString];
	
	NSNumber *seasonNum = [NSNumber numberWithInt:season];
	NSMutableDictionary *epDict = [dict objectForKey:key];
	if(epDict == nil)
	{
		epDict = [NSMutableDictionary new];
		[dict setObject:epDict forKey:key];
		[epDict release];
	}
	if(ep != 0)
		[epDict setObject:epNum forKey:META_EPISODE_NUMBER_KEY];
	if(season != 0)
		[epDict setObject:seasonNum forKey:META_SEASON_NUMBER_KEY];
	if(epTitle != nil)
		[epDict setObject:epTitle forKey:META_TITLE_KEY];
	if(epLink != nil)
		[epDict setObject:epLink forKey:LINK_KEY];
	if(summary != nil)
		[epDict setObject:summary forKey:META_DESCRIPTION_KEY];
	if(epNumber != nil)
		[epDict setObject:[NSNumber numberWithInt:epNumber] forKey:META_ABSOLUTE_EP_NUMBER_KEY];
	if(airDate != nil)
		[epDict setObject:airDate forKey:META_SHOW_AIR_DATE];
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
		NSDate *airDate = nil;
		
		NSArray *epInfos = [epNode objectsForXQuery:TVRAGE_EP_INFO error:&error];
		NSEnumerator *epInfoEnum = [epInfos objectEnumerator];
		NSXMLNode *epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			NSString *nodeName = [epInfo name];
			if(link == nil && [nodeName isEqualToString:@"a"])
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
			else if(summary == nil && [nodeName isEqualToString:@"font"])
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
		epInfos = [epNode objectsForXQuery:TVRAGE_EP_TEXT error:&error];
		epInfoEnum = [epInfos objectEnumerator];
		epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			NSString *nodeName = [epInfo stringValue];
			if ([nodeName hasPrefix:@" ("] && [nodeName hasSuffix:@") "])
			{
				NSString *subStr = [nodeName substringWithRange:NSMakeRange(2, [nodeName length] - 4)];
				
				airDate = [NSDate dateWithNaturalLanguageString:subStr];
				if([airDate timeIntervalSince1970] == 0)
					airDate = nil;
				else
					break;
			}
		}
		[self addEp:epTitle season:season epNum:ep summary:summary link:link absEpNum:epNumber airDate:airDate toDict:ret];
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

- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season
{
	NSMutableDictionary *showDict = [showInfo objectForKey:show];
	NSMutableDictionary *seasonDict = nil;
	NSNumber *seasonNum = [NSNumber numberWithInt:season];
	if(!showDict)
	{
		showDict = [NSMutableDictionary new];
		[showInfo setObject:showDict forKey:show];
		[showDict release];
	}
	else
		seasonDict = [showDict objectForKey:seasonNum];
	if(!seasonDict)
	{
		seasonDict = [self getMetaForSeries:show inSeason:season];
		if(seasonDict != nil)
			[showDict setObject:seasonDict forKey:seasonNum];
	}
	return seasonDict;
}

- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episode:(int)ep
{
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	return [NSMutableDictionary dictionaryWithDictionary:[[self getInfo:show forSeason:season] objectForKey:epNum]];
}

- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episodeTitle:(NSString *)epTitle
{
	return [NSMutableDictionary dictionaryWithDictionary:[[self getInfo:show forSeason:season] objectForKey:[epTitle lowercaseString]]];
}

- (void)writeSettings
{
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
		showTranslations, TRANSLATIONS_KEY,
		nil];
	[settings writeToFile:settingsPath atomically:YES];
}

- (void)getItems
{
	importItems = [[meta subFileMetas] mutableCopy];
}

- (BOOL)doImport
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	if([fileMeta importedTimeFromSource:META_TVRAGE_IMPORT_KEY])
		return NO;
	NSString *path = [fileMeta path];
//	NSArray *pathComponents = [path pathComponents];
	NSString *fileName = [path lastPathComponent];
	
	int index = NSNotFound;
	regmatch_t matches[3];
	const char *theFileName = [fileName fileSystemRepresentation];
	NSString *scanString = nil;
	if(!regexec(&letterMarking, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
	}
	else if(!regexec(&seasonByEpisode, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
	}
	else if(!regexec(&seasonEpisodeTriple, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so + 1;
		NSMutableString *tempStr = [fileName mutableCopy];
		[tempStr deleteCharactersInRange:NSMakeRange(0, index)];
		[tempStr insertString:@"x" atIndex:matches[0].rm_eo - index - 3];
		scanString = [tempStr autorelease];
	}
	
	if(index == NSNotFound)
		return NO;
	
	NSString *searchStr = [fileName substringToIndex:index];
	NSString *show = [showTranslations objectForKey:[searchStr lowercaseString]];
	if(show == nil)
	{
		NSArray *shows = [self searchResultsForSeries:searchStr];
		[self pause];
		SapphireShowChooser *chooser = [[SapphireShowChooser alloc] initWithScene:[self scene]];
		[chooser setShows:shows];
		[chooser setListTitle:[BRLocalizedString(@"Show? ", @"Prompt the user for showname with a file") stringByAppendingString:fileName]];
		[chooser setSearchStr:searchStr];
		[[self stack] pushController:chooser];
		return NO;
	}
	
	int season = 0;
	int ep = 0;
	NSScanner *scanner = [NSScanner scannerWithString:scanString];
	NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
	[scanner scanUpToCharactersFromSet:digits intoString:nil];
	[scanner scanInt:&season];
	NSString *skipped = nil;
	[scanner scanUpToCharactersFromSet:digits intoString:&skipped];
	[scanner scanInt:&ep];
	if([skipped hasSuffix:@"S"])
		ep = 0;
	if(season == 0)
		return NO;
	
	NSMutableDictionary *info = nil;
	if(ep != 0)
		info = [self getInfo:show forSeason:season episode:ep];
	else
	{
		NSString *showTitle = nil;
		[scanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
		if([scanner scanUpToString:@"." intoString:&showTitle])
			info = [self getInfo:show forSeason:season episodeTitle:showTitle];
	}
	if(!info)
		return NO;
	
	NSString *showInfoUrl = [info objectForKey:LINK_KEY];
	NSString *image = nil;
	NSString *coverArtDir = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"];
	NSString *newPath = [coverArtDir stringByAppendingPathComponent:fileName];
	NSString *imageDestination = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
	BOOL isDir = NO;
	BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imageDestination isDirectory:&isDir] && !isDir;
	if(showInfoUrl && !imageExists)
		image = [self getScreencapUrl:showInfoUrl];
	if(image)
	{
		NSURL *imageURL = [NSURL URLWithString:image];
		NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
		[[NSFileManager defaultManager] createDirectoryAtPath:coverArtDir attributes:nil];
		SapphireTVShowDataMenuDownloadDelegate *myDelegate = [[SapphireTVShowDataMenuDownloadDelegate alloc] initWithDest:imageDestination];
		[[NSURLDownload alloc] initWithRequest:request delegate:myDelegate];
		[myDelegate release];
	}
	
	[info removeObjectForKey:LINK_KEY];
	[fileMeta importInfo:info fromSource:META_TVRAGE_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
	
	return YES;
}

- (void)setCompletionText
{
	[self setText:BRLocalizedString(@"All availble TV Show data has been imported", @"The TV Show import complete")];
}

- (void)importNextItem:(NSTimer *)timer
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	NSString * fileName=[[fileMeta path] lastPathComponent] ;
	[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Current File: %@", "Current TV Show import process format, filename"),fileName]];
	[super importNextItem:timer];
}

- (void)resetUIElements
{
	[super resetUIElements];
	[title setTitle: BRLocalizedString(@"Populate TV Show Data", @"Title")];
	[self setText:BRLocalizedString(@"This will attempt to fetch information about TV shows automatically.  This procedure may take quite some time and could ask you questions", @"Description of the tv show import")];
	[button setTitle: BRLocalizedString(@"Import TV Show Data", @"Button")];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	[super wasExhumedByPoppingController:controller];
	if(![controller isKindOfClass:[SapphireShowChooser class]])
		return;
	
	SapphireShowChooser *chooser = (SapphireShowChooser *)controller;
	int selection = [chooser selection];
	if(selection == SHOW_CHOOSE_CANCEL)
		[self skipNextItem];
	else if(selection == SHOW_CHOOSE_NOT_SHOW)
		[[importItems objectAtIndex:0] importInfo:[NSMutableDictionary dictionary] fromSource:META_TVRAGE_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
	else
	{
		NSDictionary *show = [[chooser shows] objectAtIndex:selection];
		[showTranslations setObject:[show objectForKey:@"link"] forKey:[[chooser searchStr] lowercaseString]];
		[self writeSettings];
	}
	[self resume];
}

@end
