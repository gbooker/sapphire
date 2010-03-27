/*
 * SapphireMetaDataSupport.m
 * Sapphire
 *
 * Created by Graham Booker on Apr. 16, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireMetaDataSupport.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireFileMetaData.h"
#import "SapphireJoinedFile.h"
#import "SapphireCollectionDirectory.h"
#import "SapphireMovie.h"
#import "SapphireCast.h"
#import "SapphireMovieTranslation.h"
#import "SapphireMoviePoster.h"
#import "SapphireTVTranslation.h"
#import "SapphireTVShow.h"
#import "SapphireMetaDataUpgrading.h"
#import "SapphireDirector.h"
#import "SapphireGenre.h"
#import "SapphireDirectorySymLink.h"
#import "SapphireFileSymLink.h"
#import "SapphireEpisode.h"
#import "SapphireXMLData.h"
#import "SapphireApplianceController.h"
#import "SapphireSeason.h"
#import "CoreDataSupportFunctions.h"

@interface NSManagedObject (deleteDelegate)
- (BOOL)shouldDelete;
@end


@interface NSManagedObject (ChangePersistence)
- (NSDictionary *)changedValuesWithObjectIDs;
- (void)updateChanges:(NSDictionary *)changes withTrans:(NSDictionary *)translation;
@end

@implementation NSManagedObject (ChangePersistence)
- (NSDictionary *)changedValuesWithObjectIDs
{
	NSDictionary *changedValues = [self changedValues];
	NSMutableDictionary *ret = [[NSMutableDictionary alloc] initWithDictionary:changedValues];
	NSString *key;
	NSEnumerator *keyEnum = [changedValues keyEnumerator];
	while((key = [keyEnum nextObject]) != nil)
	{
		id value = [ret objectForKey:key];
		if([value isKindOfClass:[NSManagedObject class]])
			[ret setObject:[[(NSManagedObject *)value objectID] URIRepresentation] forKey:key];
		else if([value isKindOfClass:[NSSet class]] && [[(NSSet *)value anyObject] isKindOfClass:[NSManagedObject class]])
			[ret setObject:[value valueForKeyPath:@"objectID.URIRepresentation"] forKey:key];
	}
	return [ret autorelease];
}

- (void)updateChanges:(NSDictionary *)changes withTrans:(NSDictionary *)translation
{
	NSEnumerator *keyEnum = [changes keyEnumerator];
	NSString *key;
	while((key = [keyEnum nextObject]) != nil)
	{
		id newValue = [changes objectForKey:key];
		id testValue = newValue;
		BOOL isSet = NO;
		if([newValue isKindOfClass:[NSSet class]])
		{
			testValue = [newValue anyObject];
			isSet = YES;
		}
		NSManagedObjectContext *moc = [self managedObjectContext];
		if([testValue isKindOfClass:[NSURL class]] && [[(NSURL *)testValue scheme] hasPrefix:@"x-core"])
		{
			NSPersistentStoreCoordinator *coord = [moc persistentStoreCoordinator];
			NSManagedObject *newObj;
			if(isSet)
			{
				NSSet *objSet = (NSSet *)newValue;
				NSEnumerator *objEnum = [objSet objectEnumerator];
				NSMutableSet *newSet = [[NSMutableSet alloc] init];
				NSURL *url;
				while((url = [objEnum nextObject]) != nil)
				{
					newObj = [translation objectForKey:url];
					if(newObj == nil)
					{
						NSManagedObjectID *upObjId = [coord managedObjectIDForURIRepresentation:url];
						newObj = [moc objectWithID:upObjId];
					}
					[newSet addObject:newObj];
				}
				[self setValue:newSet forKey:key];
				[newSet release];
			}
			else
			{
				newObj = [translation objectForKey:newValue];
				if(newObj == nil)
				{
					NSManagedObjectID *upObjId = [coord managedObjectIDForURIRepresentation:newValue];
					newObj = [moc objectWithID:upObjId];
				}
				[self setValue:newObj forKey:key];
			}
		}
		else if(![newValue isKindOfClass:[NSNull class]])
			[self setValue:newValue forKey:key];
		else
			[self setValue:nil forKey:key];
	}
}

@end

#define META_VERSION_KEY			@"Version"

/* Movie Translations */
#define MOVIE_TRAN_VERSION_KEY					@"Version"
#define MOVIE_TRAN_CURRENT_VERSION				2
/* Translation Keys */
#define MOVIE_TRAN_TRANSLATIONS_KEY				@"Translations"
#define MOVIE_TRAN_IMDB_LINK_KEY				@"IMDB Link"
#define MOVIE_TRAN_IMP_LINK_KEY					@"IMP Link"
#define MOVIE_TRAN_IMP_POSTERS_KEY				@"IMP Posters"
#define MOVIE_TRAN_SELECTED_POSTER_KEY			@"Selected Poster"
#define MOVIE_TRAN_AUTO_SELECT_POSTER_KEY		@"Default Poster"

