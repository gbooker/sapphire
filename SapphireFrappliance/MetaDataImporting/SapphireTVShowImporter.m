/*
 * SapphireTVShowImporter.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 30, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireTVShowImporter.h"
#import "SapphireFileMetaData.h"
#import "NSString-Extensions.h"
#import "NSFileManager-Extensions.h"
#import "SapphireShowChooser.h"
#import "SapphireMovieChooser.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireTVTranslation.h"
#import "SapphireEpisode.h"
#import "SapphireSettings.h"
#import "NSImage-Extensions.h"


/* TVRage XPATHS  */
#define TVRAGE_SHOWNAME_XPATH @".//font[@size=2][@color=\"white\"]/b/text()"
#define TVRAGE_EPLIST_XPATH @"//*[@class='b']"
#define TVRAGE_EP_INFO @".//*[@class='b2']/*"
#define TVRAGE_EP_TEXT @".//*[@class='b2']/text()"
#define TVRAGE_SCREEN_CAP_XPATH @".//img[contains(@src, 'screencap')]"
#define TVRAGE_SEARCH_XPATH @"//*[@class='b1']/a"
#define TVRAGE_UNKNOWN_XPATH @"//*[contains(text(), 'Unknown Page')]"

#define TRANSLATIONS_KEY		@"Translations"
#define LINK_KEY				@"Link"
#define IMG_URL					@"imgURL"

/*Delegate class to download cover art*/
@interface SapphireTVShowDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
}
- (id)initWithDest:(NSString *)dest;
@end

@implementation SapphireTVShowDataMenuDownloadDelegate
/*!
 * @brief Initialize a cover art downloader
 *
 * @param dest The path to save the file
 */
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

/*!
 * @brief Delegate Method which prompts for location to save file.  Override and set new
 * destination
 *
 * @param download The downloader
 * @param filename The suggested filename
 */
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
	[download setDestination:destination allowOverwrite:YES];
}
@end
 
@interface SapphireTVShowImporter (private)
- (void)writeSettings;
@end

@implementation SapphireTVShowImporter

- (id) initWithContext:(NSManagedObjectContext *)context
{
	self = [super init];
	if(!self)
		return nil;
	
	/*Get the settings*/
	moc = [context retain];
	/*Cached show info*/
	showInfo = [NSMutableDictionary new];
	
	/*Initialize the regexes*/
	regcomp(&letterMarking, "[\\. -]?S[0-9]+E[S0-9]+(-E?[0-9]+)?", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonByEpisode, "[\\. -]?[0-9]+x[S0-9]+(-[0-9]+)?", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonEpisodeTriple, "[\\. -][0-9]{1,3}[S0-9]{2}[\\. -]", REG_EXTENDED | REG_ICASE);	
	return self;
}

- (void)dealloc
{
	[moc release];
	[showInfo release];
	regfree(&letterMarking);
	regfree(&seasonByEpisode);
	regfree(&seasonEpisodeTriple);
	[chooser release];
	[super dealloc];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	dataMenu = theDataMenu;
}

/*!
 * @brief Add an episode's info into our cache dict
 *
 * @param showName The TV Show's name
 * @param epTitle The episode's title
 * @param season The episode's season
 * @param ep The episodes's episode number within the season
 * @param summary The episodes's summary
 * @param eplink The episode's info URL
 * @param epNumber The absolute episode number
 * @param airDate The episode's air date
 * @param imgURL The episode's screenshot URL
 * @param dict The cache dictionary
 */
