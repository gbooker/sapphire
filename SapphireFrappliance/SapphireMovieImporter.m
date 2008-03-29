/*
 * SapphireMovieImporter.m
 * Sapphire
 *
 * Created by Patrick Merrill on Sep. 10, 2007.
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

#import "SapphireMovieImporter.h"
#import "SapphireMetaData.h"
#import "NSString-Extensions.h"
#import "NSFileManager-Extensions.h"
#import "SapphireMovieChooser.h"
#import "SapphirePosterChooser.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireShowChooser.h"
#import "SapphireSettings.h"
#import "NSArray-Extensions.h"

#define VERSION_KEY					@"Version"
#define CURRENT_VERSION				2
/* Translation Keys */
#define TRANSLATIONS_KEY			@"Translations"
#define IMDB_LINK_KEY				@"IMDB Link"
#define IMP_LINK_KEY				@"IMP Link"
#define IMP_POSTERS_KEY				@"IMP Posters"
#define SELECTED_POSTER_KEY			@"Selected Poster"
#define AUTO_SELECT_POSTER_KEY		@"Default Poster"
 /* IMDB XPATHS */
#define	IMDB_SEARCH_XPATH				@"//td[starts-with(a/@href,'/title')]"
#define IMDB_UNIQUE_SEARCH_XPATH		@"//a[@class='tn15more inline']/@href"
#define IMDB_RESULT_LINK_XPATH			@"a/@href"
#define IMDB_POSTER_LINK_XPATH			@"//ul/li/a/@href"
#define	IMDB_RESULT_NAME_XPATH			@"normalize-space(string())"
#define IMDB_RESULT_TITLE_YEAR_XPATH	@"//div[@id='tn15title']/h1/replace(string(), '\n', '')"
#define IMDB_RESULT_INFO_XPATH	@"//div[@class='info']"
#define IMDB_RESTULT_CAST_NAMES_XPATH	@"//div[@class='info']/table/tr/td/a"
/* IMP XPATHS */
#define IMP_POSTER_CANDIDATES_XPATH		@"//img/@src"
#define IMP_LINK_REDIRECT_XPATH				@"//head/meta/@content/string()"




/*Delegate class to download cover art*/
@interface SapphireMovieDataMenuDownloadDelegate : NSObject
{
	NSString *destination;
	NSArray *requestList ;
	NSMutableArray *delegates ;
	long downloadsLeft ;
	id delegate;
}
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest delegate:(id)aDelegate;
- (void) downloadDidFinish: (NSURLDownload *) download;
- (void)downloadMoviePosters ;
-(void)downloadSingleMoviePoster;
@end

@interface NSObject (MovieDataDownloadDelegateDelegate)
- (void)downloadCompleted:(NSURLDownload *)download atIndex:(int)index;
@end

@implementation SapphireMovieDataMenuDownloadDelegate
/*!
* @brief Initialize a cover art downloader
 *
 * @param reqList The list of url requests to try
 * @param dest The path to save the file
 */
- (id)initWithRequest:(NSArray*)reqList withDestination:(NSString *)dest delegate:(id)aDelegate;
{
	self = [super init];
	if(!self)
		return nil;
	delegates = [NSMutableArray new];
	destination = [dest retain];
	requestList = [reqList retain];
	downloadsLeft=[requestList count];
	delegate = aDelegate;
	return self;	
}

- (void)dealloc
{
	[destination release];
	[requestList release];
	[delegates release];
	[super dealloc];
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

/*!
 * @brief Fire the delegate to start downloading a single poster
 *
 */
-(void)downloadSingleMoviePoster
{
	NSURL *posterURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMPAwards.com%@",[requestList objectAtIndex:0]]];
	NSString *fullDestination = destination;
	NSURLRequest *request = [NSURLRequest requestWithURL:posterURL];
	NSURLDownload *currentDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self] ;
	[currentDownload setDestination:fullDestination allowOverwrite:YES];
	[delegates addObject:currentDownload];
	[currentDownload release];
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
	downloadsLeft--;
	if([delegate respondsToSelector:@selector(downloadCompleted:atIndex:)])
		[delegate downloadCompleted:download atIndex:[delegates indexOfObject:download]];
}

@end

@interface SapphireMovieImporter (private)
- (void)writeSettings;
@end

