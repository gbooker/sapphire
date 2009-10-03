// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireJoinedFile.h instead.

#import <CoreData/CoreData.h>



@class SapphireFileMetaData;

@class SapphireFileMetaData;


@interface _SapphireJoinedFile : NSManagedObject {}



- (SapphireFileMetaData*)file;
- (void)setFile:(SapphireFileMetaData*)value_;
//- (BOOL)validateFile:(id*)value_ error:(NSError**)error_;



- (void)addJoinedFiles:(NSSet*)value_;
- (void)removeJoinedFiles:(NSSet*)value_;
- (void)addJoinedFilesObject:(SapphireFileMetaData*)value_;
- (void)removeJoinedFilesObject:(SapphireFileMetaData*)value_;
- (NSMutableSet*)joinedFilesSet;


@end
