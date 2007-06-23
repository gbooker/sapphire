//
//  SapphireMetaData.h
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SapphirePredicates.h"

@class SapphireMetaData, SapphireFileMetaData, SapphireDirectoryMetaData;

@protocol SapphireMetaDataDelegate <NSObject>
- (void)updateComplete;
@end

@interface SapphireMetaData : NSObject {
	NSMutableDictionary				*metaData;
	SapphireMetaData				*parent;
	NSString						*path;
	id <SapphireMetaDataDelegate>	delegate;
}

- (NSString *)path;

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;
- (void)writeMetaData;
- (void)cancelImport;
- (void)resumeImport;

@end

@interface SapphireMetaDataCollection : SapphireMetaData {
	SapphireDirectoryMetaData	*mainDirectory;
	NSString					*dictionaryPath;
}
- (id)initWithFile:(NSString *)dictionary path:(NSString *)myPath;
- (SapphireDirectoryMetaData *)rootDirectory;

@end

@interface SapphireDirectoryMetaData : SapphireMetaData {
	NSMutableDictionary	*metaFiles;
	NSMutableDictionary	*metaDirs;
	NSMutableDictionary	*cachedMetaFiles;
	NSMutableDictionary	*cachedMetaDirs;

	NSMutableArray		*files;
	NSMutableArray		*directories;
	
	NSTimer				*importTimer;
	NSMutableArray		*importArray;
}

- (void)reloadDirectoryContents;
- (NSArray *)files;
- (NSArray *)directories;
- (NSArray *)predicatedFiles:(metaDataPredicate)predicate;
- (NSArray *)predicatedDirectories:(metaDataPredicate)predicate;

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)file;

- (BOOL)pruneMetaData;
- (BOOL)updateMetaData;

- (SapphireMetaData *)metaDataForSubPath:(NSString *)path;
- (void)scanDirectory;
@end

@interface SapphireFileMetaData : SapphireMetaData {
}

- (int)modified;
- (BOOL)watched;
- (void)setWatched;
- (long long)size;
- (float)duration;
- (int)sampleRate;

@end