@implementation SapphireMovieImporter

- (int)upgradeFromVersion1
{
	NSEnumerator *keyEnum = [[movieTranslations allKeys] objectEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		NSString *newKey = [key stringByDeletingPathExtension];
		if(![newKey isEqualToString:key])
		{
			[movieTranslations setObject:[movieTranslations objectForKey:key] forKey:newKey];
			[movieTranslations removeObjectForKey:key];
		}
	}
	return 2;
}

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
	
	int version = [[settings objectForKey:VERSION_KEY] intValue];
	if(version < CURRENT_VERSION)
	{
		if(version < 2)
			version = [self upgradeFromVersion1];
		[self writeSettings];
	}
	
	return self;
}

- (void)dealloc
{
	[movieTranslations release];
	[settingsPath release];
	[super dealloc];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	dataMenu = theDataMenu;
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
	NSMutableArray * candidatePosterLinks=[NSMutableArray arrayWithObjects:nil] ;
	NSString * yearPathComponent=[posterPageLink stringByDeletingLastPathComponent];
	
	/*Get the results list*/
	NSArray *results = [root objectsForXQuery:IMP_POSTER_CANDIDATES_XPATH error:&error];
	if([results count]<1)
	{
		/* IMDB had the wrong release year link, see if IMP Tried to redirect*/
		NSArray *newPosterPageLinkArray = [root objectsForXQuery:IMP_LINK_REDIRECT_XPATH error:&error];
		if([newPosterPageLinkArray count])
		{
			NSString * newPosterPageLink=[newPosterPageLinkArray objectAtIndex:0] ;
			NSScanner *trimmer=[NSScanner scannerWithString:newPosterPageLink];
			[trimmer scanUpToString:@"URL=.." intoString:&yearPathComponent];
			newPosterPageLink=[newPosterPageLink substringFromIndex:[yearPathComponent length]+6];
			yearPathComponent=[newPosterPageLink stringByDeletingLastPathComponent];
			url=[NSURL URLWithString:[NSString stringWithFormat:@"http://www.IMPAwards.com%@",newPosterPageLink]] ;
			document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyHTML error:&error];
			root = [document rootElement];
			results = [root objectsForXQuery:IMP_POSTER_CANDIDATES_XPATH error:&error];			
		}
	}

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
				[candidatePosterLinks addObject:subPath];
			}
			else if([resultURL hasPrefix:@"thumbs/"]) /* get the displayed poster link */
			{
				NSString * subPath=[resultURL substringFromIndex:11];
				subPath=[NSString stringWithFormat:[NSString stringWithFormat:@"%@/posters/%@",yearPathComponent,subPath]];
				[candidatePosterLinks addObject:subPath];
			}
		}
	}
	[candidatePosterLinks uniqueObjects];
	return [[candidatePosterLinks copy] autorelease];
}

- (void)downloadPosterCandidates:(NSArray *)posterCandidates
{
	/* download all posters to the scratch folder */
	NSString *posterBuffer = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
	[[NSFileManager defaultManager] constructPath:posterBuffer];
	SapphireMovieDataMenuDownloadDelegate *myDelegate = [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:posterCandidates withDestination:posterBuffer delegate:self];
	[myDelegate downloadMoviePosters] ;
	[myDelegate autorelease];
}

/*!
 * @brief A download completed
 *
 * @param download The download which completed
 * @param index The index of this poster
 */
