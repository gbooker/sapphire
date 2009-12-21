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
#import "SapphireFileMetaData.h"
#import "NSFileManager-Extensions.h"
#import "SapphireMovieChooser.h"
#import "SapphirePosterChooser.h"
#import "SapphireSettings.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireMovie.h"
#import "SapphireMovieTranslation.h"
#import "SapphireMoviePoster.h"
#import "SapphireApplianceController.h"
#import "SapphireURLLoader.h"
#import "SapphireScraper.h"

#define MOVIE_TRAN_IMDB_NAME_KEY				@"name"
#define MOVIE_TRAN_IMDB_LINK_KEY				@"IMDB Link"

@interface SapphireMovieImportStateData : SapphireImportStateData
{
@public
	SapphireSiteMovieScraper	*siteScraper;
}
- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath scraper:(SapphireSiteMovieScraper *)siteScaper;
@end

@implementation SapphireMovieImportStateData

- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath scraper:(SapphireSiteMovieScraper *)aSiteScaper
{
	self = [super initWithFile:aFile atPath:aPath];
	if(!self)
		return self;
	
	siteScraper = [aSiteScaper retain];
	
	return self;
}

- (void)dealloc
{
	[siteScraper release];
	[super dealloc];
}

@end



@interface SapphireMovieImporter (private)
- (void)getMovieResultsForState:(SapphireMovieImportStateData *)state translation:(SapphireMovieTranslation *)tran;
- (void)getMoviePostersForState:(SapphireMovieImportStateData *)state translation:(SapphireMovieTranslation *)tran thumbElements:(NSArray *)thumbElements;
- (void)saveMoviePosterAtURL:(NSString *)url forTranslation:(SapphireMovieTranslation *)tran;
- (void)completeWithState:(SapphireMovieImportStateData *)state withStatus:(ImportState)status userCanceled:(BOOL)userCanceled;
@end

@implementation SapphireMovieImporter

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	NSError *error = nil;
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [selfBundle pathForResource:@"imdb" ofType:@"xml" inDirectory:@"scrapers"];
	scraper = [[SapphireMovieScraper alloc] initWithPath:path error:&error];
	
	return self;
}

- (void)dealloc
{
	[scraper release];
	[super dealloc];
}


- (void)setDelegate:(id <SapphireImporterDelegate>)aDelegate
{
	delegate = aDelegate;
}

- (void)cancelImports
{
	cancelled = YES;
}

- (void)retrievedSearchResuls:(NSXMLDocument *)results forObject:(SapphireMovieImportStateData *)state
{
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	NSXMLElement *root = [results rootElement];
	NSArray *entities = [root elementsForName:@"entity"];
	NSMutableArray *movies = [[NSMutableArray alloc] initWithCapacity:[entities count]];
	NSEnumerator *entityEnum = [entities objectEnumerator];
	NSXMLElement *entity;
	while((entity = [entityEnum nextObject]) != nil)
	{
		NSString *kind = stringValueOfChild(entity, @"kind");
		
		//Skip video games and tv series
		if([kind isEqualToString:@"VG"] || [kind isEqualToString:@"TV series"])
			continue;
		
		NSString *title = stringValueOfChild(entity, @"title");
		NSString *url = stringValueOfChild(entity, @"url");
		if([url length])
		{
			NSURL *trimmer = [NSURL URLWithString:url];
			url = [trimmer path];
		}
		NSString *year = stringValueOfChild(entity, @"year");
		if([year length])
			title = [title stringByAppendingFormat:@" (%@)", year];
		
		if([title length] && [url length])
			[movies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   title, MOVIE_TRAN_IMDB_NAME_KEY,
							   url, MOVIE_TRAN_IMDB_LINK_KEY,
							   nil]];
	}
	
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Found results: %@", movies);
	
	/* No need to prompt the user for an empty set */
	if(![movies count])
	{
		/* We tried to import but found nothing - mark this file to be skipped on future imports */
		[self completeWithState:state withStatus:ImportStateNotUpdated userCanceled:NO];
	}
	if([[SapphireSettings sharedSettings] autoSelection])
	{
		SapphireFileMetaData *metaData = state->file;
		NSManagedObjectContext *moc = [metaData managedObjectContext];
		NSString *lookupName = [[state->lookupName lowercaseString] stringByDeletingPathExtension];
		SapphireMovieTranslation *tran = [SapphireMovieTranslation createMovieTranslationWithName:lookupName inContext:moc];
		[tran setIMDBLink:[[movies objectAtIndex:0] objectForKey:MOVIE_TRAN_IMDB_LINK_KEY]];
		[self getMovieResultsForState:state translation:tran];
	}
	else
	{
		/*Bring up the prompt*/
		SapphireMovieChooser *chooser = [[SapphireMovieChooser alloc] initWithScene:[delegate chooserScene]];
		[chooser setMovies:movies];
		[chooser setFileName:state->lookupName];		
		[chooser setListTitle:BRLocalizedString(@"Select Movie Title", @"Prompt the user for title of movie")];
		/*And display prompt*/
		[delegate displayChooser:chooser forImporter:self withContext:state];
		[chooser release];
	}
	[movies release];
}

