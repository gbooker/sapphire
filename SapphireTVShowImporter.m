//
//  SapphireTVShowDataMenu.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTVShowImporter.h"
#import "SapphireMetaData.h"
#import "NSString-Extensions.h"
#import "SapphireShowChooser.h"
#import "SapphireMovieChooser.h"

/* TVRage XPATHS  */
#define TVRAGE_SHOWNAME_XPATH @".//h3/text()"
#define TVRAGE_EPLIST_XPATH @"//*[@class='b']"
#define TVRAGE_EP_INFO @".//*[@class='b2']/*"
#define TVRAGE_EP_TEXT @".//*[@class='b2']/text()"
#define TVRAGE_SCREEN_CAP_XPATH @"//img[contains(@src, 'screencap')]"
#define TVRAGE_SEARCH_XPATH @"//*[@class='b1']/a"
#define TVRAGE_UNKNOWN_XPATH @"//*[contains(text(), 'Unknown Page')]"

#define TRANSLATIONS_KEY		@"Translations"
#define LINK_KEY				@"Link"

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

- (id) initWithSavedSetting:(NSString *)path
{
	self = [super init];
	if(!self)
		return nil;
	
	/*Get the settings*/
	settingsPath = [path retain];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	/*Get or create the show translation dict*/
	showTranslations = [[settings objectForKey:TRANSLATIONS_KEY] mutableCopy];
	if(showTranslations == nil)
		showTranslations = [NSMutableDictionary new];
	/*Cached show info*/
	showInfo = [NSMutableDictionary new];
	
	/*Initialize the regexes*/
	regcomp(&letterMarking, "[\\. -]?S[0-9]+E[S0-9]+", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonByEpisode, "[\\. -]?[0-9]+x[S0-9]+", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonEpisodeTriple, "[\\. -][0-9]{1,3}[S0-9]{2}[\\. -]", REG_EXTENDED | REG_ICASE);	
	return self;
}

- (void)dealloc
{
	[dataMenu release];
	[showTranslations release];
	[showInfo release];
	[settingsPath release];
	regfree(&letterMarking);
	regfree(&seasonByEpisode);
	regfree(&seasonEpisodeTriple);
	[super dealloc];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[dataMenu release];
	dataMenu = [theDataMenu retain];
}

/*!
 * @brief Fetches the screencap URL from a show's info URL
 *
 * @param epUrl The show's info URL
 * @return The screencap URL if it exists, nil otherwise
 */