- (void)addEp:(NSString *)showName title:(NSString *)epTitle season:(int)season epNum:(int)ep summary:(NSString *)summary link:(NSString *)epLink absEpNum:(int)epNumber airDate:(NSDate *)airDate showID:(NSString *)showID imgURL:(NSString *)imgURL toDict:(NSMutableDictionary *)dict
{
	/*Set the key by which to store this.  Either by season/ep or season/title*/
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Adding ep to show %@, title %@, season %d, num %d, sum %@ link %@, absNum %d, date %@, id %@, img %@", showName, epTitle, season, ep, summary, epLink, epNumber, airDate, showID, imgURL);
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	id key = epNum;
	if(ep == 0)
		key = [epTitle lowercaseString];
	
	/*Get the ep dict*/
	NSNumber *seasonNum = [NSNumber numberWithInt:season];
	NSMutableDictionary *epDict = [dict objectForKey:key];
	if(epDict == nil)
	{
		epDict = [NSMutableDictionary new];
		[dict setObject:epDict forKey:key];
		[epDict release];
	}
	/*Add info*/
	if(showName)
	{
		[epDict setObject:showName forKey:META_SHOW_NAME_KEY] ;
	}
	if(ep != 0)
		[epDict setObject:epNum forKey:META_EPISODE_NUMBER_KEY];
	if(season != 0)
	{
		[epDict setObject:seasonNum forKey:META_SEASON_NUMBER_KEY];
	}
	if(epTitle != nil)
		[epDict setObject:epTitle forKey:META_TITLE_KEY];
	if(epLink != nil)
		[epDict setObject:epLink forKey:LINK_KEY];
	if(showID != nil)
		[epDict setObject:showID forKey:META_SHOW_IDENTIFIER_KEY];
	if(summary != nil)
		[epDict setObject:summary forKey:META_DESCRIPTION_KEY];
	if(epNumber != nil)
		[epDict setObject:[NSNumber numberWithInt:epNumber] forKey:META_ABSOLUTE_EP_NUMBER_KEY];
	if(airDate != nil)
		[epDict setObject:airDate forKey:META_SHOW_AIR_DATE];
	if(imgURL != nil)
		[epDict setObject:imgURL forKey:IMG_URL];
}

/*!
 * @brief Fetch information about a season of a show
 *
 * @param seriesName The tvrage series name (part of the show's URL)
 * @param season The season to fech
 * @return A cached dictionary of the season's episodes
 */
- (NSMutableDictionary *)getMetaForSeries:(NSString *)seriesName inSeason:(int)season
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	NSCharacterSet *decimalSet = [NSCharacterSet decimalDigitCharacterSet];
	/*Get the season's html*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tvrage.com%@/episode_guide/%d", seriesName, season]];
	NSError *error = nil;
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error] autorelease];
	/* Dump XML document to disk (Dev Only) */