- (ImportState)getMovieResultsForState:(SapphireMovieImportStateData *)state translation:(SapphireMovieTranslation *)tran
{
	NSString *link = [tran IMDBLink];
	SapphireSiteMovieScraper *siteScraper = state->siteScraper;
	[siteScraper setObject:state];
	NSString *fullURL = [@"http://akas.imdb.com" stringByAppendingString:link];
	if([fullURL characterAtIndex:[fullURL length]-1] != '/')
		fullURL = [fullURL stringByAppendingString:@"/"];
	[siteScraper getMovieDetailsAtURL:fullURL forMovieID:[link lastPathComponent]];
}

- (void)retrievedMovieDetails:(NSXMLDocument *)details forObject:(SapphireMovieImportStateData *)state
{
	[state->siteScraper setObject:nil];	//Avoid retain loop

	if(cancelled)
		return;
	
	NSXMLElement *root = [details rootElement];
	
	NSString	*movieTitleLink	= stringValueOfChild(root, @"id");
	NSNumber	*oscarsWon		= intValueOfChild(root, @"oscars");
	NSDate		*releaseDate	= dateValueOfChild(root, @"releasedate");
	NSString	*plot			= stringValueOfChild(root, @"plot");
	NSString	*mpaaStr		= stringValueOfChild(root, @"mpaa");
	NSArray		*directors		= arrayStringValueOfChild(root, @"director");
	NSArray		*genres			= arrayStringValueOfChild(root, @"genre");
	NSNumber	*top250			= intValueOfChild(root, @"top250");
	NSString	*usrRating		= stringValueOfChild(root, @"rating");
	NSArray		*completeCast	= arrayStringValueOfXPath(root, @"actor/name");
	NSString	*movieTitle		= stringValueOfChild(root, @"title");
	
	NSString *mpaaRating = nil;
	if([mpaaStr hasPrefix:@"Rated"])
	{
		NSScanner *trimmer=[NSScanner scannerWithString:[mpaaStr substringFromIndex:6]] ;
		[trimmer scanUpToString:@" " intoString:&mpaaRating];
	}	
	
	
	NSMutableDictionary *infoIMDB = [NSMutableDictionary dictionary];
	/* populate metadata to return */
	[infoIMDB setObject:movieTitleLink forKey:META_MOVIE_IDENTIFIER_KEY];
	if(oscarsWon)
		[infoIMDB setObject:oscarsWon forKey:META_MOVIE_OSCAR_KEY];
	else
		[infoIMDB setObject:[NSNumber numberWithInt:0] forKey:META_MOVIE_OSCAR_KEY];
	if(top250)
		[infoIMDB setObject:top250 forKey:META_MOVIE_IMDB_250_KEY];
	if([usrRating length]>0)
		[infoIMDB setObject:[NSNumber numberWithFloat:[usrRating floatValue]] forKey:META_MOVIE_IMDB_RATING_KEY];
	if(mpaaRating)
		[infoIMDB setObject:mpaaRating forKey:META_MOVIE_MPAA_RATING_KEY];
	else
		[infoIMDB setObject:@"N/A" forKey:META_MOVIE_MPAA_RATING_KEY];
	if(directors)
		[infoIMDB setObject:directors forKey:META_MOVIE_DIRECTOR_KEY];
	if(plot)
		[infoIMDB setObject:plot forKey:META_MOVIE_PLOT_KEY];
	if(releaseDate)
		[infoIMDB setObject:releaseDate forKey:META_MOVIE_RELEASE_DATE_KEY];
	if(genres)
		[infoIMDB setObject:genres forKey:META_MOVIE_GENRES_KEY];
	if(completeCast)
		[infoIMDB setObject:completeCast forKey:META_MOVIE_CAST_KEY];
	if(movieTitle)
		[infoIMDB setObject:movieTitle forKey:META_MOVIE_TITLE_KEY];
	
	NSString *movieTranslationString = [[state->lookupName lowercaseString] stringByDeletingPathExtension];
	SapphireFileMetaData *metaData = state->file;
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	SapphireMovieTranslation *tran = [SapphireMovieTranslation movieTranslationWithName:movieTranslationString inContext:moc];
	SapphireMovie *movie = [SapphireMovie movieWithDictionary:infoIMDB inContext:moc];
	if(movie == nil)
	{
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_ERROR, @"Failed to import movie for %@", state->path);
		[self completeWithState:state withStatus:ImportStateNotUpdated userCanceled:NO];
	}
	[tran setMovie:movie];
	[metaData setMovie:movie];
	
	NSArray *thumbs = [root elementsForName:@"thumb"];
	NSXMLElement *fanart = [[root elementsForName:@"fanart"] lastObject];
	if(fanart)
		thumbs = [thumbs arrayByAddingObjectsFromArray:[fanart elementsForName:@"thumb"]];
	
	if([thumbs count])
		[self getMoviePostersForState:state translation:tran thumbElements:thumbs];
	else
		[self completeWithState:state withStatus:ImportStateUpdated userCanceled:NO];
}