#define CHANGES_INSERTED_KEY					@"Inserted"
#define CHANGES_UPDATED_KEY						@"Updated"
#define CHANGES_DELETED_KEY						@"Deleted"

static NSSet *coverArtExtentions = nil;
static NSMutableSet *pendingDeleteObjects = nil;

NSString *searchCoverArtExtForPath(NSString *path)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *directory = [path stringByDeletingLastPathComponent];
	NSArray *files = [fm directoryContentsAtPath:directory];
	NSString *lastComp = [path lastPathComponent];
	/*Search all files*/
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		NSString *ext = [file pathExtension];
		if([ext length] && 
		   [coverArtExtentions containsObject:ext] && 
		   [lastComp caseInsensitiveCompare:[file stringByDeletingPathExtension]] == NSOrderedSame)
			return [directory stringByAppendingPathComponent:file];
	}
	/*Didn't find one*/
	return nil;
}

@implementation SapphireMetaDataSupport

+ (void)load
{
	coverArtExtentions = [[NSSet alloc] initWithObjects:
						  @"jpg",
						  @"jpeg",
						  @"tif",
						  @"tiff",
						  @"png",
						  @"gif",
						  nil];
	pendingDeleteObjects = [[NSMutableSet alloc] init];
}

+ (SapphireMetaDataSupport *)sharedInstance
{
	static SapphireMetaDataSupport *shared = nil;
	
	if(shared == nil)
		shared = [[SapphireMetaDataSupport alloc] init];
	
	return shared;
}

- (void) dealloc
{
	[mainMoc release];
	[writeTimer invalidate];
	writeTimer = nil;
	[super dealloc];
}