- (NSString *)getScreencapUrl:(NSString *)epUrl
{
	/*Get the HTML document*/
	NSURL *url = [NSURL URLWithString:epUrl];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	/*Search for a screencap*/
	NSXMLElement *html = [document rootElement];
	NSArray *caps = [html objectsForXQuery:TVRAGE_SCREEN_CAP_XPATH error:&error];
	if([caps count])
		/*Found one; return it*/
		return [[(NSXMLElement *)[caps objectAtIndex:0] attributeForName:@"src"] stringValue];
	/*None found*/
	return nil;
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
 * @param dict The cache dictionary
 */
- (void)addEp:(NSString *)showName title:(NSString *)epTitle season:(int)season epNum:(int)ep summary:(NSString *)summary link:(NSString *)epLink absEpNum:(int)epNumber airDate:(NSDate *)airDate showID:(NSString *)showID toDict:(NSMutableDictionary *)dict
{
	/*Set the key by which to store this.  Either by season/ep or season/title*/
	NSString * previewArtPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Preview Art/"];
	NSFileManager *FM=[NSFileManager defaultManager];
	[FM createDirectoryAtPath:previewArtPath attributes:nil];
	previewArtPath=[previewArtPath stringByAppendingPathComponent:@"@TV"];
	[FM createDirectoryAtPath:previewArtPath attributes:nil];
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
		previewArtPath=[previewArtPath stringByAppendingPathComponent:showName];
		[FM createDirectoryAtPath:previewArtPath attributes:nil];
		[epDict setObject:showName forKey:META_SHOW_NAME_KEY] ;
	}
	if(ep != 0)
		[epDict setObject:epNum forKey:META_EPISODE_NUMBER_KEY];
	if(season != 0)
	{
		previewArtPath=[previewArtPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Season %d",season]];
		[FM createDirectoryAtPath:previewArtPath attributes:nil];
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
	NSCharacterSet *skipSet = [NSCharacterSet characterSetWithCharactersInString:@"- "];
	/*Get the season's html*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tvrage.com%@/episode_guide/%d", seriesName, season]];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	/* Dump XML document to disk (Dev Only) */
/*	NSString *documentPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/XML"];
	[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"/%@%@.xml",documentPath,seriesName] atomically:YES] ;*/
	/*Get the episode list*/
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
		NSMutableString *summary = nil;
		NSDate *airDate = nil;
		
		/*Get the info pieces*/
		NSArray *epInfos = [epNode objectsForXQuery:TVRAGE_EP_INFO error:&error];
		NSEnumerator *epInfoEnum = [epInfos objectEnumerator];
		NSXMLNode *epInfo = nil;
		while((epInfo = [epInfoEnum nextObject]) != nil)
		{
			NSString *nodeName = [epInfo name];
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
					if([epInfoStr rangeOfString:@" - " options:0].location != NSNotFound)
					{
						[scanner scanInt:&epNumber];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&seasonNum];
						[scanner scanUpToCharactersFromSet:decimalSet intoString:nil];
						[scanner scanInt:&ep];
						[scanner scanCharactersFromSet:skipSet intoString:nil];							
					}
					else
						seasonNum = season;
					epTitle = [epInfoStr substringFromIndex:[scanner scanLocation]];
				}
			}
			else if(summary == nil && [nodeName isEqualToString:@"font"])
			{
				/*Get the summary*/
				NSArray *summarys = [epInfo objectsForXQuery:@"replace(string(), '\n\n', '\n')" error:&error];
				summary = [NSMutableString string];
				NSEnumerator *sumEnum = [summarys objectEnumerator];
				NSXMLNode *sum = nil;
				while((sum = [sumEnum nextObject]) != nil)
					[summary appendFormat:@"\n%@", sum];
				if([[summary substringFromIndex:3] isEqualToString:@"No Summary (Add Here)"])
					summary = nil;
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
		[self addEp:showName title:epTitle season:seasonNum epNum:ep summary:summary link:link absEpNum:epNumber airDate:airDate showID:seriesName toDict:ret];
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
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	/*Get the results list*/
	NSXMLElement *root = [document rootElement];
	NSArray *results = [root objectsForXQuery:TVRAGE_SEARCH_XPATH error:&error];
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
				[resultURL path], @"link",
				nil]];
		}
		return ret;
	}
	/*No results found*/
	return nil;
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
 * @brief Get info about a show's episode
 *
 * @param show The tvrage show name
 * @param season The episode's season
 * @param ep The episode's episode number
 * @return The episode's info
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episode:(int)ep
{
	NSNumber *epNum = [NSNumber numberWithInt:ep];
	return [NSMutableDictionary dictionaryWithDictionary:[[self getInfo:show forSeason:season] objectForKey:epNum]];
}

/*!
 * @brief Get info about a show's episode which doesn't have an episode number (specials)
 *
 * @param show The tvrage show name
 * @param season The episode's season
 * @param epTitle The episode's title
 * @return The episode's info
 */
- (NSMutableDictionary *)getInfo:(NSString *)show forSeason:(int)season episodeTitle:(NSString *)epTitle
{
	return [NSMutableDictionary dictionaryWithDictionary:[[self getInfo:show forSeason:season] objectForKey:[epTitle lowercaseString]]];
}

/*!
 * @brief Write our setings out
 */
- (void)writeSettings
{
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
		showTranslations, TRANSLATIONS_KEY,
		nil];
	[settings writeToFile:settingsPath atomically:YES];
}

