//
//  SapphireMovieImporter.m
//  Sapphire
//
//  Created by Patrick Merrill on 9/10/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMovieImporter.h"
#import "SapphireMetaData.h"
#import "NSString-Extensions.h"
#import "SapphireMovieChooser.h"

 /* IMDB XPATHS */
#define	IMDB_SEARCH_XPATH @"//td[starts-with(a/@href,'/title')]"
#define IMDB_RESULT_LINK_XPATH @"a/@href"
#define	IMDB_RESULT_NAME_XPATH @"normalize-space(string())"
 
 
#define TRANSLATIONS_KEY		@"Translations"
#define LINK_KEY				@"Link"

/*Delegate class to download cover art*/
@interface SapphireMovieDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
}
- (id)initWithDest:(NSString *)dest;
@end

@implementation SapphireMovieDataMenuDownloadDelegate
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

@interface SapphireMovieImporter (private)
- (void)writeSettings;
@end

@implementation SapphireMovieImporter

- (id) initWithSavedSetting:(NSString *)path
{
	self = [super init];
	if(!self)
		return nil;
	
	/*Get the settings*/
	settingsPath = [path retain];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	/*Get or create the show translation dict*/
	movieTranslations = [[settings objectForKey:TRANSLATIONS_KEY] mutableCopy];
	if(movieTranslations == nil)
		movieTranslations = [NSMutableDictionary new];
	/*Cached show info*/
	movieInfo = [NSMutableDictionary new];
	
	return self;
}

- (void)dealloc
{
	[dataMenu release];
	[movieTranslations release];
	[movieInfo release];
	[settingsPath release];
	[super dealloc];
}

/*!
* @brief Sets the importer's data menu
 *
 * @param theDataMenu The importer's menu
 */
- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[dataMenu release];
	dataMenu = [theDataMenu retain];
}

/*!
* @brief Fetch information for a movie
 *
 * @param movieName The IMDB name (part of the show's URL)
 * @return A cached dictionary of the movie info
 */
- (NSMutableDictionary *)getMetaForMovie:(NSString *)movieName
{
	NSError *error = nil;
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	/*Get the movie html*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMDB.com%@",movieName]];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	/* Dump XML document to disk (Dev Only) */
	NSString *documentPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/XML"];
	[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"/%@%@_page.xml",documentPath,movieName] atomically:YES] ;
	NSString *movieTitle= [[document objectsForXQuery:@"//div[@id='tn15title']/h1/replace(string(), '\n', '')" error:&error] objectAtIndex:0];
	
	[ret setObject:movieTitle forKey:META_MOVIE_TITLE];
	return ret;
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
//	NSURL *url = [NSURL URLWithString:epUrl];
//	NSError *error = nil;
//	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	/*Search for a screencap*/
//	NSXMLElement *html = [document rootElement];
//	NSArray *caps = [html objectsForXQuery:TVRAGE_SCREEN_CAP_XPATH error:&error];
//	if([caps count])
		/*Found one; return it*/
//		return [[(NSXMLElement *)[caps objectAtIndex:0] attributeForName:@"src"] stringValue];
	/*None found*/
	return nil;
}

/*!
* @brief Searches for a movie based on the filename
 *
 * @param searchStr Part of the filename to use in the show search
 * @return An array of possible results
 */
- (NSArray *)searchResultsForMovie:(NSString *)searchStr
{
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"_" withString:@" "];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"." withString:@" "];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"-" withString:@" "];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.imdb.com/Title?%@", [searchStr URLEncode]]];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	/* Dump XML document to disk (Dev Only) */
	NSString *documentPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/XML"];
	[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"%@/%@.xml",documentPath,searchStr] atomically:YES] ;
	/*Get the results list*/
	NSXMLElement *root = [document rootElement];
	NSArray *results = [root objectsForXQuery:IMDB_SEARCH_XPATH error:&error];
	//Need to clean out (VG) entries <Video Game>
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[results count]];
	if([results count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			/*Add the result to the list*/
			//			NSURL *resultURL = [NSURL URLWithString:[[result attributeForName:@"href"] stringValue]];
			NSURL *resultURL = [NSURL URLWithString:[[[result objectsForXQuery:IMDB_RESULT_LINK_XPATH error:&error] objectAtIndex:0] stringValue]] ;
			
			if(resultURL == nil)
				continue;
			{
				[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[[result objectsForXQuery:IMDB_RESULT_NAME_XPATH error:&error] objectAtIndex:0], @"name",
					[resultURL path], @"link",
					nil]];
			}
		}
		return ret;
	}
	/*No results found*/
	return nil;
}

