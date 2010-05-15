// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireFileSymLink.h instead.

#import <CoreData/CoreData.h>



@class SapphireFileMetaData;

@class SapphireDirectoryMetaData;


@interface _SapphireFileSymLink : NSManagedObject {}


- (NSString*)path;
- (void)setPath:(NSString*)value_;

//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;





- (NSData*)otherPropertiesData;
- (void)setOtherPropertiesData:(NSData*)value_;

//- (BOOL)validateOtherPropertiesData:(id*)value_ error:(NSError**)error_;




- (SapphireFileMetaData*)file;
- (void)setFile:(SapphireFileMetaData*)value_;
//- (BOOL)validateFile:(id*)value_ error:(NSError**)error_;



- (SapphireDirectoryMetaData*)containingDirectory;
- (void)setContainingDirectory:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateContainingDirectory:(id*)value_ error:(NSError**)error_;


@end