/*	NSString *documentPath =[applicationSupportDir() stringByAppendingPathComponent:@"XML"];
	[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"/%@%@.xml",documentPath,seriesName] atomically:YES] ;*/
	/*Get the episode list*/
	if(error != nil && ![[error domain] isEqualToString:@"NSXMLParserErrorDomain"])
	{
		/*Error fetching data; return nil*/
		return nil;
	}
	NSString *showName= nil;
	
	
	NSXMLElement *html = [document rootElement];
	
	NSArray *titleArray=[html objectsForXQuery:TVRAGE_SHOWNAME_XPATH error:&error];
	if([titleArray count])
	{
		showName=[[titleArray objectAtIndex:0] stringValue];
		int length = [showName length];
		if([showName characterAtIndex:length - 1] == '\n')
			showName = [showName substringToIndex:length - 1];
/*		int index = [showName rangeOfString:@"Season" options:0].location;
		if(index != NSNotFound)
			showName = [showName substringToIndex:index - 1];*/
	}

	NSArray *eps = [html objectsForXQuery:TVRAGE_EPLIST_XPATH error:&error];
	NSEnumerator *epEnum = [eps objectEnumerator];
	NSXMLNode *epNode = nil;
	while((epNode = [epEnum nextObject]) != nil)
	{
		/*Parse the episode's info*/
		NSString *epTitle = nil;
		NSString *link = nil;
		int seasonNum = 0;
		int ep = 0;
		int epNumber = 0;
		NSString *summary = nil;
		NSDate *airDate = nil;
		NSString *imageURL = nil;
		
		/*Get the info pieces*/
		NSArray *epInfos = [epNode objectsForXQuery:TVRAGE_EP_INFO error:&error];
		NSEnumerator *epInfoEnum = [epInfos objectEnumerator];
		NSXMLNode *epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			NSString *nodeName = [epInfo name];
			NSArray *summaryObjects = [epInfo objectsForXQuery:@".//font" error:&error];
			if([summaryObjects count] && ![nodeName isEqualToString:@"font"])
			{
				/*Sometimes, the summary is inside formatting, strip*/
				epInfo = [summaryObjects objectAtIndex:0];
				nodeName = [epInfo name];
			}
			if(link == nil && [nodeName isEqualToString:@"a"])
			{
				/*Get the URL*/
				link = [[(NSXMLElement *)epInfo attributeForName:@"href"] stringValue];
				link = [NSString stringWithFormat:@"http://www.tvrage.com%@", link];
				/*Parse the name*/
				NSString *epInfoStr = [[epInfo childAtIndex:0] stringValue];
				if(epInfoStr != nil)
				{
					/*Get the season number and ep numbers*/
					NSScanner *scanner = [NSScanner scannerWithString:epInfoStr];
					NSRange range = [epInfoStr rangeOfString:@" - " options:0];
					if(range.location != NSNotFound)
					{
						[scanner scanInt:&epNumber];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&seasonNum];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&ep];
						[scanner setScanLocation:range.length + range.location];
						if(seasonNum == 0)
							seasonNum = season;
					}
					else
						seasonNum = season;
					epTitle = [epInfoStr substringFromIndex:[scanner scanLocation]];
				}
			}
			else if(summary == nil && [nodeName isEqualToString:@"font"])
			{
				/*Get the summary*/
				NSArray *summaries = [epInfo objectsForXQuery:@"string()" error:&error];
				summary = [summaries componentsJoinedByString:@"\n"];
				NSMutableString *mutSummary = [summary mutableCopy];
				[mutSummary replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:0 range:NSMakeRange(0, [summary length])];
				summary = [NSString stringWithString:mutSummary];
				[mutSummary release];
				
				if([summary length] > 3 && [[summary substringFromIndex:3] isEqualToString:@"No Summary (Add Here)"])
					summary = nil;
				if(![summary length])
					summary = nil;
			}
			else if(imageURL == nil)
			{
				NSArray *images = [epInfo objectsForXQuery:TVRAGE_SCREEN_CAP_XPATH error:&error];
				if([images count])
				{
					imageURL = [[(NSXMLElement *)[images objectAtIndex:0] attributeForName:@"src"] stringValue];
				}
			}
		}
		epInfos = [epNode objectsForXQuery:TVRAGE_EP_TEXT error:&error];
		epInfoEnum = [epInfos objectEnumerator];
		epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			/*Get the air date*/
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
		/*Add to cache*/
		[self addEp:showName title:epTitle season:seasonNum epNum:ep summary:summary link:link absEpNum:epNumber airDate:airDate showID:seriesName imgURL:imageURL toDict:ret];
	}
	return ret;
}

/*!
 * @brief Searches for a show based on the filename
 *
 * @param searchStr Part of the filename to use in the show search
 * @return An array of possible results
 */
- (NSArray *)searchResultsForSeries:(NSString *)searchStr
{
	/*Load the search info*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tvrage.com/search.php?search=%@&sonly=1", [searchStr URLEncode]]];
	NSError *error = nil;
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error] autorelease];
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Document is %@", document);
	if(error != nil && ![[error domain] isEqualToString:@"NSXMLParserErrorDomain"])
	{
		/*Error fetching data*/
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Got Error %@, %@", [error domain], [error userInfo]);
		return nil;
	}
	
	/*Get the results list*/
	NSXMLElement *root = [document rootElement];
	NSArray *results = [root objectsForXQuery:TVRAGE_SEARCH_XPATH error:&error];
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Got raw search results %@", results);
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[results count]];
	if([results count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			/*Add the result to the list*/
			NSURL *resultURL = [NSURL URLWithString:[[result attributeForName:@"href"] stringValue]];
			if(resultURL == nil)
				continue;
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[[result childAtIndex:0] stringValue], @"name",
				[resultURL path], LINK_KEY,
				nil]];
		}
		return ret;
	}
	/*No results found*/
	return [NSArray array];
}

