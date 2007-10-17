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
#import "SapphirePosterChooser.h"
/* Translation Keys */
#define TRANSLATIONS_KEY			@"Translations"
#define IMDB_LINK_KEY				@"IMDB Link"
#define IMP_LINK_KEY				@"IMP Link"
#define IMP_POSTERS_KEY				@"IMP Posters"
#define SELECTED_POSTER_KEY			@"Selected Poster"
 /* IMDB XPATHS */
#define	IMDB_SEARCH_XPATH				@"//td[starts-with(a/@href,'/title')]"
#define IMDB_UNIQUE_SEARCH_XPATH		@"//a[@class='tn15more inline']/@href"
#define IMDB_RESULT_LINK_XPATH			@"a/@href"
#define IMDB_POSTER_LINK_XPATH			@"//ul/li/a/@href"
#define	IMDB_RESULT_NAME_XPATH			@"normalize-space(string())"
#define IMDB_RESULT_TITLE_YEAR_XPATH	@"//div[@id='tn15title']/h1/replace(string(), '\n', '')"
/* IMP XPATHS */
#define IMP_POSTER_CANDIDATES_XPATH		@"//img/@src"




/*Delegate class to download cover art*/
@interface SapphireMovieDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
	NSArray *requestList ;
	
}
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest;
-(void)downloadMoviePosters ;
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
	
//	destination = [[NSString stringWithFormat:@"%@/",dest] retain];
	destination = [dest retain];
	requestList = [reqList retain];
	return self;	
}

/*!
* @brief Fire the delegate to start downloading the posters
 *
 */
