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
#define	IMDB_SEARCH_XPATH				@"//td[starts-with(a/@href,'/title')]"
#define IMDB_RESULT_LINK_XPATH			@"a/@href"
#define	IMDB_RESULT_NAME_XPATH			@"normalize-space(string())"
#define IMDB_RESULT_TITLE_YEAR_XPATH	@"//div[@id='tn15title']/h1/replace(string(), '\n', '')"
 
 
#define TRANSLATIONS_KEY		@"Translations"
#define LINK_KEY				@"Link"

/*Delegate class to download cover art*/
@interface SapphireMovieDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
	NSArray *requestList ;
	
}
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest;
-(void)getCoverArt ;
@end

@implementation SapphireMovieDataMenuDownloadDelegate
/*!
* @brief Initialize a cover art downloader
 *
 * @param reqList The list of url requests to try
 * @param dest The path to save the file
 */
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest;
{
	self = [super init];
	if(!self)
		return nil;
	
	destination = [dest retain];
	requestList = [reqList retain];
	
	return self;
	
}

/*!
* @brief Fire the delegate to start downloading
 *
 */
-(void)getCoverArt
{
	NSEnumerator *reqEnum= [requestList objectEnumerator] ;
	NSURLRequest *req=nil ;
	while((req=[reqEnum nextObject]) !=nil)
	{
		NSURLDownload *currentDownload=[[NSURLDownload alloc] initWithRequest:req delegate:self] ;
		[currentDownload release] ;
	//	if(currentDownload)break;/*The download is going, no need to try another URL */
	}
	
}


