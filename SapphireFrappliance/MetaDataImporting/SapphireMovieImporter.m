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
#import "NSString-Extensions.h"

@interface SapphireMovieImportStateData : SapphireImportStateData
{
@public
	SapphireSiteMovieScraper	*siteScraper;
	SapphireMovieTranslation	*translation;
}
- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath scraper:(SapphireSiteMovieScraper *)siteScaper;
- (void)setTranslation:(SapphireMovieTranslation *)aTranslation;
- (SapphireMovieTranslation *)createTranslationInContext:(NSManagedObjectContext *)moc;
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
	[translation release];
	[super dealloc];
}

- (void)setTranslation:(SapphireMovieTranslation *)aTranslation
{
	[translation autorelease];
	translation = [aTranslation retain];
}

- (SapphireMovieTranslation *)createTranslationInContext:(NSManagedObjectContext *)moc
{
	SapphireMovieTranslation *tran = [SapphireMovieTranslation createMovieTranslationWithName:lookupName inContext:moc];
	tran.importerID = [[siteScraper scraper] name];
	[self setTranslation:tran];
	return tran;
}

@end



@interface SapphireMovieImporter ()
- (void)getMovieResultsForState:(SapphireMovieImportStateData *)state;
- (void)getMoviePostersForState:(SapphireMovieImportStateData *)state thumbElements:(NSArray *)thumbElements;
- (void)saveMoviePosterAtURL:(NSString *)url forTranslation:(SapphireMovieTranslation *)tran;
- (void)completeWithState:(SapphireMovieImportStateData *)state withStatus:(ImportState)status importComplete:(BOOL)importComplete;
@end

@implementation SapphireMovieImporter

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	scraper = [[SapphireScraper scrapperWithName:@"IMDb.com"] retain];
	
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

- (void)retrievedSearchResuls:(NSXMLDocument *)results forObject:(id)stateObj
{
	SapphireMovieImportStateData *state = (SapphireMovieImportStateData *)stateObj;
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	if(results == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	NSXMLElement *root = [results rootElement];
	NSArray *entities = [root elementsForName:@"entity"];
	NSMutableArray *movies = [[NSMutableArray alloc] initWithCapacity:[entities count]];
	NSEnumerator *entityEnum = [entities objectEnumerator];
	NSXMLElement *entity;
	while((entity = [entityEnum nextObject]) != nil)
	{
		NSString *kind = stringValueOfChild(entity, @"kind");
		
		/*Skip video games and tv series*/
		if([kind isEqualToString:@"VG"] || [kind isEqualToString:@"TV series"])
			continue;
		
		NSString *title = stringValueOfChild(entity, @"title");
		NSString *itemID = stringValueOfChild(entity, @"id");
		NSString *url = stringValueOfChild(entity, @"url");
		NSString *year = stringValueOfChild(entity, @"year");
		if([year length])
			title = [title stringByAppendingFormat:@" (%@)", year];
		
		if([title length] && [url length])
			[movies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   title, movieTranslationNameKey,
							   url, movieTranslationLinkKey,
							   itemID, movieTranslationIDKey,
							   nil]];
	}
	
	SapphireLog(SapphireLogTypeImport, SapphireLogLevelDetail, @"Found results: %@", movies);
	
	/* No need to prompt the user for an empty set */
	if(![movies count])
	{
		/* We tried to import but found nothing - mark this file to be skipped on future imports */
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:YES];
	}
	else if([[SapphireSettings sharedSettings] autoSelection])
	{
		SapphireFileMetaData *metaData = state->file;
		NSManagedObjectContext *moc = [metaData managedObjectContext];
		SapphireMovieTranslation *tran = [state createTranslationInContext:moc];
		tran.url = [[movies objectAtIndex:0] objectForKey:movieTranslationLinkKey];
		tran.itemID = [[movies objectAtIndex:0] objectForKey:movieTranslationIDKey];
		[self getMovieResultsForState:state];
	}
	else
	{
		/*Bring up the prompt*/
		SapphireMovieChooser *chooser = [[SapphireMovieChooser alloc] initWithScene:[delegate chooserScene]];
		[chooser setMovies:movies];
		[chooser setFileName:[NSString stringByCroppingDirectoryPath:state->path toLength:3]];
		[chooser setListTitle:BRLocalizedString(@"Select Movie Title", @"Prompt the user for title of movie")];
		/*And display prompt*/
		[delegate displayChooser:chooser forImporter:self withContext:state];
		[chooser release];
	}
	[movies release];
}