-(void)downloadMoviePosters
{
	NSEnumerator *reqEnum= [requestList objectEnumerator] ;
	NSString *req=nil ;
	while((req=[reqEnum nextObject]) !=nil)
	{
		NSURL *posterURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMPAwards.com%@",req]];
		NSString *fullDestination=[NSString stringWithFormat:@"%@/%@",destination,[req lastPathComponent]];
		NSURLRequest * request=[NSURLRequest requestWithURL:posterURL];
		NSURLDownload *currentDownload=[[NSURLDownload alloc] initWithRequest:request delegate:self] ;
		[currentDownload setDestination:fullDestination allowOverwrite:YES];
		[currentDownload release] ;
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
//- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
//{
//	NSString *fullDestination=[NSString stringWithFormat:@"@%/@%",destination,[[[self request] lastPathComponent]pathExtension]];
//	[download setDestination:download allowOverwrite:YES];
	
//}

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
	/*Cached movie info*/
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
* @brief Gets IMPAwards.com Poster page link
 *
 * @param candidateIMDBLink The functions IMDB Posters Path
 */
- (NSString *)getPosterPath:(NSString *)candidateIMDBLink
{
	NSError *error = nil ;
	NSURL * url=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.imdb.com%@/posters",candidateIMDBLink]] ;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	NSXMLElement *root = [document rootElement];

	/*Get the results list*/
	NSArray *results = [root objectsForXQuery:IMDB_POSTER_LINK_XPATH error:&error];
	if([results count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			/*Add the result to the list*/			
			NSString *resultURL =[[result stringValue] lowercaseString];
			if(resultURL == nil)
				continue;
			else if([resultURL hasPrefix:@"http://www.impawards.com"])/* See if the link is to IMP */
			{
				NSString * foundPosterLink =[resultURL stringByReplacingAllOccurancesOf:@"http://www.impawards.com" withString:@""];
				return foundPosterLink;
			}
		}		
	}
	return nil;
}

/*!
* @brief Compile IMPAwards.com Poster link list
 *
 * @param posterPageLink The Movie's IMP Poster link extention
 * @return An array of canidate poster images
 */
- (NSArray *)getPosterLinks:(NSString *)posterPageLink
{
	NSError *error = nil ;
	NSURL * url=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMPAwards.com%@",posterPageLink]] ;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	NSXMLElement *root = [document rootElement];
	NSArray * candidatePosterLinks=[NSArray arrayWithObjects:nil] ;
	NSString * yearPathComponent=[posterPageLink stringByDeletingLastPathComponent];
	
	/*Get the results list*/
	NSArray *results = [root objectsForXQuery:IMP_POSTER_CANDIDATES_XPATH error:&error];
	if([results count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			/*Add the result to the list*/			
			NSString *resultURL =[[result stringValue] lowercaseString];
			if(resultURL == nil)
				continue;
			if([resultURL hasPrefix:@"posters/"]) /* get the displayed poster link */
			{
				NSString * subPath=[resultURL substringFromIndex:7];
				subPath=[NSString stringWithFormat:[NSString stringWithFormat:@"%@/posters%@",yearPathComponent,subPath]];
				candidatePosterLinks=[candidatePosterLinks arrayByAddingObject:subPath];
			}
			else if([resultURL hasPrefix:@"thumbs/"]) /* get the displayed poster link */
			{
				NSString * subPath=[resultURL substringFromIndex:11];
				subPath=[NSString stringWithFormat:[NSString stringWithFormat:@"%@/posters/%@",yearPathComponent,subPath]];
				candidatePosterLinks=[candidatePosterLinks arrayByAddingObject:subPath];
			}
		}
	}
return candidatePosterLinks;
}

/*!
* @brief Get the posters from IMPAwards.com
 *
 * @param posterLinks The Movie's IMP Poster links
 * @return selected poster link
 */
- (NSString *)getPostersForMovie:(NSString *)movieTitle withPath:(NSString*)moviePath
{
//	NSError *error = nil ;
	NSString *fileName=[[moviePath lastPathComponent]lowercaseString] ;
	NSString *selectedPoster=nil ;
	selectedPoster=[[movieTranslations objectForKey:[fileName lowercaseString]]objectForKey:SELECTED_POSTER_KEY];
	/* Should we check to see if a poster has already been selected? */
	if(selectedPoster)
		return selectedPoster ;	
	NSArray *posters=[[movieTranslations objectForKey:[fileName lowercaseString]]objectForKey:IMP_POSTERS_KEY];
	if([posters count])
	{
		[dataMenu pause];
		/* download all posters to the scratch folder */
		NSString * posterBuffer=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		[[NSFileManager defaultManager] createDirectoryAtPath:posterBuffer attributes:nil];
//		NSString *posterDest=[NSString stringWithFormat:@"%@/%@",posterBuffer,[
		SapphireMovieDataMenuDownloadDelegate *myDelegate=[[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:posters withDestination:posterBuffer];
		[myDelegate downloadMoviePosters] ;
		/* Now have the user pick a poster */
		SapphirePosterChooser * chooser=[[SapphirePosterChooser alloc] initWithScene:[dataMenu scene]];
		[chooser setPosters:posters] ;
		[chooser setFileName:fileName];
		[chooser setMovieTitle:movieTitle];
		[chooser setListTitle:BRLocalizedString(@"Select Movie Poster", @"Prompt the user for poster selection")];
		[[dataMenu stack] pushController:chooser];
		[chooser release];
	}
	return nil;
}


/*!
* @brief Fetch information for a movie
 *
 * @param movieTitleLink The IMDB link extention (part of the show's URL)
 * @param moviePath The movie file's location
 * @return A cached dictionary of the movie info
 */
- (NSMutableDictionary *)getMetaForMovie:(NSString *)movieTitleLink withPath:(NSString*)moviePath
{
	NSError *error = nil;
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	
	/* Gather IMDB Data */
	/*Get the movie html*/
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMDB.com%@",movieTitleLink]];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	/* Get the movie title */
	NSString *movieTitle= [[document objectsForXQuery:IMDB_RESULT_TITLE_YEAR_XPATH error:&error] objectAtIndex:0];
	
	/*Prompt User to Select an IMP Poster */
	/* We want to save the selected poster to the Cover Art folder & delete the rest */
//	NSString *selectedPoster=nil ;

//	selectedPoster=[self getPostersForMovie:movieTitle withPath:moviePath];
	
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
	NSError * error = nil;
	BOOL uniqueResult=NO ;
	NSArray * results = nil;
	NSMutableArray *ret=nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
	NSXMLElement *root = [document rootElement];	
	NSString *resultTitle=[[[root objectsForXQuery:@"//title" error:&error]objectAtIndex:0] stringValue];
	
	if([resultTitle isEqualToString:@"IMDb Search"])/*Make sure we didn't get back a unique result */
	{
		results = [root objectsForXQuery:IMDB_SEARCH_XPATH error:&error];
		ret = [NSMutableArray arrayWithCapacity:[results count]];
		//Need to clean out (VG) entries <Video Game>
		//Need to clean out (TV) entries <Television> ?
	}
	else /* IMDB directly linked to a unique movie title */
	{
		uniqueResult=YES ;
		ret = [NSMutableArray arrayWithCapacity:1];
		results = [root objectsForXQuery:IMDB_UNIQUE_SEARCH_XPATH error:&error];		
	}	
		
	if([results count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [results objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			if(uniqueResult)/*Check for a unique title link*/
			{
				NSURL *resultURL = [NSURL URLWithString:[[[result objectsForXQuery:IMDB_UNIQUE_SEARCH_XPATH error:&error] objectAtIndex:0] stringValue]] ;
				if(resultURL == nil)
					continue;
				NSString *URLSubPath =[resultURL path] ;
				if([URLSubPath hasPrefix:@"/rg/title-tease/"])
				{
					URLSubPath=[[URLSubPath stringByReplacingAllOccurancesOf:@"/rg/title-tease/" withString:@""]stringByDeletingLastPathComponent];
					NSScanner * snipPrefix=[NSScanner scannerWithString:URLSubPath];
					NSString *snip=nil ;
					[snipPrefix scanUpToString:@"/" intoString:&snip] ;
					URLSubPath=[URLSubPath stringByReplacingAllOccurancesOf:snip withString:@""];
					[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						resultTitle, @"name",
						URLSubPath, IMDB_LINK_KEY,
						nil]];
					return ret ;
				}
			}
			else
			{
				/*Add the result to the list*/
				NSURL *resultURL = [NSURL URLWithString:[[[result objectsForXQuery:IMDB_RESULT_LINK_XPATH error:&error] objectAtIndex:0] stringValue]] ;
				if(resultURL == nil)
					continue;
				[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[[result objectsForXQuery:IMDB_RESULT_NAME_XPATH error:&error] objectAtIndex:0], @"name",
					[resultURL path], IMDB_LINK_KEY,
					nil]];
			}
		}
		if(!uniqueResult)return ret;
	}
	return nil ;
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
	NSString *movieDataLink = nil ;
	/*Check to see if we know this movie*/
	NSMutableDictionary *dict=[movieTranslations objectForKey:[fileName lowercaseString]];
	if(dict == nil)
	{
		/*Ask the user what movie this is*/
		NSArray *movies = [self searchResultsForMovie:fileName];
		/*Pause for the user's input*/
		[dataMenu pause];
		/*Bring up the prompt*/
		SapphireMovieChooser *chooser = [[SapphireMovieChooser alloc] initWithScene:[dataMenu scene]];
		[chooser setMovies:movies];
		[chooser setFileName:fileName];		
		[chooser setListTitle:BRLocalizedString(@"Select Movie Title", @"Prompt the user for title of movie")];
		/*And display prompt*/
		[[dataMenu stack] pushController:chooser];
		[chooser release];
		return NO ;
		//Data will be ready for access on the next call
	}
	

	/*Import the info*/
	/*IMDB Data */
	NSMutableDictionary *infoIMDB = nil;
	movieDataLink=[dict objectForKey:IMDB_LINK_KEY];
	infoIMDB = [self getMetaForMovie:movieDataLink withPath:path];
	if(!infoIMDB)
		return NO;
	
	NSString * selectedPoster=nil ;
	selectedPoster=[dict objectForKey:SELECTED_POSTER_KEY] ;
	if(!selectedPoster && [dict objectForKey:IMP_POSTERS_KEY])
	{
		/*Prompt User to Select an IMP Poster */
		/* We want to save the selected poster to the Cover Art folder & delete the rest */
		//	NSString *selectedPoster=nil ;
		
		[self getPostersForMovie:[infoIMDB objectForKey:META_MOVIE_TITLE_KEY] withPath:path];
			
		return NO ;
	}
	else if(selectedPoster)
	{
		/* Lets move the selected poster to the corresponding Cover Art Directory */
		NSFileManager *fileAgent=[NSFileManager alloc];
		NSString * poster=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		poster=[poster stringByAppendingPathComponent:[selectedPoster lastPathComponent]];
		NSString * coverart=[[path stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Cover Art"];
		coverart=[coverart stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]];
		coverart=[coverart stringByAppendingPathExtension:[poster pathExtension]];
		/* Might want to make sure files exist / DNE */
		[fileAgent movePath:poster toPath:coverart handler:self] ;
		/* Lets clean up the Poster_Buffer */
		NSArray *oldPosters = [dict objectForKey:IMP_POSTERS_KEY];
		if([oldPosters count])
		{
			/*Get each result*/
			NSEnumerator *resultEnum = [oldPosters objectEnumerator];
			NSString *result = nil;
			while((result = [resultEnum nextObject]) != nil)
			{
				NSString *removeFile=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"],[result lastPathComponent]];
		//		if(!results)
		//			results=[NSArray arrayWithObject:[self getPosterLayer:posterPath]];
		//		else 
		//			results=[results arrayByAddingObject:[self getPosterLayer:posterPath]];
				[fileAgent removeFileAtPath:removeFile handler:self] ;
			}
		}
		[fileAgent release];
	}
	
	[infoIMDB removeObjectForKey:IMDB_LINK_KEY];
	[metaData importInfo:infoIMDB fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
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
	if([controller isKindOfClass:[SapphireMovieChooser class]])
	{
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
			NSMutableDictionary * transDict = [movieTranslations objectForKey:[[chooser fileName] lowercaseString]];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:[[chooser fileName] lowercaseString]];
				[transDict release];
			}
			/* Add IMDB Key */
			[transDict setObject:[movie objectForKey:IMDB_LINK_KEY] forKey:IMDB_LINK_KEY];
			NSString *posterPath=nil ;
			/* Get the IMP Key with the IMDB Posters page */
			posterPath=[self getPosterPath:[transDict objectForKey:IMDB_LINK_KEY]] ;
			if(posterPath!=nil)
			{
				[transDict setObject:posterPath forKey:IMP_LINK_KEY];
				/*We got a posterPath, get the posterLinks */
				NSArray *posterLinks=nil ;
				posterLinks=[self getPosterLinks:posterPath];
				if(posterLinks!=nil)
				{
					/* Add the poster links */
					[transDict setObject:posterLinks forKey:IMP_POSTERS_KEY];
				}
				
			}
			[self writeSettings];
		}
	}
	else if([controller isKindOfClass:[SapphirePosterChooser class]])
	{
		SapphirePosterChooser *chooser = (SapphirePosterChooser *)controller;
		int selectedPoster = [chooser selectedPoster];
		if(selectedPoster == POSTER_CHOOSE_CANCEL)
			/*They aborted, skip*/
			[dataMenu skipNextItem]; //Should this be done?
		else
		{
			NSString *selected = [[chooser posters] objectAtIndex:selectedPoster];
			NSMutableDictionary * transDict = [movieTranslations objectForKey:[chooser fileName]];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:[chooser fileName]];
				[transDict release];
			}
			[transDict setObject:selected forKey:SELECTED_POSTER_KEY];
		}
		[self writeSettings];
	}
	else
		return;
	/*We can resume now*/
	[dataMenu resume];
}

@end