+ (void)pruneMetaData:(NSManagedObjectContext *)moc
{
	NSPredicate *movieFilePred = [NSPredicate predicateWithFormat:@"movie != nil"];
	NSArray *movieFiles = doFetchRequest(SapphireFileMetaDataName, moc, movieFilePred);
	NSSet *movieIds = [NSSet setWithArray:[movieFiles valueForKeyPath:@"movie.objectID"]];
	
	NSPredicate *movieNoFile = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", movieIds];
	NSArray *emptyMovies = doFetchRequest(SapphireMovieName, moc, movieNoFile);
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Pruning Movies %@", [emptyMovies valueForKeyPath:@"title"]);
	NSEnumerator *objEnum = [emptyMovies objectEnumerator];
	NSManagedObject *obj;
	while((obj = [objEnum nextObject]) != nil)
		[moc deleteObject:obj];
	
	NSArray *allMovies = doFetchRequest(SapphireMovieName, moc, nil);
	
	NSDictionary *pruneKeys = [NSDictionary dictionaryWithObjectsAndKeys:
							   SapphireCastName, @"cast",
							   SapphireGenreName, @"genres",
							   SapphireDirectorName, @"directors",
							   nil];
	NSEnumerator *keyEnum = [pruneKeys keyEnumerator];
	NSString *key;
	while((key = [keyEnum nextObject]) != nil)
	{
		NSString *objName = [pruneKeys objectForKey:key];
		NSArray *itemSet = [allMovies valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfSets.%@.objectID", key]];
		NSArray *emptyItems = doFetchRequest(objName, moc, [NSPredicate predicateWithFormat:@"NOT SELF IN %@", itemSet]);
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Pruning %@ %@", key, [emptyItems valueForKeyPath:@"name"]);
		objEnum = [emptyItems objectEnumerator];
		while((obj = [objEnum nextObject]) != nil)
			[moc deleteObject:obj];
	}
	
	NSPredicate *epFilePred = [NSPredicate predicateWithFormat:@"tvEpisode != nil"];
	NSArray *epFiles = doFetchRequest(SapphireFileMetaDataName, moc, epFilePred);
	NSSet *epIds = [NSSet setWithArray:[epFiles valueForKeyPath:@"tvEpisode.objectID"]];
	
	NSPredicate *epNoFile = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", epIds];
	NSArray *emptyEpisodes = doFetchRequest(SapphireEpisodeName, moc, epNoFile);
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Pruning Episodes %@", [emptyEpisodes valueForKeyPath:@"episodeTitle"]);
	objEnum = [emptyEpisodes objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
		[moc deleteObject:obj];
	
	NSArray *allEps = doFetchRequest(SapphireEpisodeName, moc, nil);
	
	NSSet *seasonIds = [allEps valueForKeyPath:@"@distinctUnionOfObjects.season.objectID"];
	NSPredicate *noEpisodes = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", seasonIds];
	NSArray *emptySeasons = doFetchRequest(SapphireSeasonName, moc, noEpisodes);
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Pruning Seasons %@", [emptySeasons valueForKeyPath:@"path"]);
	objEnum = [emptySeasons objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
		[moc deleteObject:obj];
	
	NSSet *showIds = [allEps valueForKeyPath:@"@distinctUnionOfObjects.tvShow.objectID"];
	noEpisodes = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", showIds];
	NSArray *emptyShows = doFetchRequest(SapphireTVShowName, moc, noEpisodes);
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Pruning Shows %@", [emptyShows valueForKeyPath:@"name"]);
	objEnum = [emptyShows objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
		[moc deleteObject:obj];
}

+ (void)setObjectForPendingDelete:(NSManagedObject *)objectToDelete
{
	[pendingDeleteObjects addObject:objectToDelete];
}

/*!
 * @brief Deletes pending objects
 *
 * Deletes all objects in the pending queue, but calls shouldDelete first to make sure it should
 * be deleted.  This is also used as a hack to work around CD apparent inability to make KVO
 * notifications during an object delete when it is within an KVO notification.
 */
+ (void)deletePendingObjects
{
	NSManagedObjectContext *mainMoc = [SapphireMetaDataSupport sharedInstance]->mainMoc;
	[mainMoc processPendingChanges];		
	while([pendingDeleteObjects count])
	{
		NSManagedObject *obj;
		NSSet *pendingObjects = [pendingDeleteObjects copy];
		[pendingDeleteObjects removeAllObjects];
		NSEnumerator *objEnum = [pendingObjects objectEnumerator];
		while((obj = [objEnum nextObject]) != nil)
		{
			if([obj isDeleted])
				continue;
			if([obj managedObjectContext] != mainMoc)
				continue;
			if(![obj respondsToSelector:@selector(shouldDelete)] || [obj shouldDelete])
				[mainMoc deleteObject:obj];
		}
		[pendingObjects release];
		[mainMoc processPendingChanges];
	}
}

- (void)realWriteMetaData:(NSTimer *)timer
{
	NSManagedObjectContext *context = nil;
	if([timer isKindOfClass:[NSManagedObjectContext class]])
		context = (NSManagedObjectContext *)timer;
	else
		context = [timer userInfo];
	
	if(writeTimer != nil)
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Rescheduled write");
	writeTimer = nil;
	NSError *error = nil;
	locked = NO;
	BOOL success = NO;
	@try {
		[SapphireMetaDataSupport deletePendingObjects];
		success = [context save:&error];
	}
	@catch (NSException * e) {
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Could not save due to exception \"%@\" with reason \"%@\"", [e name], [e reason]);
	}
	if(error != nil)
	{
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_ERROR, @"Save error \"%@\"", error);
		NSArray *details = [[error userInfo] objectForKey:@"NSDetailedErrors"];
		if(details != nil)
		{
			NSEnumerator *errorEnum = [details objectEnumerator];
			NSError *aError;
			while((aError = [errorEnum nextObject]) != nil)
				SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_ERROR, @"One error is %@: %@", aError, [aError userInfo]);
		}
		NSException *underlying = [[error userInfo] objectForKey:@"NSUnderlyingException"];
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Underlying is %@ %@ %@ %@", underlying, [underlying name], [underlying reason], [underlying userInfo]);
		if([[underlying reason] isEqualToString:@"database is locked"])
		{
			SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Detected locked");
			locked = YES;
		}
	}
	if(success == NO)
	{
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Inserted objects is %@", [context insertedObjects]);
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Updated objects is %@", [context updatedObjects]);
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Deleted objects is %@", [context deletedObjects]);
		interval *= 2;
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Rescheduling write to occurr in %f seconds", interval);
		
		@try {
			NSSet *objSet = [context updatedObjects];
			NSEnumerator *objEnum = [objSet objectEnumerator];
			NSManagedObject *obj;
			while((obj = [objEnum nextObject]) != nil)
				[context refreshObject:obj mergeChanges:YES];
			objSet = [context deletedObjects];
			objEnum = [objSet objectEnumerator];
			while((obj = [objEnum nextObject]) != nil)
				[context refreshObject:obj mergeChanges:YES];			
		}
		@catch (NSException * e) {
			SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Could not fix save due to exception \"%@\" with reason \"%@\"", [e name], [e reason]);
		}
		
		writeTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(realWriteMetaData:) userInfo:context repeats:NO];
	}
	else
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Save successful");
}