- (void)downloadCompleted:(NSURLDownload *)download atIndex:(int)index;
{
	id controller = [[dataMenu stack] peekController];
	if([controller isKindOfClass:[SapphirePosterChooser class]])
		[posterChooser reloadPoster:index];
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
	
	/* Get the User Rating (IMDB) */
	NSArray *ratingCandidates=[document objectsForXQuery:@"//b/string()" error:&error];
	NSString *usrRating=[[document objectsForXQuery:@"//b/string()" error:&error] objectAtIndex:[ratingCandidates indexOfObject:@"User Rating:"]+1];
	metaTrimmer=[NSScanner scannerWithString:usrRating];
	[metaTrimmer scanUpToString:@"/" intoString:&usrRating];
	
	/* Check for IMDB top 250 */
	NSNumber * top250=nil ;
	NSArray *top250Candidate=[document objectsForXQuery:@"//div[@class='left']/a/string()" error:&error];

	if([top250Candidate count])
	{
		NSString *top250Str=[top250Candidate objectAtIndex:0];
		if([top250Str hasPrefix:@"Top 250:"])
			top250=[NSNumber numberWithInt:[[top250Str substringFromIndex:10] intValue]];
	}
		
	/* Get the release date */
	NSArray *rawData=[document objectsForXQuery:IMDB_RESULT_INFO_XPATH error:&error];
	NSDate * releaseDate=nil ;
	NSString * plot=nil;
	NSString * mpaaRating=nil;
	NSNumber * oscarsWon=nil ;
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
					NSString *writersStr = [[trimmer string] substringFromIndex:[trimmer scanLocation]+1];
					NSMutableArray *mutWrit = [[writersStr componentsSeparatedByString:@"\n"] mutableCopy];
					[mutWrit removeObject:@""];
					writers = [[mutWrit copy] autorelease];
					[mutWrit release];
				}
				else if([dataType hasPrefix:@"Director"])
				{
					NSString *directorsStr = [[trimmer string] substringFromIndex:[trimmer scanLocation]+1];
					NSMutableArray *mutDirs = [[directorsStr componentsSeparatedByString:@"\n"] mutableCopy];
					[mutDirs removeObject:@""];
					directors = [[mutDirs copy] autorelease];
					[mutDirs release];
				}
				else if([dataType hasPrefix:@"Awards"])
				{
					NSString *awardsStr = [[trimmer string] substringFromIndex:[trimmer scanLocation]+1];
					trimmer=[NSScanner scannerWithString:awardsStr];
					[trimmer scanUpToString:@" Oscars." intoString:&awardsStr];
					if([awardsStr length]<[[trimmer string] length])
					{
						awardsStr=[awardsStr substringFromIndex:3];
						oscarsWon=[NSNumber numberWithInt:[awardsStr intValue]];
					}
					else if([awardsStr hasPrefix:@"Won Oscar"])
						oscarsWon=[[NSNumber alloc] initWithInt:1];
					
				}
				else if([dataType hasPrefix:@"MPAA"])
				{
					NSString *mpaaStr = [[trimmer string] substringFromIndex:[trimmer scanLocation]+1];
					if([mpaaStr hasPrefix:@"Rated"])
					{
						trimmer=[NSScanner scannerWithString:[mpaaStr substringFromIndex:6]] ;
						[trimmer scanUpToString:@" " intoString:&mpaaRating];
					}
				}
				else if([dataType hasPrefix:@"Genre"])
				{

					NSMutableArray *myGenres=[NSMutableArray array];
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
							else if([aGenre hasSuffix:@"\n"])
								aGenre=[aGenre substringToIndex:[aGenre length]-1];
							[myGenres addObject:aGenre];
						}
						else
						{
							[trimmer scanUpToString:@" " intoString:&aGenre];
						}
					}
					genres = [[myGenres copy] autorelease];
				}
				else if([dataType hasPrefix:@"Plot Outline"])
				{
					[trimmer scanUpToString:@"more\n" intoString:&plot];
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
		NSMutableArray *results=nil;
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
						results=[NSMutableArray arrayWithObject:castName];
					else
						[results addObject:castName];
				}
				else continue ;
			}
			else
			continue ;
		}
		completeCast=[[results copy] autorelease] ;
	}
	
	
	/* populate metadata to return */
	[ret setObject:movieTitleLink forKey:META_MOVIE_IDENTIFIER_KEY];
	if(oscarsWon)
		[ret setObject:oscarsWon forKey:META_MOVIE_OSCAR_KEY];
	else
		[ret setObject:[NSNumber numberWithInt:0] forKey:META_MOVIE_OSCAR_KEY];
	if(top250)
		[ret setObject:top250 forKey:META_MOVIE_IMDB_250_KEY];
	if([usrRating length]>0)
		[ret setObject:[NSNumber numberWithFloat:[usrRating floatValue]] forKey:META_MOVIE_IMDB_RATING_KEY];
	if(mpaaRating)
		[ret setObject:mpaaRating forKey:META_MOVIE_MPAA_RATING_KEY];
	else
		[ret setObject:@"N/A" forKey:META_MOVIE_MPAA_RATING_KEY];
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
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@"(" withString:@" "];
	searchStr = [searchStr stringByReplacingAllOccurancesOf:@")" withString:@" "];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.imdb.com/find?s=all&site=aka&q=%@", [searchStr URLEncode]]];
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
				if([URLSubPath hasSuffix:@"/releaseinfo"])
				{
					URLSubPath=[URLSubPath stringByReplacingAllOccurancesOf:@"/releaseinfo" withString:@""];
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
				/* Deal with AKA titles */
				if([resultTitleValue hasPrefix:@"\n"])
				{
					resultTitleValue=[resultTitleValue substringFromIndex:3];
					resultTitle=[resultTitle stringByReplacingAllOccurancesOf:@"\n" withString:@" "];
				}
				/* Skip image links */
				else if(resultURL == nil || [resultTitleValue characterAtIndex:0] == 160)
					continue;
				/*Skip Video Game titles (VG) */
				if([resultTitleValue rangeOfString:@"(VG)"].location != NSNotFound)
					continue ;
				[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[[result objectsForXQuery:IMDB_RESULT_NAME_XPATH error:&error] objectAtIndex:0], @"name",
					[resultURL path], IMDB_LINK_KEY,
					nil]];
			}
		}
		if(!uniqueResult && [ret count]>0)return ret;
	}
	return nil ;
}


