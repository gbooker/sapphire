//
//  SapphireMetaData.h
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SapphirePredicates.h"

#define META_TVRAGE_IMPORT_KEY			@"TVRage Source"
#define META_XML_IMPORT_KEY				@"XML Source"

//TV Show Specific Keys
#define META_TITLE_KEY					@"Title"
#define META_SEASON_NUMBER_KEY			@"Season"
#define META_EPISODE_NUMBER_KEY			@"Episode"
#define META_SHOW_NAME_KEY				@"Show Name"
#define META_SHOW_DESCRIPTION_KEY		@"Show Description"
#define META_SHOW_AIR_DATE				@"Air Date"
#define META_RATING_KEY					@"Rating"
#define META_DESCRIPTION_KEY			@"Description"

//ATV Extra Info
#define META_SHOW_BROADCASTER_KEY		@"Broadcast Company"
#define META_SHOW_PUBLISHED_DATE_KEY	@"Published Date"
#define META_SHOW_AQUIRED_DATE			@"Date Aquired"
#define META_SHOW_RATING_KEY			@"Rating"
#define META_SHOW_FAVORITE_RATING_KEY	@"User Rating"
#define META_COPYRIGHT_KEY				@"Copyright"

//IMDB Type Info

@class SapphireMetaData, SapphireFileMetaData, SapphireDirectoryMetaData;

@protocol SapphireMetaDataDelegate <NSObject>
- (void)updateCompleteForFile:(NSString *)file;
@end

@interface SapphireMetaData : NSObject {
	NSMutableDictionary				*metaData;
	SapphireMetaData				*parent;
	/* These two are not retained */
	NSString						*path;
	id <SapphireMetaDataDelegate>	delegate;
}

- (NSString *)path;

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;
- (void)writeMetaData;
- (NSMutableDictionary *)getDisplayedMetaData;

@end

@interface SapphireMetaDataCollection : SapphireMetaData {
	SapphireDirectoryMetaData	*mainDirectory;
	NSString					*dictionaryPath;
}
- (id)initWithFile:(NSString *)dictionary path:(NSString *)myPath;
- (SapphireDirectoryMetaData *)rootDirectory;

@end

@interface SapphireDirectoryMetaData : SapphireMetaData {
	/*These two are not retained*/
	NSMutableDictionary	*metaFiles;
	NSMutableDictionary	*metaDirs;
	
	NSMutableDictionary	*cachedMetaFiles;
	NSMutableDictionary	*cachedMetaDirs;

	NSMutableArray		*files;
	NSMutableArray		*directories;
	
	NSTimer				*importTimer;
	NSMutableArray		*importArray;
	BOOL				scannedDirectory;
}

- (void)reloadDirectoryContents;
- (NSArray *)files;
- (NSArray *)directories;
- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate;
- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate;

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)file;

- (BOOL)pruneMetaData;
- (BOOL)updateMetaData;

- (void)cancelImport;
- (void)resumeImport;
- (void)resumeDelayedImport;

- (SapphireMetaData *)metaDataForSubPath:(NSString *)path;
- (NSArray *)subFileMetas;
- (void)scanForNewFiles;

- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate;
- (void)setWatched:(BOOL)watched predicate:(SapphirePredicate *)predicate;
- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate;
- (void)setFavorite:(BOOL)favorite predicate:(SapphirePredicate *)predicate;
- (void)setToImportFromTVForPredicate:(SapphirePredicate *)predicate;

@end

@interface SapphireFileMetaData : SapphireMetaData {
}

- (BOOL) updateMetaData;

- (int)modified;
- (BOOL)watched;
- (void)setWatched:(BOOL)watched;
- (BOOL)favorite;
- (void)setFavorite:(BOOL)favorite;
- (BOOL)importedFromSource:(NSString *)source;
- (void)setToImportFromSource:(NSString *)source;
- (void)importInfo:(NSDictionary *)newMeta fromSource:(NSString *)source;
- (unsigned int)resumeTime;
- (void)setResumeTime:(unsigned int)resumeTime;

- (long long)size;
- (float)duration;
- (int)sampleRate;
- (int)episodeNumber ;
- (NSString *)episodeTitle ;

- (NSString *)sizeString;

@end