- (BOOL)save:(NSManagedObjectContext *)context;
{
	if(context != mainMoc)
	{
		return YES;
	}
	if(writeTimer == nil)
	{
		interval = 1;
		[self performSelectorOnMainThread:@selector(realWriteMetaData:) withObject:context waitUntilDone:YES];
		return (writeTimer == nil);
	}
	else
		return YES;
}

+ (BOOL)save:(NSManagedObjectContext *)context
{
	if(context == nil)
		return NO;
	
	return [[SapphireMetaDataSupport sharedInstance] save:context];
}

- (void)applyChanges:(NSDictionary *)changes
{
	[SapphireMetaDataSupport applyChanges:changes toContext:mainMoc];
}

- (void)applyChangesFromContext:(NSManagedObjectContext *)context
{
	if(mainMoc != nil)
	{
		NSDictionary *changes = [SapphireMetaDataSupport changesDictionaryForContext:context];
		[self performSelectorOnMainThread:@selector(applyChanges:) withObject:changes waitUntilDone:YES];
	}
}

+ (void)applyChangesFromContext:(NSManagedObjectContext *)context
{
	[[SapphireMetaDataSupport sharedInstance] applyChangesFromContext:context];
}

- (void)setMainContext:(NSManagedObjectContext *)moc
{
	[mainMoc release];
	mainMoc = [moc retain];
}

+ (void)setMainContext:(NSManagedObjectContext *)moc
{
	[[SapphireMetaDataSupport sharedInstance] setMainContext:moc];
}

- (BOOL)wasLocked
{
	return locked;
}

+ (BOOL)wasLocked
{
	return [[SapphireMetaDataSupport sharedInstance] wasLocked];
}

+ (void)importV1Store:(NSManagedObjectContext *)v1Context intoContext:(NSManagedObjectContext *)context withDisplay:(SapphireMetaDataUpgrading *)display
{
	[display setCurrentFile:@"Upgrading Cast"];
	NSDictionary *castLookup = [SapphireCast upgradeV1CastFromContext:v1Context toContext:context];
	[display setCurrentFile:@"Upgrading Directors"];
	NSDictionary *directorLookup = [SapphireDirector upgradeV1DirectorsFromContext:v1Context toContext:context];
	[display setCurrentFile:@"Upgrading Genres"];
	NSDictionary *genreLookup = [SapphireGenre upgradeV1GenresFromContext:v1Context toContext:context];
	[display setCurrentFile:@"Upgrading Movies"];
	NSDictionary *movieLookup = [SapphireMovie upgradeV1MoviesFromContext:v1Context toContext:context withCast:castLookup directors:directorLookup genres:genreLookup];
	[display setCurrentFile:@"Upgrading Shows"];
	[SapphireTVShow upgradeV1ShowsFromContext:v1Context toContext:context];
	[display setCurrentFile:@"Upgrading Directories"];
	NSDictionary *dirLookup = [SapphireDirectoryMetaData upgradeV1DirectoriesFromContext:v1Context toContext:context];
	[display setCurrentFile:@"Upgrading Files"];
	NSDictionary *fileLookup = [SapphireFileMetaData upgradeV1FilesFromContext:v1Context toContext:context withMovies:movieLookup directories:dirLookup];
	[display setCurrentFile:@"Upgrading SymLinks"];
	[SapphireDirectorySymLink upgradeV1DirLinksFromContext:v1Context toContext:context directories:dirLookup];
	[SapphireFileSymLink upgradeV1FileLinksFromContext:v1Context toContext:context directories:dirLookup file:fileLookup];
	[display setCurrentFile:@"Upgrading Joined Files"];
	[SapphireJoinedFile upgradeV1JoinedFileFromContext:v1Context toContext:context file:fileLookup];
	[display setCurrentFile:@"Upgrading Episodes"];
	[SapphireEpisode upgradeV1EpisodesFromContext:v1Context toContext:context file:fileLookup];
	[display setCurrentFile:@"Upgrading XML"];
	[SapphireXMLData upgradeV1XMLFromContext:v1Context toContext:context file:fileLookup];
}