/*!
* @brief Write our setings out
 */
- (void)writeSettings
{
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:CURRENT_VERSION], VERSION_KEY,
		movieTranslations, TRANSLATIONS_KEY,
		nil];
	[settings writeToFile:settingsPath atomically:YES];
}

/*!
* @brief verify file extention of a file
 *
 * @param metaData The file's metadata
 * @return YES if candidate, NO otherwise
 */
- (BOOL)isMovieCandidate:(id <SapphireFileMetaDataProtocol>)metaData;
{
	NSString *fileExt = [[metaData path] pathExtension];
	if([[SapphireMetaData videoExtensions] member:fileExt])
		return YES;
	if([metaData fileContainerType] == FILE_CONTAINER_TYPE_VIDEO_TS)
		return YES;
	return NO ;
}

- (ImportState) importMetaData:(id <SapphireFileMetaDataProtocol>)metaData 
{
	currentData = metaData;
	/*Check to see if it is already imported*/
	if([metaData importedTimeFromSource:META_IMDB_IMPORT_KEY])
		return IMPORT_STATE_NOT_UPDATED;
	id controller = [[dataMenu stack] peekController];
	/* Check to see if we are waiting on the user to select a show title */
	if(![controller isKindOfClass:[SapphireImporterDataMenu class]])
	{
		/* Another chooser is on the screen - delay further processing */
		return IMPORT_STATE_NOT_UPDATED;
	}
	/*Get path*/
	if(![self isMovieCandidate:metaData])
		return IMPORT_STATE_NOT_UPDATED;
	NSString *path = [metaData path];
	NSString *fileName = [path lastPathComponent];
	/*choose between file or directory name for lookup */
	NSString *lookupName;
	if([[SapphireSettings sharedSettings] dirLookup])
		lookupName = [[path stringByDeletingLastPathComponent] lastPathComponent];
	else
		lookupName = fileName;
	if([metaData fileClass]==FILE_CLASS_TV_SHOW) /* File is a TV Show - skip it */
		return IMPORT_STATE_NOT_UPDATED;
	
	/*Get the movie title*/
	NSString *movieDataLink = nil ;
	/*Check to see if we know this movie*/
	NSMutableDictionary *dict=[movieTranslations objectForKey:[[lookupName lowercaseString] stringByDeletingPathExtension]];
	if(dict == nil)
	{
		if(dataMenu == nil)
		/*There is no data menu, background import. So we can't ask user, skip*/
			return IMPORT_STATE_NOT_UPDATED;
		/*Ask the user what movie this is*/
		NSArray *movies = [self searchResultsForMovie:lookupName];
		/* No need to prompt the user for an empty set */
		if(movies==nil)
		{
			/* We tried to import but found nothing - mark this file to be skipped on future imports */
			[metaData importInfo:[NSMutableDictionary dictionary] fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
			[metaData setFileClass:FILE_CLASS_OTHER];
			return IMPORT_STATE_UPDATED;
		}
		/*Bring up the prompt*/
		SapphireMovieChooser *chooser = [[SapphireMovieChooser alloc] initWithScene:[dataMenu scene]];
		[chooser setMovies:movies];
		[chooser setFileName:lookupName];		
		[chooser setListTitle:BRLocalizedString(@"Select Movie Title", @"Prompt the user for title of movie")];
		/*And display prompt*/
		[[dataMenu stack] pushController:chooser];
		[chooser release];
		return IMPORT_STATE_NEEDS_SUSPEND;
		//Data will be ready for access on the next call
	}

	NSString * selectedPoster=nil ;
	NSString * autoSelectPoster=nil ;
	selectedPoster =	[dict objectForKey:SELECTED_POSTER_KEY] ;
	autoSelectPoster=	[dict objectForKey:AUTO_SELECT_POSTER_KEY] ;
	if(!selectedPoster)
	{
		if(dataMenu == nil)
		/*There is no data menu, background import. So we can't ask user, skip*/
			return IMPORT_STATE_NOT_UPDATED;
		/* Posters will be downloaded, let the user choose one */
		[SapphireFrontRowCompat renderScene:[dataMenu scene]];
		NSArray *posters=[dict objectForKey:IMP_POSTERS_KEY];
		if(![posters count])
		{
			NSString *posterPath=nil ;
			/* Get the IMP Key with the IMDB Posters page */
			posterPath=[self getPosterPath:[dict objectForKey:IMDB_LINK_KEY]] ;
			if(posterPath!=nil)
			{
				[dict setObject:posterPath forKey:IMP_LINK_KEY];
				/*We got a posterPath, get the posterLinks */
				posters = [self getPosterLinks:posterPath];
				if(posters != nil)
				{
					/* Add the poster links */
					[dict setObject:posters forKey:IMP_POSTERS_KEY];
					[self writeSettings];
				}
				/* Add another method via chooser incase IMDB doesn't have an IMP link */
			}
			else posters=nil ;
		}
		if([posters count])
		{
			posterChooser=[[SapphirePosterChooser alloc] initWithScene:[dataMenu scene]];
			if(![posterChooser okayToDisplay])
			{
				if(autoSelectPoster==nil)
				{
					/* Auto Select the first poster */
					autoSelectPoster=[posters objectAtIndex:0];
					[dict setObject:autoSelectPoster forKey:AUTO_SELECT_POSTER_KEY];
					[self writeSettings];
				}
				[posterChooser release];
			}
			else
			{
				[self downloadPosterCandidates:posters];
				[posterChooser setPosters:posters] ;
				[posterChooser setFileName:lookupName];
				[posterChooser setFile:(SapphireFileMetaData *)metaData];
				[posterChooser setListTitle:BRLocalizedString(@"Select Movie Poster", @"Prompt the user for poster selection")];
				[[dataMenu stack] pushController:posterChooser];
				[posterChooser release];
				return IMPORT_STATE_NEEDS_SUSPEND;
			}
			[dataMenu resume];
		}
	}
	if(selectedPoster && [dict objectForKey:IMP_POSTERS_KEY])
	{
		/* Lets move the selected poster to the corresponding Cover Art Directory */
		NSFileManager *fileAgent=[NSFileManager defaultManager];
		NSString * poster=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"];
		poster=[poster stringByAppendingPathComponent:[selectedPoster lastPathComponent]];
		NSString * coverart=[[SapphireMetaData collectionArtPath]stringByAppendingPathComponent:@"@MOVIES"];
		[fileAgent constructPath:coverart];
		coverart=[coverart stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]];
		coverart=[coverart stringByAppendingPathExtension:[poster pathExtension]];
		if([fileAgent fileExistsAtPath:poster])/* See if we need to clean up */
		{
			if([fileAgent fileExistsAtPath:coverart])/* Remove old poster */
				[fileAgent removeFileAtPath:coverart handler:self];
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
		}
		else if(![fileAgent fileExistsAtPath:coverart])
		{
			/* We have seen this file before, but in a different location */
			/* - OR - the coverart has been deleted */
			NSArray * posterList=[NSArray arrayWithObject:selectedPoster];
			SapphireMovieDataMenuDownloadDelegate *myDelegate = [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:posterList withDestination:coverart delegate:self];
			[myDelegate downloadSingleMoviePoster] ;
			[myDelegate autorelease];
		}
	}
	else if(autoSelectPoster)
	{
		/* The poster chooser wasn't loaded - ATV 1.0 */
		NSFileManager *fileAgent=[NSFileManager defaultManager];
		NSString * coverart=[[SapphireMetaData collectionArtPath]stringByAppendingPathComponent:@"@MOVIES"];
		[fileAgent constructPath:coverart];
		NSArray * posterList=[NSArray arrayWithObject:autoSelectPoster];
		coverart=[coverart stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]];
		coverart=[coverart stringByAppendingPathExtension:[autoSelectPoster pathExtension]];
		SapphireMovieDataMenuDownloadDelegate *myDelegate = [[SapphireMovieDataMenuDownloadDelegate alloc] initWithRequest:posterList withDestination:coverart delegate:self];
		[myDelegate downloadSingleMoviePoster] ;
		[myDelegate autorelease];	
	}
	
	/*Import the info*/
	/*IMDB Data */
	NSMutableDictionary *infoIMDB = nil;
	movieDataLink=[dict objectForKey:IMDB_LINK_KEY];
	infoIMDB = [self getMetaForMovie:movieDataLink withPath:path];
	if(!infoIMDB)
		return IMPORT_STATE_NOT_UPDATED;
	[infoIMDB removeObjectForKey:IMDB_LINK_KEY];
	[metaData importInfo:infoIMDB fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
	[metaData setFileClass:FILE_CLASS_MOVIE];
	/*We imported something*/
	return IMPORT_STATE_UPDATED;
}


