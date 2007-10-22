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
#define IMDB_RESULT_RELEASE_DATE_XPATH	@"//div[@class='info']"
#define IMDB_RESTULT_CAST_NAMES_XPATH	@"//div[@class='info']/table/tr/td/a"
/* IMP XPATHS */
#define IMP_POSTER_CANDIDATES_XPATH		@"//img/@src"




/*Delegate class to download cover art*/
@interface SapphireMovieDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
	NSArray *requestList ;
	NSMutableArray *delegates ;
	long downloadsLeft ;
}
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest;
- (void) downloadDidFinish: (NSURLDownload *) download;
- (long) downloadsCompleted;
- (long) downloadsQueued;
- (void)downloadMoviePosters ;
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
	delegates = [NSMutableArray new];
	destination = [dest retain];
	requestList = [reqList retain];
	downloadsLeft=[requestList count] ;
	return self;	
}

/*!
* @brief Fire the delegate to start downloading the posters
 *
 */
-(void)downloadMoviePosters
{
	NSEnumerator *reqEnum = [requestList objectEnumerator] ;
	NSString *req = nil ;
	while((req = [reqEnum nextObject]) !=nil)
	{
		NSURL *posterURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMPAwards.com%@",req]];
		NSString *fullDestination = [NSString stringWithFormat:@"%@/%@", destination, [req lastPathComponent]];
		NSURLRequest *request = [NSURLRequest requestWithURL:posterURL];
		NSURLDownload *currentDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self] ;
		[currentDownload setDestination:fullDestination allowOverwrite:YES];
		[delegates addObject:currentDownload];
		[currentDownload release];
	}
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
	downloadsLeft--;
}

- (long) downloadsCompleted
{
	if(downloadsLeft == 0)
	{
		[delegates release];
		delegates = nil;
		return 0;
	}
	else
	{
		return [requestList count] - downloadsLeft;
	}
}

- (long) downloadsQueued
{
		return [requestList count];
}

- (void)dealloc
{
	[destination release];
	[requestList release];
	[delegates release];
	[super dealloc];
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
	if([candidatePosterLinks count])
	{
		/* download all posters to the scratch folder */
		NSString *posterBuffer = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		[[NSFileManager defaultManager] createDirectoryAtPath:posterBuffer attributes:nil];
		SapphireMovieDataMenuDownloadDelegate *myDelegate = [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:candidatePosterLinks withDestination:posterBuffer];
		[myDelegate downloadMoviePosters] ;
		[myDelegate autorelease];
	}
	return candidatePosterLinks;
}

/*!
* @brief Get the posters from IMPAwards.com
 *
 * @param posterLinks The Movie's IMP Poster links
 * @return selected poster link
 */
