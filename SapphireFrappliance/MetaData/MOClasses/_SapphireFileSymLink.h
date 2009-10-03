// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireFileSymLink.h instead.

#import <CoreData/CoreData.h>
#import "SapphireSymLink.h"


@class SapphireFileMetaData;

@class SapphireDirectoryMetaData;


@interface _SapphireFileSymLink : SapphireSymLink {}



- (SapphireFileMetaData*)file;
- (void)setFile:(SapphireFileMetaData*)value_;
//- (BOOL)validateFile:(id*)value_ error:(NSError**)error_;



- (SapphireDirectoryMetaData*)containingDirectory;
- (void)setContainingDirectory:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateContainingDirectory:(id*)value_ error:(NSError**)error_;


@end