- (void)dealloc
{
	[destination release];
	[requestList release];
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

	[download setDestination:destination allowOverwrite:NO];
	
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[download release];
//	NSString *failed=[[error userInfo] objectForKey:NSErrorFailingURLStringKey] ;
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
- (NSMutableDictionary *)getMetaForMovie:(NSString *)movieName withPath:(NSString*)moviePath
{
	NSError *error = nil;
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	/*Get the movie html*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMDB.com%@",movieName]];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	
	/* Get the movie title */
	NSString *movieTitle= [[document objectsForXQuery:IMDB_RESULT_TITLE_YEAR_XPATH error:&error] objectAtIndex:0];
	int titleYear= 0 ;
	NSString *shortenedMovieTitle=nil ;
	NSString *coverArtLinkA=nil ;
	NSString *coverArtLinkB=nil ;
	NSString *coverArtSavePath=nil ;
	NSCharacterSet *decimalSet = [NSCharacterSet decimalDigitCharacterSet];
	NSCharacterSet *skipSet = [NSCharacterSet characterSetWithCharactersInString:@"("];
	NSScanner *titleScan= [NSScanner scannerWithString:movieTitle] ;
	
	/* Cover Art Processing */
	[titleScan scanUpToCharactersFromSet:skipSet intoString:&shortenedMovieTitle];
	[titleScan scanUpToCharactersFromSet:decimalSet intoString:nil];
	[titleScan scanInt:&titleYear];
	
	/* Remove punctuation */
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@":" withString:@""];
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"'" withString:@""];
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"," withString:@""];
	shortenedMovieTitle=[[shortenedMovieTitle stringByReplacingAllOccurancesOf:@" " withString:@"_"] lowercaseString];
	
	/*Convert roman to verbage*/
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_i_"	withString:@"_one_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_ii_"	withString:@"_two_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_iii_"	withString:@"_three_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_iv_"	withString:@"_four_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_v_"	withString:@"_five_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_1_"	withString:@"_one_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_2_"	withString:@"_two_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_3_"	withString:@"_three_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_4_"	withString:@"_four_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"_5_"	withString:@"_five_"] ;
	
	/* Symbol Replacements */
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"&"	withString:@"_and_"] ;
	shortenedMovieTitle=[shortenedMovieTitle stringByReplacingAllOccurancesOf:@"®"	withString:@"ae"] ;
		
	/* Remove leading 'the' and 'a' */
	if([shortenedMovieTitle hasPrefix:@"the_"])shortenedMovieTitle=[shortenedMovieTitle substringFromIndex:4];
	else if([shortenedMovieTitle hasPrefix:@"a_"])shortenedMovieTitle=[shortenedMovieTitle substringFromIndex:2];
	coverArtLinkA=[NSString stringWithFormat:@"http://www.impawards.com/%d/posters/%@ver1.jpg",titleYear,shortenedMovieTitle] ;
	coverArtLinkB=[coverArtLinkA stringByReplacingAllOccurancesOf:@"_ver1" withString:@""];
	coverArtSavePath=[[[moviePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:[[[moviePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"]];
	error = nil;
	BOOL isDir = NO;
	BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:coverArtSavePath isDirectory:&isDir] && !isDir;
	if(!imageExists)/*Get the screen cap*/
	{
		NSArray *requestURLList=[[NSArray alloc]  initWithObjects:
			[NSURLRequest requestWithURL:[NSURL URLWithString:coverArtLinkA]
							 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0],
			[NSURLRequest requestWithURL:[NSURL URLWithString:coverArtLinkB]
				cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0],
			nil];
		

//		SapphireMovieDataMenuDownloadDelegate *myDelegate= [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:requestURLList withDestination:coverArtSavePath];		
//		[[NSFileManager defaultManager] createDirectoryAtPath:[coverArtSavePath stringByDeletingLastPathComponent] attributes:nil];
//		[myDelegate getCoverArt];
//		[[NSURLDownload alloc] initWithRequest:[requestURLList objectAtIndex:0] delegate:myDelegate];
//		[myDelegate release];
	}
		
	/* Dump XML document to disk (Dev Only) */
//	NSString *documentPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/XML"];
//	[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"/%@/%@_title_result.xml",documentPath,movieTitle] atomically:YES] ;
	
	
	
	/* populate metadata to return */
	[ret setObject:movieTitle forKey:META_MOVIE_TITLE_KEY];
	return ret;
}



/*!
* @brief Searches for a movie based on the filename
 *
 * @param searchStr Part of the filename to use in the show search
 * @return An array of possible results
 */
- (NSArray *)searchResultsForMovie:(NSString *)searchStr
{
	/* prep the search string */
	searchStr = [searchStr stringByDeletingPathExtension];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"_" withString:@" "];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"." withString:@" "];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"-" withString:@" "];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.imdb.com/find?s=all&q=%@", [searchStr URLEncode]]];
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	/* Dump XML document to disk (Dev Only) */
	//NSString *documentPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/XML"];
	//[[document XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:[NSString stringWithFormat:@"%@/%@_search_result.xml",documentPath,searchStr] atomically:YES] ;
	
	NSXMLElement *root = [document rootElement];
	
	NSString *resultTitle=[[[root objectsForXQuery:@"//title" error:&error]objectAtIndex:0] stringValue];
	
	if([resultTitle isEqualToString:@"IMDb Search"])/*Make sure we didn't get back a unique result */
	{
		/*Get the results list*/
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
	}
	else /* IMDB directly linked to a unique movie title */
	{
		NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
		[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		resultTitle, @"name",
		[[url relativeString] stringByReplacingAllOccurancesOf:@"http://www.imdb.com" withString:@""], @"link",
		nil]];
		return ret ;
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
* @brief verify file extention of a file
 *
 * @param filePAth The file's path 
 * @return YES if candidate, NO otherwise
 */
- (BOOL)isMovieCandidate:(NSString*)fileExt
{
	if([[SapphireMetaData videoExtensions] member:fileExt])
		return YES;
	else return NO ;
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
	if(![self isMovieCandidate:[path pathExtension]])
		return NO;
	/*Get fineName*/
	NSString *fileName = [path lastPathComponent];
	
	if([metaData fileClass]==FILE_CLASS_TV_SHOW) /* File is a TV Show - skip it */
		return NO ;
	
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
	
	/*Import the info*/
	NSMutableDictionary *info = nil;
	info = [self getMetaForMovie:movie withPath:path];
	if(!info)
		return NO;	
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
	/*See if it was a movie chooser*/
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
		if ([currentData fileClass] != FILE_CLASS_TV_SHOW)
			[currentData setFileClass:FILE_CLASS_UNKNOWN];
	}
	else if(selection==MOVIE_CHOOSE_OTHER)
	{
		[currentData importInfo:[NSMutableDictionary dictionary] fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
		[currentData setFileClass:FILE_CLASS_OTHER] ;
	}
	else if(selection==MOVIE_CHOOSE_TV_SHOW)
	{
		[currentData importInfo:[NSMutableDictionary dictionary] fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
		[currentData setFileClass:FILE_CLASS_TV_SHOW] ;	
	}
	else
	{
		/*They selected a movie title, save the translation and write it*/
		NSDictionary *movie = [[chooser movies] objectAtIndex:selection];
		[movieTranslations setObject:[movie objectForKey:@"link"] forKey:[[chooser searchStr] lowercaseString]];
		[self writeSettings];
	}
	/*We can resume now*/
	[dataMenu resume];
}

@end