- (void)getMoviePostersForState:(SapphireMovieImportStateData *)state translation:(SapphireMovieTranslation *)tran thumbElements:(NSArray *)thumbElements;
{
	NSMutableArray *previews = [NSMutableArray arrayWithCapacity:[thumbElements count]];
	if([thumbElements count])
	{
		int index = 0;
		NSManagedObjectContext *moc = [tran managedObjectContext];
		NSEnumerator *thumbEnum = [thumbElements objectEnumerator];
		NSXMLElement *thumb;
		NSMutableSet *posterSet = [NSMutableSet setWithCapacity:[thumbElements count]];
		while((thumb = [thumbEnum nextObject]) != nil)
		{
			NSString *preview = [[thumb attributeForName:@"preview"] stringValue];
			NSString *url = [thumb stringValue];
			if(![preview length])
				preview = url;
			
			[previews addObject:preview];
			[posterSet addObject:[SapphireMoviePoster createPosterWithLink:url index:index translation:tran inContext:moc]];
			index++;
		}
		[[tran postersSet] setSet:posterSet];
	}
	else
	{
		NSArray *posters = [tran orderedPosters];
		NSEnumerator *posterEnum = [posters objectEnumerator];
		SapphireMoviePoster *poster;
		while((poster = [posterEnum nextObject]) != nil)
		{
			NSString *link = [poster link];
			if(![link hasPrefix:@"http://"])
			{
				link = [@"http://www.IMPAwards.com" stringByAppendingString:link];
				[poster setLink:link];
			}
			[previews addObject:link];
		}
	}
	if([previews count])
	{
		SapphirePosterChooser *posterChooser = [[SapphirePosterChooser alloc] initWithScene:[delegate chooserScene]];
		if(![posterChooser okayToDisplay] || [[SapphireSettings sharedSettings] autoSelection])
		{
			/* Auto Select the first poster */
			[self saveMoviePosterAtURL:[[tran posterAtIndex:0] link] forTranslation:tran];
			[posterChooser release];
		}
		else
		{
			[posterChooser setPosters:previews];
			[posterChooser setFileName:state->lookupName];
			[posterChooser setFile:state->file];
			[posterChooser setListTitle:BRLocalizedString(@"Select Movie Poster", @"Prompt the user for poster selection")];
			[delegate displayChooser:posterChooser forImporter:self withContext:state];
			[posterChooser release];
		}		
	}
}