/*!
* @brief Write our setings out
 */
- (void)writeSettings
{
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
		movieTranslations, TRANSLATIONS_KEY,
		nil];
	[settings writeToFile:settingsPath atomically:YES];
}

/*!
* @brief Import a single File
 *
 * @param metaData The file to import
 * @return YES if imported, NO otherwise
 */
- (BOOL) importMetaData:(SapphireFileMetaData *)metaData
{
	currentData = metaData;
	/*Check to see if it is already imported*/
	if([metaData importedTimeFromSource:META_IMDB_IMPORT_KEY])
		return NO;
	/*Get path*/
	NSString *path = [metaData path];
	/*Get fineName*/
	NSString *fileName = [path lastPathComponent];
	
	/*Get the movie title*/
	NSString *searchStr = fileName;
	/*Check to see if we know this movie*/
	NSString *movie = [movieTranslations objectForKey:[searchStr lowercaseString]];
	if(movie == nil)
	{
		/*Ask the user what movie this is*/
		NSArray *movies = [self searchResultsForMovie:searchStr];
		/*Pause for the user's input*/
		[dataMenu pause];
		/*Bring up the prompt*/
		SapphireMovieChooser *chooser = [[SapphireMovieChooser alloc] initWithScene:[dataMenu scene]];
		[chooser setMovies:movies];
		[chooser setFileName:fileName];		
		[chooser setListTitle:BRLocalizedString(@"Select Movie Title", @"Prompt the user for title of movie")];
		[chooser setSearchStr:searchStr];
		/*And display prompt*/
		[[dataMenu stack] pushController:chooser];
		[chooser release];
		return NO ;
		//Data will be ready for access on the next exe
	}
	
	/*Get The Release Date*/


	
	

	NSMutableDictionary *info = nil;
	info = [self getMetaForMovie:movie];
	if(!info)
		return NO;
	
	
	/*Import the info*/
	[info removeObjectForKey:LINK_KEY];
	[metaData importInfo:info fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
	[metaData setFileClass:FILE_CLASS_MOVIE];
	
	/*We imported something*/
	return YES;
}


/*!
* @brief The completion text to display
 *
 * @return The completion text to display
 */
- (NSString *)completionText
{
	return BRLocalizedString(@"All availble Movie data has been imported", @"The Movie import is complete");
}

/*!
* @brief The initial text to display
 *
 * @return The initial text to display
 */
- (NSString *)initialText
{
	return BRLocalizedString(@"Movie Meta Data", @"Title");
}

/*!
* @brief The informative text to display
 *
 * @return The informative text to display
 */
- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will attempt to fetch information about your Movie files from the Internet (IMDB/IMPAwards).  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of the movie import");
}

/*!
* @brief The button title
 *
 * @return The button title
 */
- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Fetching Data", @"Button");
}

/*!
* @brief The data menu was exhumed
 *
 * @param controller The Controller which was on top
 */
- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	/*See if it was a show chooser*/
	if(![controller isKindOfClass:[SapphireMovieChooser class]])
		return;
	
	/*Get the user's selection*/
	SapphireMovieChooser *chooser = (SapphireMovieChooser *)controller;
	int selection = [chooser selection];
	if(selection == MOVIE_CHOOSE_CANCEL)
		/*They aborted, skip*/
		[dataMenu skipNextItem];
	else if(selection == MOVIE_CHOOSE_NOT_MOVIE)
	{
		/*They said it is not a movie, so put in empty data so they are not asked again*/
		[currentData importInfo:[NSMutableDictionary dictionary] fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
		if ([currentData fileClass] == FILE_CLASS_MOVIE && [currentData fileClass] != FILE_CLASS_TV_SHOW)//check to make sure it's not already a tv show?
			[currentData setFileClass:FILE_CLASS_UNKNOWN];
	}
	else
	{
		/*They selected a show, save the translation and write it*/
		NSDictionary *movie = [[chooser movies] objectAtIndex:selection];
		[movieTranslations setObject:[movie objectForKey:@"link"] forKey:[[chooser searchStr] lowercaseString]];
		[self writeSettings];
	}
	/*We can resume now*/
	[dataMenu resume];
}

@end