- (NSString *)completionText
{
	return BRLocalizedString(@"All availble Movie data has been imported", @"The Movie import is complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Fetch Movie Data", @"Title");
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
	/*See if it was a movie chooser*/
	if([controller isKindOfClass:[SapphireMovieChooser class]])
	{
		/*Get the user's selection*/
		SapphireMovieChooser *chooser = (SapphireMovieChooser *)controller;
		int selection = [chooser selection];
		if(selection == MOVIE_CHOOSE_CANCEL)
		{
			/*They aborted, skip*/
			[dataMenu skipNextItem];
		}
		else if(selection == MOVIE_CHOOSE_NOT_MOVIE)
		{
			/*They said it is not a movie, so put in empty data so they are not asked again*/
			[currentData importInfo:[NSMutableDictionary dictionary] fromSource:META_IMDB_IMPORT_KEY withTime:[[NSDate date] timeIntervalSince1970]];
			if ([currentData fileClass] != FILE_CLASS_TV_SHOW)
				[currentData setFileClass:FILE_CLASS_UNKNOWN];
		}
		else
		{
			/*They selected a movie title, save the translation and write it*/
			NSDictionary *movie = [[chooser movies] objectAtIndex:selection];
			NSString *filename = [[[chooser fileName] lowercaseString] stringByDeletingPathExtension];
			NSMutableDictionary * transDict = [movieTranslations objectForKey:filename];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:filename];
				[transDict release];
			}
			/* Add IMDB Key */
			[transDict setObject:[movie objectForKey:IMDB_LINK_KEY] forKey:IMDB_LINK_KEY];
		}
		[self writeSettings];
		/*We can resume now*/
		[dataMenu resume];
	}
	else if([controller isKindOfClass:[SapphirePosterChooser class]])
	{
		int selectedPoster = [posterChooser selectedPoster];
		if(selectedPoster == POSTER_CHOOSE_CANCEL)
			/*They aborted, skip*/
			[dataMenu skipNextItem];
		else
		{
			NSString *selected = [[posterChooser posters] objectAtIndex:selectedPoster];
			NSString *filename = [[[posterChooser fileName] lowercaseString] stringByDeletingPathExtension];
			NSMutableDictionary * transDict = [movieTranslations objectForKey:filename];
			if(transDict == nil)
			{
				transDict=[NSMutableDictionary new] ;
				[movieTranslations setObject:transDict forKey:filename];
				[transDict release];
			}
			[transDict setObject:selected forKey:SELECTED_POSTER_KEY];
		}
		posterChooser = nil;
		[self writeSettings];
		/*We can resume now*/
		[dataMenu resume];
	}
	else
		return;
}

@end