- (void)saveMoviePosterAtURL:(NSString *)url forTranslation:(SapphireMovieTranslation *)tran
{
	NSString *coverart = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:@"@MOVIES"];
	[[NSFileManager defaultManager] constructPath:coverart];
	int imdbNumber = [SapphireMovie imdbNumberFromString:[tran IMDBLink]];
	coverart = [coverart stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", imdbNumber]];
	[[SapphireApplianceController urlLoader] saveDataAtURL:url toFile:coverart];	
}

- (void)completeWithState:(SapphireMovieImportStateData *)state withStatus:(ImportState)status userCanceled:(BOOL)userCanceled;
{
	SapphireFileMetaData *currentData = state->file;
	if(!userCanceled)
	{
		[currentData didImportType:IMPORT_TYPE_MOVIE_MASK];
		if (status == ImportStateNotUpdated || [currentData fileClassValue] != FILE_CLASS_TV_SHOW)
			[currentData setFileClassValue:FILE_CLASS_UNKNOWN];
	}
	[delegate backgroundImporter:self completedImportOnPath:state->path withState:status];
}

/*!
* @brief verify file extention of a file
 *
 * @param metaData The file's metadata
 * @return YES if candidate, NO otherwise
 */
- (BOOL)isMovieCandidate:(SapphireFileMetaData *)metaData;
{
	NSString *path = [metaData path];
	BOOL ret = [[NSFileManager defaultManager] acceptFilePath:path];
	if([metaData fileContainerType] == FILE_CONTAINER_TYPE_QT_MOVIE)
		ret &= [[NSFileManager videoExtensions] containsObject:[path pathExtension]];
	if([metaData fileClassValue]==FILE_CLASS_TV_SHOW) /* File is a TV Show - skip it */
		ret = NO;
	return ret;
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	cancelled = NO;
	/*Check to see if it is already imported*/
	if([metaData importTypeValue] & IMPORT_TYPE_MOVIE_MASK)
		return ImportStateNotUpdated;
	/*Get path*/
	if(![self isMovieCandidate:metaData])
		return ImportStateNotUpdated;
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Going to movie import %@", path);
	NSString *fileName = [path lastPathComponent];
	/*choose between file or directory name for lookup */
	NSString *lookupName;
	if([[SapphireSettings sharedSettings] dirLookup])
		lookupName = [[path stringByDeletingLastPathComponent] lastPathComponent];
	else
		lookupName = fileName;
	
	SapphireSiteMovieScraper *siteScraper = [[[SapphireSiteMovieScraper alloc] initWithMovieScraper:scraper delegate:self loader:[SapphireApplianceController urlLoader]] autorelease];
	SapphireMovieImportStateData *state = [[[SapphireMovieImportStateData alloc] initWithFile:metaData atPath:path scraper:siteScraper] autorelease];
	[state setLookupName:lookupName];
	/*Get the movie title*/
	NSString *movieDataLink = nil ;
	/*Check to see if we know this movie*/
	NSString *movieTranslationString = [[lookupName lowercaseString] stringByDeletingPathExtension];
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Searching for movie %@", movieTranslationString);
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	SapphireMovieTranslation *tran = [SapphireMovieTranslation movieTranslationWithName:movieTranslationString inContext:moc];
	int searchIMDBNumber = [metaData searchIMDBNumber];
	if(searchIMDBNumber > 0)
	{
		if(!tran)
			tran = [SapphireMovieTranslation createMovieTranslationWithName:movieTranslationString inContext:moc];
		[tran setIMDBLink:[NSString stringWithFormat:@"/title/tt%d", searchIMDBNumber]];
	}
	if([tran IMDBLink] == nil)
	{
		if(![delegate canDisplayChooser])
		/*There is no data menu, background import. So we can't ask user, skip*/
			return ImportStateNotUpdated;
		
		/*Look for a year in the title*/
		NSString *searchStr = [lookupName stringByDeletingPathExtension];
		NSScanner *titleYearScanner = [NSScanner scannerWithString:searchStr];
		NSString *normalTitle = nil;
		int year = 0;
		BOOL success = YES;
		success &= [titleYearScanner scanUpToString:@"(" intoString:&normalTitle];
		NSString *junk = nil;
		success &= [titleYearScanner scanString:@"(" intoString:nil];
		success &= [titleYearScanner scanInt:&year];
		success &= [titleYearScanner scanString:@")" intoString:nil];
		
		NSString *yearStr = nil;
		if(!success)
		{
			normalTitle = searchStr;
		}
		else
			yearStr = [NSString stringWithFormat:@"%d", year];
		
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Searching for %@ with year %@", normalTitle, yearStr);
		
		/*Ask the user what movie this is*/
		[siteScraper setObject:state];
		[siteScraper searchForMovieName:normalTitle year:yearStr];
		return ImportStateBackground;
	}
	
	SapphireMovie *movie = [tran movie];
	if(movie != nil)
	{	
		[metaData setMovie:movie];
		return ImportStateUpdated;
	}
	[self getMovieResultsForState:state translation:tran];
	return ImportStateBackground;
}