+ (void)importPlist:(NSString *)configDir intoContext:(NSManagedObjectContext *)context withDisplay:(SapphireMetaDataUpgrading *)display
{
	NSString *currentImportPlist=[configDir stringByAppendingPathComponent:@"metaData.plist"];

	if([[NSFileManager defaultManager] fileExistsAtPath:currentImportPlist])//import metadata & related info
	{
		NSLog(@"Upgrading %@", currentImportPlist);
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:currentImportPlist];
		NSMutableDictionary *defer = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [NSMutableDictionary dictionary], @"Join",
									  [NSMutableDictionary dictionary], @"Cast",
									  [NSMutableDictionary dictionary], @"Directors",
									  nil];
		int version = [[dict objectForKey:META_VERSION_KEY] intValue];
		SapphireDirectoryMetaData *newDir = nil;
		if(version > 2)
		{
			NSDictionary *slash = [dict objectForKey:@"/"];
			newDir = [SapphireDirectoryMetaData createDirectoryWithPath:@"/" parent:nil inContext:context];
			[newDir insertDictionary:slash withDefer:defer andDisplay:display];
		}
		else
		{
			newDir = [SapphireDirectoryMetaData createDirectoryWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"] parent:nil inContext:context];
			[newDir insertDictionary:dict withDefer:defer andDisplay:display];
		}
		[display setCurrentFile:BRLocalizedString(@"Upgrading Joined Files", @"Upgrade progress indicator stating Sapphire is upgrading joined files")];
		NSDictionary *joinDict = [defer objectForKey:@"Join"];
		if(joinDict != nil)
		{
			NSEnumerator *joinEunm = [joinDict keyEnumerator];
			NSString *joinedPath;
			while((joinedPath = [joinEunm nextObject]) != nil)
			{
				SapphireJoinedFile *joinedFile = [SapphireJoinedFile joinedFileForPath:joinedPath inContext:context];
				NSArray *joinArray = [joinDict objectForKey:joinedPath];
				NSEnumerator *joinedEnum = [joinArray objectEnumerator];
				SapphireFileMetaData *joinFile;
				while((joinFile = [joinedEnum nextObject]) != nil)
					joinFile.joinedToFile = joinedFile;
			}			
		}
		
		[display setCurrentFile:BRLocalizedString(@"Upgrading Collection Prefs", @"Upgrade progress indicator stating Sapphire is upgrading collections preferences")];
		NSDictionary *options = [dict objectForKey:@"Options"];
		NSMutableSet *collections = [NSMutableSet set];
		NSArray *custom = [options objectForKey:@"Directories"];
		if([custom count])
			[collections unionSet:[NSSet setWithArray:custom]];
		NSDictionary *hidden = [options objectForKey:@"Hide"];
		NSArray *keyArray = [hidden allKeys];
		if([keyArray count])
			[collections unionSet:[NSSet setWithArray:keyArray]];
		NSDictionary *skipped = [options objectForKey:@"Skip"];
		keyArray = [skipped allKeys];
		if([keyArray count])
			[collections unionSet:[NSSet setWithArray:keyArray]];
		
		NSEnumerator *collectionEnum = [collections objectEnumerator];
		NSString *collectionPath;
		while((collectionPath = [collectionEnum nextObject]) != nil)
		{
			[SapphireCollectionDirectory collectionAtPath:collectionPath
													mount:NO
													 skip:[[skipped objectForKey:collectionPath] boolValue]
												   hidden:[[hidden objectForKey:collectionPath] boolValue]
												   manual:[custom containsObject:collectionPath]
												inContext:context];
		}
		//Set the mount values for all
		[SapphireCollectionDirectory availableCollectionDirectoriesInContext:context includeHiddenOverSkipped:NO];
	}
	
	currentImportPlist=[configDir stringByAppendingPathComponent:@"movieData.plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:currentImportPlist])//import movie translations
	{
		NSLog(@"Upgrading %@", currentImportPlist);
		[display setCurrentFile:BRLocalizedString(@"Upgrading Movie Translations", @"Upgrade progress indicator stating Sapphire is upgrading movie translations")];
		NSDictionary *movieTranslations = [NSDictionary dictionaryWithContentsOfFile:currentImportPlist];
		NSDictionary *translations = [movieTranslations objectForKey:MOVIE_TRAN_TRANSLATIONS_KEY];
		NSEnumerator *movieEnum = [translations keyEnumerator];
		NSString *movie = nil;
		while((movie = [movieEnum nextObject]) != nil)
		{
			NSDictionary *movieDict = [translations objectForKey:movie];
			SapphireMovieTranslation *trans = [SapphireMovieTranslation createMovieTranslationWithName:movie inContext:context];
			trans.IMPLink = [movieDict objectForKey:MOVIE_TRAN_IMP_LINK_KEY];
			NSString *IMDBLink = [movieDict objectForKey:MOVIE_TRAN_IMDB_LINK_KEY];
			trans.IMDBLink = IMDBLink;
			
			int imdbNumber = [SapphireMovie imdbNumberFromString:IMDBLink];
			if(imdbNumber != 0)
			{
				SapphireMovie *thisMovie = [SapphireMovie movieWithIMDB:imdbNumber inContext:context];
				trans.movie = thisMovie;
			}
			
			NSArray *posters = [movieDict objectForKey:MOVIE_TRAN_IMP_POSTERS_KEY];
			NSSet *dupCheck = [NSSet setWithArray:posters];
			posters = [dupCheck allObjects];
			
			NSString *selectedPoster = [movieDict objectForKey:MOVIE_TRAN_SELECTED_POSTER_KEY];
			int i, count = [posters count];
			for(i=0; i<count; i++)
			{
				NSString *posterUrl = [posters objectAtIndex:i];
				if([posterUrl isEqualToString:selectedPoster])
					trans.selectedPosterIndexValue = i;
				
				[SapphireMoviePoster createPosterWithLink:posterUrl index:i translation:trans inContext:context];
			}
		}
	}
	
	currentImportPlist=[configDir stringByAppendingPathComponent:@"tvdata.plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:currentImportPlist])//import tvshow translations
	{
		NSLog(@"Upgrading %@", currentImportPlist);
		[display setCurrentFile:BRLocalizedString(@"Upgrading TV Translations", @"Upgrade progress indicator stating Sapphire is upgrading TV Translations")];
		NSDictionary *tvTranslations = [NSDictionary dictionaryWithContentsOfFile:currentImportPlist];
		NSDictionary *translations = [tvTranslations objectForKey:@"Translations"];
		NSEnumerator *tvEnum = [translations keyEnumerator];
		NSString *tvShow = nil;
		while((tvShow = [tvEnum nextObject]) != nil)
		{
			NSString *showPath = [translations objectForKey:tvShow];
			SapphireTVTranslation *trans = [SapphireTVTranslation createTVTranslationForName:tvShow withPath:showPath inContext:context];
			SapphireTVShow *show = [SapphireTVShow showWithPath:showPath inContext:context];
			trans.tvShow = show;
		}
	}
	NSError *error = nil;
	NSManagedObject *obj;
	NSEnumerator *objEnum = [[context registeredObjects] objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
	{
		if(![obj validateForUpdate:&error])
			SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_INFO, @"%@", error);
	}
}

+ (NSString *)collectionArtPath
{
	static NSString *path = nil;
	if(path == nil)
		path = [[applicationSupportDir() stringByAppendingPathComponent:@"Collection Art"] retain];
	return path;
}

+ (NSDictionary *)changesDictionaryForContext:(NSManagedObjectContext *)moc
{
	NSSet *insertedObjects = [moc insertedObjects];
	NSSet *deletedObjects = [moc deletedObjects];
	NSMutableSet *updatedObjects = [[moc updatedObjects] mutableCopy];
	[updatedObjects minusSet:insertedObjects];
	[updatedObjects autorelease];
	
	NSManagedObject *obj;
	NSEnumerator *objEnum = [insertedObjects objectEnumerator];
	NSMutableDictionary *inserted = [NSMutableDictionary dictionary];
	while((obj = [objEnum nextObject]) != nil)
	{
		[inserted setObject:[obj changedValuesWithObjectIDs] forKey:[[obj objectID] URIRepresentation]];
	}
	objEnum = [updatedObjects objectEnumerator];
	NSMutableDictionary *updated = [NSMutableDictionary dictionary];
	while((obj = [objEnum nextObject]) != nil)
	{
		NSDictionary *changes = [obj changedValuesWithObjectIDs];
		if([changes count])
			[updated setObject:changes forKey:[[obj objectID] URIRepresentation]];
	}
	NSArray *deleted = [deletedObjects valueForKeyPath:@"objectID.URIRepresentation"];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			inserted, CHANGES_INSERTED_KEY,
			updated, CHANGES_UPDATED_KEY,
			deleted, CHANGES_DELETED_KEY,
			nil];
}

