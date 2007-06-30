//
//  SapphireMetaData.h
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SapphirePredicates.h"

#define META_TITLE_KEY @"Title"
#define META_RATING_KEY @"Rating"
#define META_SUMMARY_KEY @"Summary"
#define META_COPYRIGHT_KEY @"Copyright"

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
- (NSDictionary *)getAllMetaData;

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

@end

@interface SapphireFileMetaData : SapphireMetaData {
}

- (BOOL) updateMetaData;

- (int)modified;
- (BOOL)watched;
- (void)setWatched:(BOOL)watched;
- (BOOL)favorite;
- (void)setFavorite:(BOOL)favorite;
- (unsigned int)resumeTime;
- (void)setResumeTime:(unsigned int)resumeTime;

- (long long)size;
- (float)duration;
- (int)sampleRate;

- (NSString *)sizeString;

@end