- (NSString *)completionText
{
	return BRLocalizedString(@"All available Movie data has been imported", @"The Movie import is complete");
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

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(SapphireMovieImportStateData *)state
{
	/*See if it was a movie chooser*/
	if([chooser isKindOfClass:[SapphireMovieChooser class]])
	{
		/*Get the user's selection*/
		SapphireMovieChooser *movieChooser = (SapphireMovieChooser *)chooser;
		SapphireFileMetaData *currentData = state->file;
		NSString *path = state->path;
		NSManagedObjectContext *moc = [currentData managedObjectContext];
		int selection = [movieChooser selection];
		if(selection == SapphireChooserChoiceCancel)
		{
			/*They aborted, skip*/
			[self completeWithState:state withStatus:ImportStateNotUpdated userCanceled:YES];
		}
		else if(selection == SapphireChooserChoiceNotType)
		{
			/*They said it is not a movie, so put in empty data so they are not asked again*/
			[self completeWithState:state withStatus:ImportStateNotUpdated userCanceled:NO];
		}
		else
		{
			/*They selected a movie title, save the translation and write it*/
			NSDictionary *movie = [[movieChooser movies] objectAtIndex:selection];
			NSString *filename = [[[movieChooser fileName] lowercaseString] stringByDeletingPathExtension];
			SapphireMovieTranslation *tran = [SapphireMovieTranslation createMovieTranslationWithName:filename inContext:moc];
			/* Add IMDB Key */
			[tran setIMDBLink:[movie objectForKey:MOVIE_TRAN_IMDB_LINK_KEY]];
			/*We can resume now*/
			[self getMovieResultsForState:state translation:tran];
		}
		[SapphireMetaDataSupport save:moc];
	}
	else if([chooser isKindOfClass:[SapphirePosterChooser class]])
	{
		SapphirePosterChooser *posterChooser = (SapphirePosterChooser *)chooser;
		SapphireFileMetaData *currentData = state->file;
		NSString *path = state->path;
		NSManagedObjectContext *moc = [currentData managedObjectContext];
		SapphireChooserChoice selectedPoster = [posterChooser selection];
		if(selectedPoster == SapphireChooserChoiceCancel)
			/*They aborted, skip*/
			[self completeWithState:state withStatus:ImportStateNotUpdated userCanceled:YES];
		else
		{
			NSString *filename = [[[posterChooser fileName] lowercaseString] stringByDeletingPathExtension];
			SapphireMovieTranslation *tran = [SapphireMovieTranslation createMovieTranslationWithName:filename inContext:moc];
			[tran setSelectedPosterIndexValue:selectedPoster];
			[self saveMoviePosterAtURL:[[tran posterAtIndex:selectedPoster] link] forTranslation:tran];
			[self completeWithState:state withStatus:ImportStateUpdated userCanceled:NO];
		}
		posterChooser = nil;
		[SapphireMetaDataSupport save:moc];
	}
	else
		return;
}

@end