- (BOOL) importMetaData:(SapphireFileMetaData *)metaData
{
	currentData = metaData;
	/*Check to see if it is already imported*/
	if([metaData importedTimeFromSource:META_TVRAGE_IMPORT_KEY])
		return NO;
	id controller = [[dataMenu stack] peekController];
	/* Check to see if we are waiting on the user to select a movie title */
	if([controller isKindOfClass:[SapphireMovieChooser class]])
	{
		/* Another chooser is on the screen - delay further processing */
		return NO;
	}
	/*Get path*/
	NSString *path = [metaData path];
//	NSArray *pathComponents = [path pathComponents];
	NSString *fileName = [path lastPathComponent];
	
	/*Check regexes to see if this is a tv show*/
	int index = NSNotFound;
	regmatch_t matches[3];
	NSData *fileNameData = [fileName dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	const char *theFileName = [fileNameData bytes];
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
		/*Insert an artificial season/ep seperator so things are easier later*/
		NSMutableString *tempStr = [fileName mutableCopy];
		[tempStr deleteCharactersInRange:NSMakeRange(0, index)];
		[tempStr insertString:@"x" atIndex:matches[0].rm_eo - index - 3];
		scanString = [tempStr autorelease];
	}
	
	/*See if we found a match*/
	if(index == NSNotFound)
		return NO;
	
	/*Get the show title*/
	NSString *searchStr = [fileName substringToIndex:index];
	/*Check to see if we know this title*/
	NSString *show = [showTranslations objectForKey:[searchStr lowercaseString]];
	if(show == nil)
	{
		/*Ask the user what show this is*/
		NSArray *shows = [self searchResultsForSeries:searchStr];
		/*Pause for the user's input*/
		[dataMenu pause];
		/*Bring up the prompt*/
		SapphireShowChooser *chooser = [[SapphireShowChooser alloc] initWithScene:[dataMenu scene]];
		[chooser setShows:shows];
		[chooser setFileName:fileName];
		[chooser setListTitle:BRLocalizedString(@"Select Show Title", @"Prompt the user for showname with a file")];
		[chooser setSearchStr:searchStr];
		/*And display prompt*/
		[[dataMenu stack] pushController:chooser];
		[chooser release];
		return NO;
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
	if([skipped hasSuffix:@"S"])
		ep = 0;
	/*No season, no info*/
	if(season == 0)
		return NO;
	
	/*Get the episode's info*/
	NSMutableDictionary *info = nil;
	if(ep != 0)
		/*Match on s/e*/
		info = [self getInfo:show forSeason:season episode:ep];
	else
	{
		/*Match on show title*/
		NSString *showTitle = nil;
		[scanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
		if([scanner scanUpToString:@"." intoString:&showTitle])
			info = [self getInfo:show forSeason:season episodeTitle:showTitle];
	}
	/*No info, well, no info*/
	if(!info)
		return NO;
	
	/*Check for screen cap locally and on server*/
	NSString *showInfoUrl = [info objectForKey:LINK_KEY];
	NSString *image = nil;
	NSString *coverArtDir = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"];
	NSString *newPath = [coverArtDir stringByAppendingPathComponent:fileName];
	NSString *imageDestination = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
	BOOL isDir = NO;
	BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imageDestination isDirectory:&isDir] && !isDir;
	if(showInfoUrl && !imageExists)
		/*Get the screen cap*/
		image = [self getScreencapUrl:showInfoUrl];
	if(image)
	{
		/*Download the screen cap*/
		NSURL *imageURL = [NSURL URLWithString:image];
		NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
		[[NSFileManager defaultManager] createDirectoryAtPath:coverArtDir attributes:nil];
		SapphireTVShowDataMenuDownloadDelegate *myDelegate = [[SapphireTVShowDataMenuDownloadDelegate alloc] initWithDest:imageDestination];
		[[NSURLDownload alloc] initWithRequest:request delegate:myDelegate];
		[myDelegate release];
	}
	
	/*Import the info*/
	[info removeObjectForKey:LINK_KEY];
	[metaData importInfo:info fromSource:META_TVRAGE_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
	[metaData setFileClass:FILE_CLASS_TV_SHOW];
	
	/*We imported something*/
	return YES;
}

- (NSString *)completionText
{
	return BRLocalizedString(@"All availble TV Show data has been imported", @"The TV Show import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Fetch TV Show Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will attempt to fetch information about your Movie files from the Internet (IMDB/IMPAwards).  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of the movie import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Fetching Data", @"Button");
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	/*See if it was a show chooser*/
	if(![controller isKindOfClass:[SapphireShowChooser class]])
		return;
	
	/*Get the user's selection*/
	SapphireShowChooser *chooser = (SapphireShowChooser *)controller;
	int selection = [chooser selection];
	if(selection == SHOW_CHOOSE_CANCEL)
		/*They aborted, skip*/
		[dataMenu skipNextItem];
	else if(selection == SHOW_CHOOSE_NOT_SHOW)
	{
		/*They said it is not a show, so put in empty data so they are not asked again*/
		[currentData importInfo:[NSMutableDictionary dictionary] fromSource:META_TVRAGE_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
		if ([currentData fileClass] == FILE_CLASS_TV_SHOW)
			[currentData setFileClass:FILE_CLASS_UNKNOWN];
	}
	else
	{
		/*They selected a show, save the translation and write it*/
		NSDictionary *show = [[chooser shows] objectAtIndex:selection];
		[showTranslations setObject:[show objectForKey:@"link"] forKey:[[chooser searchStr] lowercaseString]];
		[self writeSettings];
	}
	/*We can resume now*/
	[dataMenu resume];
}

@end
