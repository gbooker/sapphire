// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireDirectoryMetaData.h instead.

#import <CoreData/CoreData.h>
#import "SapphireMetaData.h"


@class SapphireDirectoryMetaData;

@class SapphireDirectorySymLink;

@class SapphireFileMetaData;

@class SapphireFileSymLink;

@class SapphireDirectoryMetaData;

@class SapphireDirectorySymLink;

@class SapphireCollectionDirectory;


@interface _SapphireDirectoryMetaData : SapphireMetaData {}



- (SapphireDirectoryMetaData*)parent;
- (void)setParent:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;



- (void)addLinkedDirs:(NSSet*)value_;
- (void)removeLinkedDirs:(NSSet*)value_;
- (void)addLinkedDirsObject:(SapphireDirectorySymLink*)value_;
- (void)removeLinkedDirsObject:(SapphireDirectorySymLink*)value_;
- (NSMutableSet*)linkedDirsSet;



- (void)addMetaFiles:(NSSet*)value_;
- (void)removeMetaFiles:(NSSet*)value_;
- (void)addMetaFilesObject:(SapphireFileMetaData*)value_;
- (void)removeMetaFilesObject:(SapphireFileMetaData*)value_;
- (NSMutableSet*)metaFilesSet;



- (void)addLinkedFiles:(NSSet*)value_;
- (void)removeLinkedFiles:(NSSet*)value_;
- (void)addLinkedFilesObject:(SapphireFileSymLink*)value_;
- (void)removeLinkedFilesObject:(SapphireFileSymLink*)value_;
- (NSMutableSet*)linkedFilesSet;



- (void)addMetaDirs:(NSSet*)value_;
- (void)removeMetaDirs:(NSSet*)value_;
- (void)addMetaDirsObject:(SapphireDirectoryMetaData*)value_;
- (void)removeMetaDirsObject:(SapphireDirectoryMetaData*)value_;
- (NSMutableSet*)metaDirsSet;



- (void)addLinkedParents:(NSSet*)value_;
- (void)removeLinkedParents:(NSSet*)value_;
- (void)addLinkedParentsObject:(SapphireDirectorySymLink*)value_;
- (void)removeLinkedParentsObject:(SapphireDirectorySymLink*)value_;
- (NSMutableSet*)linkedParentsSet;



- (SapphireCollectionDirectory*)collectionDirectory;
- (void)setCollectionDirectory:(SapphireCollectionDirectory*)value_;
//- (BOOL)validateCollectionDirectory:(id*)value_ error:(NSError**)error_;


@end