/*!
 * @brief Fetch cached information about a show's season, and if none, fetch it
 *
 * @param show The tvrage series name
 * @param season The season to fetch
 * @return A dictionary with info about the season
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season
{
	/*Get the show's info*/
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
		/*Get the season's info*/
		seasonDict = [showDict objectForKey:seasonNum];
	if(!seasonDict)
	{
		/*Not in cache, so fetch it*/
		seasonDict = [self getMetaForSeries:show inSeason:season];
		if(seasonDict != nil)
			/*Put the result in cache*/
			[showDict setObject:seasonDict forKey:seasonNum];
	}
	/*Return the info*/
	return seasonDict;
}

/*!
 * @brief Get info about a show's episode from a key
 *
 * @param show The tvrage show name
 * @param season The episode's season
 * @param key The lookup key to use
 * @return nil if network failure, empty dictionary if info doesn't exist, otherwise the episode's info
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season key:(id)key
{
	NSMutableDictionary *seasonDict = [self getInfo:show forSeason:season];
	if(seasonDict == nil)
		return nil;
	NSDictionary *ret = [seasonDict objectForKey:key];
	if(ret != nil)
		return [NSMutableDictionary dictionaryWithDictionary:ret];
	return [NSDictionary dictionary];
}

/*!
 * @brief Get info about a show's episode
 *
 * @param show The tvrage show name
 * @param season The episode's season
 * @param ep The episode's episode number
 * @return nil if network failure, empty dictionary if info doesn't exist, otherwise the episode's info
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episode:(int)ep
{
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	return [self getInfo:show forSeason:season key:epNum];
}

/*!
 * @brief Get info about a show's episode which doesn't have an episode number (specials)
 *
 * @param show The tvrage show name
 * @param season The episode's season
 * @param epTitle The episode's title
 * @return nil if network failure, empty dictionary if info doesn't exist, otherwise the episode's info
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episodeTitle:(NSString *)epTitle
{
	return [self getInfo:show forSeason:season key:[epTitle lowercaseString]];
}

/*!
 * @brief Write our setings out
 */