- (void)getMovieResultsForState:(SapphireMovieImportStateData *)state
{
	SapphireMovieTranslation *tran = state->translation;
	NSString *link = tran.url;
	SapphireSiteMovieScraper *siteScraper = state->siteScraper;
	[siteScraper setObject:state];
	[siteScraper getMovieDetailsAtURL:link forMovieID:tran.itemID];
}

- (void)retrievedMovieDetails:(NSXMLDocument *)details forObject:(id)stateObj
{
	SapphireMovieImportStateData *state = (SapphireMovieImportStateData *)stateObj;
	[state->siteScraper setObject:nil];	//Avoid retain loop

	if(cancelled)
		return;
	
	if(details == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
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
	
	if([movieTitle rangeOfString:@"Request Limit Reached"].location != NSNotFound)
	{
		/*IMDB said we hit them too much; abort this data*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	
	NSString *mpaaRating = nil;
	if([mpaaStr hasPrefix:@"Rated"])
	{
		NSScanner *trimmer=[NSScanner scannerWithString:[mpaaStr substringFromIndex:6]] ;
		[trimmer scanUpToString:@" " intoString:&mpaaRating];
	}
	else
	{
		NSArray *certifications = arrayStringValueOfXPath(root, @"certification");
		NSString *certification;
		NSEnumerator *certEnum = [certifications objectEnumerator];
		while((certification = [certEnum nextObject]) != nil)
		{
			if([certification hasPrefix:@"USA:"])
			{
				NSScanner *trimmer=[NSScanner scannerWithString:[certification substringFromIndex:4]];
				[trimmer scanUpToString:@" " intoString:&mpaaRating];
			}
		}
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
	
	SapphireFileMetaData *metaData = state->file;
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	SapphireMovie *movie = [SapphireMovie movieWithDictionary:infoIMDB inContext:moc];
	if(movie == nil)
	{
		SapphireLog(SapphireLogTypeImport, SapphireLogLevelError, @"Failed to import movie for %@", state->path);
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	SapphireMovieTranslation *tran = state->translation;
	[tran setMovie:movie];
	[metaData setMovie:movie];
	
	SapphireMoviePoster *poster = [tran selectedPoster];
	if(poster != nil)
	{
		[self saveMoviePosterAtURL:[poster link] forTranslation:tran];
		[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
	}
	else
	{
		NSArray *thumbs = [root elementsForName:@"thumb"];
		NSXMLElement *fanart = [[root elementsForName:@"fanart"] lastObject];
		if(fanart)
			thumbs = [thumbs arrayByAddingObjectsFromArray:[fanart elementsForName:@"thumb"]];
		
		BOOL canDisplay = [delegate canDisplayChooser];
		if(canDisplay && [thumbs count])
			[self getMoviePostersForState:state thumbElements:thumbs];
		else
			[self completeWithState:state withStatus:ImportStateUpdated importComplete:canDisplay];
	}
}

- (void)getMoviePostersForState:(SapphireMovieImportStateData *)state thumbElements:(NSArray *)thumbElements;
{
	NSMutableArray *previews = [NSMutableArray arrayWithCapacity:[thumbElements count]];
	SapphireMovieTranslation *tran = state->translation;
	if([thumbElements count])
	{
		int index = 0;
		NSManagedObjectContext *moc = [tran managedObjectContext];
		//Redoing posters, get rid of old ones
		[tran setSelectedPosterIndex:nil];
		NSEnumerator *posterEnum = [[tran postersSet] objectEnumerator];
		SapphireMoviePoster *poster;
		while((poster = [posterEnum nextObject]) != nil)
			[moc deleteObject:poster];
		
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
			[previews addObject:link];
		}
	}
	if([tran selectedPoster])
	{
		[self saveMoviePosterAtURL:[[tran selectedPoster] link] forTranslation:tran];
		[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
	}
	else if([previews count])
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
			[posterChooser setFileName:[NSString stringByCroppingDirectoryPath:state->path toLength:3]];
			[posterChooser setFile:state->file];
			[posterChooser setListTitle:BRLocalizedString(@"Select Movie Poster", @"Prompt the user for poster selection")];
			[delegate displayChooser:posterChooser forImporter:self withContext:state];
			[posterChooser release];
		}		
	}
	else
		[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
}

- (void)saveMoviePosterAtURL:(NSString *)url forTranslation:(SapphireMovieTranslation *)tran
{
	NSString *coverart = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:@"@MOVIES"];
	[[NSFileManager defaultManager] constructPath:coverart];
	int imdbNumber = [SapphireMovie imdbNumberFromString:tran.itemID];
	coverart = [coverart stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", imdbNumber]];
	[[SapphireApplianceController urlLoader] saveDataAtURL:url toFile:coverart];	
}

- (void)completeWithState:(SapphireMovieImportStateData *)state withStatus:(ImportState)status importComplete:(BOOL)importComplete;
{
	SapphireFileMetaData *currentData = state->file;
	if(importComplete)
	{
		[currentData didImportType:ImportTypeMaskMovie];
		if (status == ImportStateNotUpdated && [currentData fileClassValue] != FileClassTVShow)
			[currentData setFileClassValue:FileClassUnknown];
	}
	[delegate backgroundImporter:self completedImportOnPath:state->path withState:status];
}

- (NSString *)movieURLFromNfoFilePath:(NSString *)filepath withID:(NSString * *)movieID
{
	NSString *nfoContent = [NSString stringWithContentsOfFile:filepath];
	
	if(![nfoContent length])
		return nil;
	
	NSString *results = [scraper searchResultsForNfoContent:nfoContent];
	if(![results length])
		return nil;
	
	NSString *fullResults = [NSString stringWithFormat:@"<results>%@</results>", results];
	NSError *error = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:fullResults options:0 error:&error] autorelease];
	if(!doc)
		return nil;
	
	NSXMLElement *root = [doc rootElement];
	NSString *urlStr = stringValueOfChild(root, @"url");
	*movieID = stringValueOfChild(root, @"id");
	return urlStr;
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
	if([metaData fileContainerType] == FileContainerTypeQTMovie)
		ret &= [[NSFileManager videoExtensions] containsObject:[path pathExtension]];
	if([metaData fileClassValue]==FileClassTVShow) /* File is a TV Show - skip it */
		ret = NO;
	return ret;
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	cancelled = NO;
	/*Check to see if it is already imported*/
	if([metaData importTypeValue] & ImportTypeMaskMovie)
		return ImportStateNotUpdated;
	/*Get path*/
	if(![self isMovieCandidate:metaData])
		return ImportStateNotUpdated;
	SapphireLog(SapphireLogTypeImport, SapphireLogLevelDebug, @"Going to movie import %@", path);
	NSString *extLessPath = path;
	if([metaData fileContainerTypeValue] != FileContainerTypeVideoTS)
		extLessPath = [extLessPath stringByDeletingPathExtension];
	
	/*choose between file or directory name for lookup */
	NSString *lookupName;
	if([[SapphireSettings sharedSettings] dirLookup])
		lookupName = [[[path stringByDeletingLastPathComponent] lastPathComponent] lowercaseString];
	else
		lookupName = [[extLessPath lastPathComponent] lowercaseString];
	
	SapphireSiteMovieScraper *siteScraper = [[[SapphireSiteMovieScraper alloc] initWithMovieScraper:scraper delegate:self loader:[SapphireApplianceController urlLoader]] autorelease];
	SapphireMovieImportStateData *state = [[[SapphireMovieImportStateData alloc] initWithFile:metaData atPath:path scraper:siteScraper] autorelease];
	[state setLookupName:lookupName];
	/*Check to see if we know this movie*/
	
	/*Look for a year in the title*/
	NSScanner *titleYearScanner = [NSScanner scannerWithString:state->lookupName];
	NSString *normalTitle = nil;
	int year = 0;
	BOOL success = YES;
	success &= [titleYearScanner scanUpToString:@"(" intoString:&normalTitle];
	success &= [titleYearScanner scanString:@"(" intoString:nil];
	success &= [titleYearScanner scanInt:&year];
	success &= [titleYearScanner scanString:@")" intoString:nil];
	
	NSString *yearStr = nil;
	if(success)
	{
		yearStr = [NSString stringWithFormat:@"%d", year];
		if([normalTitle hasSuffix:@" "])
		   normalTitle = [normalTitle substringToIndex:[normalTitle length]-1];
		[state setLookupName:normalTitle];
	}
	
	SapphireLog(SapphireLogTypeImport, SapphireLogLevelDetail, @"Searching for movie \"%@\"", state->lookupName);
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	SapphireMovieTranslation *tran = [SapphireMovieTranslation movieTranslationWithName:state->lookupName inContext:moc];
	if(tran == nil)
		//Check for translation with full title
		tran = [SapphireMovieTranslation movieTranslationWithName:[titleYearScanner string] inContext:moc];
	[state setTranslation:tran];
	int searchIMDBNumber = [metaData searchIMDBNumber];
	if(searchIMDBNumber > 0)
	{
		if(!tran)
			tran = [state createTranslationInContext:moc];
		tran.url = [NSString stringWithFormat:@"http://%@/title/tt%d/", [[[siteScraper scraper] settings] objectForKey:@"url"], searchIMDBNumber];
	}
	if(tran.url == nil)
	{
		BOOL nfoPathIsDir = NO;
		NSString *nfoFilePath=[extLessPath stringByAppendingPathExtension:@"nfo"];
		NSString *movieURL = nil;
		NSString *movieID = nil;
		if([[NSFileManager defaultManager] fileExistsAtPath:nfoFilePath isDirectory:&nfoPathIsDir] && !nfoPathIsDir)
			movieURL = [self movieURLFromNfoFilePath:nfoFilePath withID:&movieID];
		
		if([movieURL length])
		{
			if(tran == nil)
				tran = [state createTranslationInContext:moc];
			tran.url = movieURL;
			if([movieID length])
				[tran setItemID:movieID];
		}
		else
		{
			if(![delegate canDisplayChooser])
			/*There is no data menu, background import. So we can't ask user, skip*/
				return ImportStateNotUpdated;
			
			SapphireLog(SapphireLogTypeImport, SapphireLogLevelDebug, @"Searching for %@ with year %@", state->lookupName, yearStr);
			
			/*Ask the user what movie this is*/
			[siteScraper setObject:state];
			[siteScraper searchForMovieName:state->lookupName year:yearStr];
			return ImportStateBackground;
		}
	}
	
	SapphireMovie *movie = [tran movie];
	if(movie != nil)
	{	
		[metaData setMovie:movie];
		if([tran selectedPoster] != nil)
			return ImportStateUpdated;
		[self getMoviePostersForState:state thumbElements:[NSArray array]];
		return ImportStateBackground;
	}
	[self getMovieResultsForState:state];
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

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	SapphireMovieImportStateData *state = (SapphireMovieImportStateData *)context;
	if([chooser isKindOfClass:[SapphireMovieChooser class]])
	{
		NSManagedObjectContext *moc = [state->file managedObjectContext];
		SapphireMovieTranslation *tran = [SapphireMovieTranslation movieTranslationWithName:state->lookupName inContext:moc];
		if(tran)
			[state setTranslation:tran];
		if(tran.url)
		{
			[self getMovieResultsForState:state];
			return NO;
		}
	}
	else if([chooser isKindOfClass:[SapphirePosterChooser class]])
	{
		SapphireMovieTranslation *tran = state->translation;
		if([[tran selectedPoster] link])
		{
			[self saveMoviePosterAtURL:[[tran selectedPoster] link] forTranslation:tran];
			[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
			return NO;
		}
	}
	return YES;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	SapphireMovieImportStateData *state = (SapphireMovieImportStateData *)context;
	/*See if it was a movie chooser*/
	if([chooser isKindOfClass:[SapphireMovieChooser class]])
	{
		/*Get the user's selection*/
		SapphireMovieChooser *movieChooser = (SapphireMovieChooser *)chooser;
		SapphireFileMetaData *currentData = state->file;
		NSManagedObjectContext *moc = [currentData managedObjectContext];
		int selection = [movieChooser selection];
		if(selection == SapphireChooserChoiceCancel)
		{
			/*They aborted, skip*/
			[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		}
		else if(selection == SapphireChooserChoiceNotType)
		{
			/*They said it is not a movie, so put in empty data so they are not asked again*/
			[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:YES];
		}
		else
		{
			/*They selected a movie title, save the translation and write it*/
			NSDictionary *movie = [[movieChooser movies] objectAtIndex:selection];
			SapphireMovieTranslation *tran = [state createTranslationInContext:moc];
			tran.url = [movie objectForKey:movieTranslationLinkKey];
			tran.itemID = [movie objectForKey:movieTranslationIDKey];
			/*We can resume now*/
			[self getMovieResultsForState:state];
		}
		[SapphireMetaDataSupport save:moc];
	}
	else if([chooser isKindOfClass:[SapphirePosterChooser class]])
	{
		SapphirePosterChooser *posterChooser = (SapphirePosterChooser *)chooser;
		SapphireFileMetaData *currentData = state->file;
		NSManagedObjectContext *moc = [currentData managedObjectContext];
		SapphireChooserChoice selectedPoster = [posterChooser selection];
		if(selectedPoster == SapphireChooserChoiceCancel)
			/*They aborted, skip*/
			[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		else
		{
			SapphireMovieTranslation *tran = state->translation;
			[tran setSelectedPosterIndexValue:selectedPoster];
			[self saveMoviePosterAtURL:[[tran selectedPoster] link] forTranslation:tran];
			[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
		}
		[SapphireMetaDataSupport save:moc];
	}
	else
		return;
}

@end