- (void)getPostersForMovie:(NSString *)movieTitle withPath:(NSString*)moviePath
{
	NSString *fileName = [[moviePath lastPathComponent] lowercaseString] ;
	NSArray *posters = [[movieTranslations objectForKey:fileName] objectForKey:IMP_POSTERS_KEY];
	if([posters count])
	{
		/* download all posters to the scratch folder */
		NSString *posterBuffer = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		[[NSFileManager defaultManager] createDirectoryAtPath:posterBuffer attributes:nil];
		SapphireMovieDataMenuDownloadDelegate *myDelegate = [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:posters withDestination:posterBuffer];
		[myDelegate downloadMoviePosters] ;
		[myDelegate autorelease];
	}
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
	NSScanner *metaTrimmer=[NSScanner scannerWithString:movieTitle];
	[metaTrimmer scanUpToString:@"(" intoString:&movieTitle];
	movieTitle=[movieTitle substringToIndex:[movieTitle length]-1];
	
	/* Get the release date */
	NSArray *rawData=[document objectsForXQuery:IMDB_RESULT_RELEASE_DATE_XPATH error:&error];
	NSDate * releaseDate=nil ;
	NSString * plot=nil;
	NSArray * directors=nil;
	NSArray * writers=nil;
	NSArray * genres=nil;
	if([rawData count])
	{
		NSEnumerator *resultEnum = [rawData objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			NSString *dataCandidate=[result stringValue];

			if([dataCandidate length])
			{
				NSString * dataType=nil;
				NSScanner * trimmer=[NSScanner scannerWithString:dataCandidate];
				[trimmer scanUpToString:@"\n" intoString:&dataType];
				if([dataType hasPrefix:@"Release"])
				{
					[trimmer scanUpToString:@"(" intoString:&dataCandidate];
					releaseDate=[NSDate dateWithNaturalLanguageString:dataCandidate];

				}
				else if([dataType hasPrefix:@"Writers"])
				{
					writers=[NSArray array];
					while(![trimmer isAtEnd])
					{
						NSString * aWriter=nil;
						[trimmer scanUpToString:@"\n" intoString:&aWriter];
						writers=[writers arrayByAddingObject:aWriter];
					}
					
				}
				else if([dataType hasPrefix:@"Director"])
				{
					directors=[NSArray array];
					while(![trimmer isAtEnd])
					{
						NSString * aDirector=nil;
						[trimmer scanUpToString:@"\n" intoString:&aDirector];
						directors=[directors arrayByAddingObject:aDirector];
					}
					
				}
				else if([dataType hasPrefix:@"Genre"])
				{

					genres=[NSArray array];
					while(![trimmer isAtEnd])
					{
						NSString *aGenre=nil;
						[trimmer scanUpToString:@"/" intoString:&aGenre];
						if(aGenre)
						{
							if([aGenre isEqualToString:@"/"])
								continue ;
							else if([aGenre hasSuffix:@"more\n"])
								aGenre=[aGenre substringToIndex:[aGenre length]-6];
							else if([aGenre hasSuffix:@" "])
								aGenre=[aGenre substringToIndex:[aGenre length]-1];
							genres=[genres arrayByAddingObject:aGenre];
						}
						else
						{
							[trimmer scanUpToString:@" " intoString:&aGenre];
						}
					}
				}
				else if([dataType hasPrefix:@"Plot Outline"])
				{
					while(![trimmer isAtEnd])
					{
						NSString * aPlot=nil;
						[trimmer scanUpToString:@"more\n" intoString:&aPlot];
						if(aPlot)
							plot=aPlot;
						else
							break;
						
					}
				}
				else 
					continue ;
			}
			else
				continue ;
		}

		
	}
	
	/* Get the cast list */
	NSArray *rawCast=[document objectsForXQuery:IMDB_RESTULT_CAST_NAMES_XPATH error:&error];
	NSArray *completeCast=nil ;
	if([rawCast count])
	{
		NSArray *results=nil;
		NSEnumerator *resultEnum = [rawCast objectEnumerator];
		NSXMLElement *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			NSString *castName=nil;
			castName=[result stringValue];
			if([castName length])
			{
				NSString * castURL=[[[result attributeForName:@"href"]stringValue]lowercaseString];
				if([castURL hasPrefix:@"/name/"])
				{
					if(!results)
						results=[NSArray arrayWithObject:castName];
					else
						results=[results arrayByAddingObject:castName];
				}
				else continue ;
			}
			else
			continue ;
		}
		completeCast=results ;
	}
	
	
	/* populate metadata to return */
	if(directors)
		[ret setObject:directors forKey:META_MOVIE_DIRECTOR_KEY];
	if(plot)
		[ret setObject:plot forKey:META_MOVIE_PLOT_KEY];
	if(releaseDate)
		[ret setObject:releaseDate forKey:META_MOVIE_RELEASE_DATE_KEY];
	if(genres)
		[ret setObject:genres forKey:META_MOVIE_GENRES_KEY];
	if(completeCast)
		[ret setObject:completeCast forKey:META_MOVIE_CAST_KEY];
	if(movieTitle)
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
				NSString * resultTitleValue=[result stringValue];
				if(resultURL == nil)
					continue;
				/*Skip Video Game titles (VG) */
				else if([resultTitleValue hasSuffix:@" (VG) "])
					continue ;
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

	NSString * selectedPoster=nil ;
	selectedPoster=[dict objectForKey:SELECTED_POSTER_KEY] ;
	if(!selectedPoster && [dict objectForKey:IMP_POSTERS_KEY])
	{
		/* Posters were downloaded, let the user choose one */
		[dataMenu pause];
		SapphirePosterChooser * chooser=[[SapphirePosterChooser alloc] initWithScene:[dataMenu scene]];
		[[dataMenu scene] renderScene];
		NSArray *posters=[dict objectForKey:IMP_POSTERS_KEY];
		[chooser setPosters:posters] ;
		[chooser setFileName:fileName];
		[chooser setMovieTitle:@"Movie Title"];
		[chooser setListTitle:BRLocalizedString(@"Select Movie Poster", @"Prompt the user for poster selection")];
		[[dataMenu stack] pushController:chooser];
		[chooser release];
		return NO;
	}
	if(selectedPoster && [dict objectForKey:IMP_POSTERS_KEY])
	{
		/* Lets move the selected poster to the corresponding Cover Art Directory */
		NSFileManager *fileAgent=[NSFileManager alloc];
		NSString * poster=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		poster=[poster stringByAppendingPathComponent:[selectedPoster lastPathComponent]];
		NSString * coverart=[[path stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"Cover Art"];
		coverart=[coverart stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]];
		coverart=[coverart stringByAppendingPathExtension:[poster pathExtension]];
		/* the fileAgent will do nothing if the file has already been moved or removed */		
		[fileAgent movePath:poster toPath:coverart handler:self] ;
		/* Lets clean up the Poster_Buffer */
		NSArray *oldPosters = [dict objectForKey:IMP_POSTERS_KEY];
		if([oldPosters count])
		{
			NSEnumerator *resultEnum = [oldPosters objectEnumerator];
			NSString *result = nil;
			while((result = [resultEnum nextObject]) != nil)
			{
				BOOL isDir=NO ;
				NSString *removeFile=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"],[result lastPathComponent]];
				[fileAgent fileExistsAtPath:removeFile isDirectory:&isDir];
				if(!isDir)[fileAgent removeFileAtPath:removeFile handler:self] ;
			}
		}
		[fileAgent release];
//		return NO;
	}
	
	/*Import the info*/
	/*IMDB Data */
	NSMutableDictionary *infoIMDB = nil;
	movieDataLink=[dict objectForKey:IMDB_LINK_KEY];
	infoIMDB = [self getMetaForMovie:movieDataLink withPath:path];
	if(!infoIMDB)
		return NO;
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
			NSString *filename = [[chooser fileName] lowercaseString];
			NSMutableDictionary * transDict = [movieTranslations objectForKey:filename];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:filename];
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
				/* User already selected a poster, skip */
				if(![transDict objectForKey:SELECTED_POSTER_KEY]) posterLinks=[self getPosterLinks:posterPath];
				if(posterLinks!=nil)
				{
					/* Add the poster links */
					[transDict setObject:posterLinks forKey:IMP_POSTERS_KEY];
				}
				/* Add another method via chooser incase IMDB doesn't have an IMP link */
			}
		}
		[self writeSettings];
		/*We can resume now*/
		[dataMenu resume];
	}
	else if([controller isKindOfClass:[SapphirePosterChooser class]])
	{
		SapphirePosterChooser *chooser = (SapphirePosterChooser *)controller;
		int selectedPoster = [chooser selectedPoster];
		if(selectedPoster == POSTER_CHOOSE_CANCEL)
			/*They aborted, skip*/
			[dataMenu skipNextItem];
		else
		{
			NSString *selected = [[chooser posters] objectAtIndex:selectedPoster];
			NSMutableDictionary * transDict = [movieTranslations objectForKey:[[chooser fileName]lowercaseString]];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:[[chooser fileName]lowercaseString]];
				[transDict release];
			}
			[transDict setObject:selected forKey:SELECTED_POSTER_KEY];
		}
		[self writeSettings];
		/*We can resume now*/
		[dataMenu resume];
	}
	else
		return;
}

@end