- (void)writeSettings
{
	NSError *error = nil;
	[moc save:&error];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	currentData = metaData;
	/*Check to see if it is already imported*/
	if([metaData importTypeValue] & IMPORT_TYPE_TVSHOW_MASK)
		return IMPORT_STATE_NOT_UPDATED;
	id controller = [[dataMenu stack] peekController];
	/* Check to see if we are waiting on the user to select a movie title */
	if(controller != nil && ![controller isKindOfClass:[SapphireImporterDataMenu class]])
	{
		/* Another chooser is on the screen - delay further processing */
		return IMPORT_STATE_NOT_UPDATED;
	}
//	NSArray *pathComponents = [path pathComponents];
	NSString *fileName = [path lastPathComponent];
	
	/*Check regexes to see if this is a tv show*/
	int index = NSNotFound;
	int secondEp = -1;
	regmatch_t matches[3];
	const char *theFileName = [fileName fileSystemRepresentation];
	NSString *scanString = nil;
	if(!regexec(&letterMarking, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
		secondEp = matches[1].rm_so;
	}
	else if(!regexec(&seasonByEpisode, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
		secondEp = matches[1].rm_so;
	}
	else if(!regexec(&seasonEpisodeTriple, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		/*Insert an artificial season/ep seperator so things are easier later*/
		NSMutableString *tempStr = [fileName mutableCopy];
//		if(index > [tempStr length] || index <= 0 )return NO;
		[tempStr deleteCharactersInRange:NSMakeRange(0, index+1)];
		[tempStr insertString:@"x" atIndex:matches[0].rm_eo - index - 4];
		scanString = [tempStr autorelease];
	}
	
	/*See if we found a match*/
	if(index == NSNotFound)
		return IMPORT_STATE_NOT_UPDATED;
	
	/*Get the show title*/
	NSString *searchStr = [fileName substringToIndex:index];
	NSString *searchShowName = [metaData searchShowName];
	if(searchShowName != nil)
		searchStr = searchShowName;
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"%@ matched regex; checking show name %@", fileName, searchStr);
	/*Check to see if we know this title*/
	SapphireTVTranslation *tran = [SapphireTVTranslation tvTranslationForName:[searchStr lowercaseString] inContext:moc];
	if([tran showPath] == nil)
	{
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Conducting search");
		if(dataMenu == nil)
			/*There is no data menu, background import. So we can't ask user, skip*/
			return IMPORT_STATE_NOT_UPDATED;
		/*Ask the user what show this is*/
		NSArray *shows = [self searchResultsForSeries:searchStr];
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Found shows %@", shows);
		if(shows == nil)
			return IMPORT_STATE_NOT_UPDATED;
		
		if([[SapphireSettings sharedSettings] autoSelection])
		{
			NSString *path = [[shows objectAtIndex:0] objectForKey:LINK_KEY];
			if(tran == nil)
				tran = [SapphireTVTranslation createTVTranslationForName:[searchStr lowercaseString] withPath:path inContext:moc];
			else
				[tran setShowPath:path];
		}
		else
		{
			/*Bring up the prompt*/
			chooser = [[SapphireShowChooser alloc] initWithScene:[dataMenu scene]];
			[chooser setShows:shows];
			[chooser setFileName:fileName];
			[chooser setListTitle:BRLocalizedString(@"Select Show Title", @"Prompt the user for showname with a file")];
			[chooser setSearchStr:searchStr];
			/*And display prompt*/
			[[dataMenu stack] pushController:chooser];
			return IMPORT_STATE_NEEDS_SUSPEND;
		}
	}
	
	int season = 0;
	int ep = 0;
	/*Get the season*/
	NSScanner *scanner = [NSScanner scannerWithString:scanString];
	NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
	[scanner scanUpToCharactersFromSet:digits intoString:nil];
	[scanner scanInt:&season];
	/*Get the episode number*/
	NSString *skipped = nil;
	[scanner scanUpToCharactersFromSet:digits intoString:&skipped];
	[scanner scanInt:&ep];
	/*Was there an S before the episode number?*/
	if([skipped hasSuffix:@"S"] || [skipped hasSuffix:@"s"])
		ep = 0;
	
	int overriddenSeason = [metaData searchSeasonNumber];
	if(overriddenSeason != -1)
		season = overriddenSeason;

	int overriddenEpisode = [metaData searchEpisodeNumber];
	if(overriddenEpisode != -1)
		ep = overriddenEpisode;

	/*No season, no info*/
	if(season == 0)
		return IMPORT_STATE_NOT_UPDATED;
	
	int otherEp = 0;
	if(secondEp != -1)
	{
		[scanner setScanLocation:secondEp - index];
		[scanner scanUpToCharactersFromSet:digits intoString:nil];
		[scanner scanInt:&otherEp];
	}
	
	overriddenEpisode = [metaData searchLastEpisodeNumber];
	if(overriddenEpisode != -1)
		otherEp = overriddenEpisode;

	/*Get the episode's info*/
	NSMutableDictionary *info = nil, *info2 = nil;
	if(ep != 0)
	{
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Importing TV show %@ %d %d %d", [tran showPath], season, ep, otherEp);
		/*Match on s/e*/
		info = [self getInfo:[tran showPath] forSeason:season episode:ep];
		if(otherEp != 0)
			info2 = [self getInfo:[tran showPath] forSeason:season episode:otherEp];
	}
	else
	{
		/*Match on show title*/
		NSString *showTitle = nil;
		[scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:nil];
		if([scanner scanUpToString:@"." intoString:&showTitle])
			info = [self getInfo:[tran showPath] forSeason:season episodeTitle:showTitle];
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Searching for title \"%@\"", showTitle);
	}
	/*No info, well, no info, so we didn't import*/
	if(info == nil)
		return IMPORT_STATE_NOT_UPDATED;
	if(![info count])
	{
		/*Our search was successful, but there's no tv episode data, so it doesn't try to import again.*/
		[metaData didImportType:IMPORT_TYPE_TVSHOW_MASK];
		return IMPORT_STATE_NOT_UPDATED;
	}
	
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Import info is %@", info);
		
	/* Lets process the cover art directory structure */
	NSString * previewArtPath = [NSFileManager previewArtPathForTV:[info objectForKey:META_SHOW_NAME_KEY] season:[[info objectForKey:META_SEASON_NUMBER_KEY] intValue]];
						
	[[NSFileManager defaultManager] constructPath:previewArtPath];
	/*Check for screen cap locally and on server*/
	NSString *imgURL = [info objectForKey:IMG_URL];
	NSString *newPath = nil;
	if(ep != 0)
		newPath = [previewArtPath stringByAppendingFormat:@"/Episode %d", ep];
	else
		newPath = [previewArtPath stringByAppendingPathComponent:[info objectForKey:META_TITLE_KEY]];
	NSString *imageDestination = [newPath stringByAppendingPathExtension:@"jpg"];
	BOOL isDir = NO;
	BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imageDestination isDirectory:&isDir] && !isDir;
	if(imgURL && !imageExists)
	{
		/*Download the screen cap*/
		NSURL *imageURL = [NSURL URLWithString:imgURL];
		NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
		SapphireTVShowDataMenuDownloadDelegate *myDelegate = [[SapphireTVShowDataMenuDownloadDelegate alloc] initWithDest:imageDestination];
		[[[NSURLDownload alloc] initWithRequest:request delegate:myDelegate] autorelease];
		[myDelegate release];
	}
	else if(!imageExists)
	{
		//QTMovie is broken on ATV, don't fetch images there
		if ([SapphireFrontRowCompat usingLeopard] && [metaData fileContainerTypeValue] == FILE_CONTAINER_TYPE_QT_MOVIE)
		{
			// NSImage-Extensions
			[[NSImage imageFromMovie:path] writeToFile:imageDestination atomically:YES];
		}
	}
	
	/*Import the info*/
	[info removeObjectForKey:LINK_KEY];
	SapphireEpisode *episode = [SapphireEpisode episodeWithDictionary:info inContext:moc];
	if(info2 != nil)
		[episode insertAdditionalEpisode:info2];
	[metaData setTvEpisode:episode];
	[tran setTvShow:[episode tvShow]];
	
	/*We imported something*/
	return IMPORT_STATE_UPDATED;
}

