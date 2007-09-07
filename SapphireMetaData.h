//
//  SapphireMetaData.h
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
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
#define META_DESCRIPTION_KEY			@"Show Description"
#define META_SHOW_AIR_DATE				@"Air Date"
#define META_RATING_KEY					@"Rating"
#define META_SUMMARY_KEY				@"Summary"
#define META_ABSOLUTE_EP_NUMBER_KEY		@"Episode Number"
#define META_SHOW_IDENTIFIER_KEY		@"Show ID"

//ATV Extra Info
#define META_SHOW_BROADCASTER_KEY		@"Broadcast Company"
#define META_SHOW_PUBLISHED_DATE_KEY	@"Published Date"
#define META_SHOW_AQUIRED_DATE			@"Date Aquired"
#define META_SHOW_RATING_KEY			@"Rating"
#define META_SHOW_FAVORITE_RATING_KEY	@"User Rating"
#define META_COPYRIGHT_KEY				@"Copyright"

//IMDB Type Info

//Special Display Only Info
#define META_EPISODE_AND_SEASON_KEY		@"S/E"

#define META_DATA_FILE_ADDED_NOTIFICATION				@"MetaDataFileAdded"
#define META_DATA_FILE_REMOVED_NOTIFICATION				@"MetaDataFileRemoved"
#define META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION	@"MetaDataFileInfoWillChange"
#define META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION	@"MetaDataFileInfoHasChanged"
#define META_DATA_FILE_INFO_KIND						@"MetaDataFileInfoKind"

typedef enum {
	FILE_CLASS_UNKNOWN = 0,
	FILE_CLASS_TV_SHOW = 1,
	FILE_CLASS_MOVIE = 2,
} FileClass;

@class SapphireMetaData, SapphireMetaDataCollection, SapphireFileMetaData, SapphireDirectoryMetaData;

@protocol SapphireMetaDataDelegate <NSObject>
- (void)updateCompleteForFile:(NSString *)file;
@end

@protocol SapphireMetaDataScannerDelegate <NSObject>
- (void)gotSubFiles:(NSArray *)subs;
- (void)scanningDir:(NSString *)dir;
- (BOOL)getSubFilesCanceled;
@end

@interface SapphireMetaData : NSObject {
	NSMutableDictionary				*metaData;
	SapphireMetaData				*parent;
	/* These two are not retained */
	NSString						*path;
	id <SapphireMetaDataDelegate>	delegate;
}

+ (NSSet *)videoExtensions;
+ (NSSet *)audioExtensions;
- (NSString *)path;

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;
- (void)writeMetaData;
- (SapphireMetaDataCollection *)collection;
- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;

@end

@interface SapphireMetaDataCollection : SapphireMetaData {
	NSMutableDictionary			*directories;
	NSMutableDictionary			*skipCollection;
	NSMutableDictionary			*hideCollection;
	NSString					*dictionaryPath;
	BOOL						importing;
}
- (id)initWithFile:(NSString *)dictionary;
- (SapphireDirectoryMetaData *)directoryForPath:(NSString *)path;
- (NSArray *)collectionDirectories;
- (void)setImporting:(BOOL)isImporting;
- (BOOL)hideCollection:(NSString *)collection;
- (void)setHide:(BOOL)hide forCollection:(NSString *)collection;
- (BOOL)skipCollection:(NSString *)collection;
- (void)setSkip:(BOOL)skip forCollection:(NSString *)collection;

@end

@interface SapphireDirectoryMetaData : SapphireMetaData {
	/*These two are not retained*/
	NSMutableDictionary			*metaFiles;
	NSMutableDictionary			*metaDirs;
	
	NSMutableDictionary			*cachedMetaFiles;
	NSMutableDictionary			*cachedMetaDirs;

	NSMutableArray				*files;
	NSMutableArray				*directories;
	
	NSTimer						*importTimer;
	NSMutableArray				*importArray;
	BOOL						scannedDirectory;
	
	/*This is not retained*/
	SapphireMetaDataCollection	*collection;
}

- (void)reloadDirectoryContents;
- (NSArray *)files;
- (NSArray *)directories;
- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate;
- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate;

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)dir;

- (BOOL)pruneMetaData;
- (BOOL)updateMetaData;

- (void)cancelImport;
- (void)resumeImport;
- (void)resumeDelayedImport;

- (SapphireMetaData *)metaDataForSubPath:(NSString *)path;
- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;
- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;
- (void)loadMetaData;

- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate;
- (void)setWatched:(BOOL)watched forPredicate:(SapphirePredicate *)predicate;
- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate;
- (void)setFavorite:(BOOL)favorite forPredicate:(SapphirePredicate *)predicate;
- (void)setToImportFromSource:(NSString *)source forPredicate:(SapphirePredicate *)predicate;
- (void)setFileClass:(FileClass)fileClass forPredicate:(SapphirePredicate *)predicate;

@end

@interface SapphireFileMetaData : SapphireMetaData {
	NSDictionary		*combinedInfo;
}

- (BOOL) updateMetaData;

- (int)modified;
- (BOOL)watched;
- (void)setWatched:(BOOL)watched;
- (BOOL)favorite;
- (void)setFavorite:(BOOL)favorite;
- (long)importedTimeFromSource:(NSString *)source;
- (void)setToImportFromSource:(NSString *)source;
- (void)importInfo:(NSMutableDictionary *)newMeta fromSource:(NSString *)source withTime:(long)modTime;
- (unsigned int)resumeTime;
- (void)setResumeTime:(unsigned int)resumeTime;
- (FileClass)fileClass;
- (void)setFileClass:(FileClass)fileClass;

- (long long)size;
- (float)duration;
- (Float64)sampleRate;
- (UInt32)audioFormatID;
- (BOOL)hasVideo;
- (int)episodeNumber;
- (int)seasonNumber;
- (NSString *)episodeTitle;
- (NSString *)showID;
- (NSString *)showName;
- (NSString *)sizeString;

@end