+ (void)applyChanges:(NSDictionary *)changes toContext:(NSManagedObjectContext *)moc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUndoManager *undo = [[NSUndoManager alloc] init];
	[moc setUndoManager:undo];
	[undo beginUndoGrouping];
	BOOL failed = NO;
	@try {
		NSDictionary *inserted = [changes objectForKey:CHANGES_INSERTED_KEY];
		NSDictionary *updated = [changes objectForKey:CHANGES_UPDATED_KEY];
		NSArray *deleted = [changes objectForKey:CHANGES_DELETED_KEY];
		NSMutableDictionary *objIDTranslation = [NSMutableDictionary dictionary];
		NSURL *key;
		NSEnumerator *keyEnum = [inserted keyEnumerator];
		while((key = [keyEnum nextObject]) != nil && !failed)
		{
			NSManagedObjectID *objId = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:key];
			NSEntityDescription *desc = [objId entity];
			NSManagedObject *newObj = [NSEntityDescription insertNewObjectForEntityForName:[desc name] inManagedObjectContext:moc];
			if(newObj == nil)
				failed = YES;
			else
				[objIDTranslation setObject:newObj forKey:key];
		}
		keyEnum = [inserted keyEnumerator];
		while((key = [keyEnum nextObject]) != nil && !failed)
		{
			NSManagedObject *obj = [objIDTranslation objectForKey:key];
			if(obj == nil)
				failed = YES;
			else
				[obj updateChanges:[inserted objectForKey:key] withTrans:objIDTranslation];
		}
		keyEnum = [updated keyEnumerator];
		while((key = [keyEnum nextObject]) != nil && !failed)
		{
			NSManagedObjectID *objId = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:key];
			if(objId == nil)
				failed = YES;
			else
			{
				NSManagedObject *obj = [moc objectWithID:objId];
				if(obj == nil)
					failed = YES;
				else
					[obj updateChanges:[updated objectForKey:key] withTrans:objIDTranslation];
			}
		}
		keyEnum = [deleted objectEnumerator];
		while((key = [keyEnum nextObject]) != nil && !failed)
		{
			NSManagedObjectID *objId = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:key];
			if(objId == nil)
				failed = YES;
			else
			{
				NSManagedObject *obj = [moc objectWithID:objId];
				if(obj == nil)
					failed = YES;
				else
					[moc deleteObject:obj];
			}
		}		
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
		failed = YES;
	}
	[undo endUndoGrouping];
	if(failed)
	{
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_ERROR, @"Apply failed for %@, undoing", changes);
		[undo undo];
	}
	[moc setUndoManager:nil];
	[undo release];
	[pool drain];
}

@end