- (NSString *)completionText
{
	return BRLocalizedString(@"All available TV Show data has been imported", @"The TV Show import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Fetch TV Show Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will attempt to fetch information about your TV shows files from the Internet (TVRage).  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of the movie import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Fetching Data", @"Button");
}

- (void)wasExhumed
{
	/*See if it was a show chooser*/
	if(chooser == nil)
		return;
	
	/*Get the user's selection*/
	int selection = [chooser selection];
	if(selection == SHOW_CHOOSE_CANCEL)
		/*They aborted, skip*/
		[dataMenu skipNextItem];
	else if(selection == SHOW_CHOOSE_NOT_SHOW)
	{
		/*They said it is not a show, so put in empty data so they are not asked again*/
		[currentData didImportType:IMPORT_TYPE_TVSHOW_MASK];
		if ([currentData fileClassValue] == FILE_CLASS_TV_SHOW)
			[currentData setFileClassValue:FILE_CLASS_UNKNOWN];
	}
	else
	{
		/*They selected a show, save the translation and write it*/
		NSDictionary *show = [[chooser shows] objectAtIndex:selection];
		[SapphireTVTranslation createTVTranslationForName:[[chooser searchStr] lowercaseString] withPath:[show objectForKey:LINK_KEY] inContext:moc];
		[self writeSettings];
	}
	[chooser release];
	chooser = nil;
	/*We can resume now*/
	[dataMenu resume];
}

@end
