// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireDirectorySymLink.h instead.

#import <CoreData/CoreData.h>



@class SapphireDirectoryMetaData;

@class SapphireDirectoryMetaData;


@interface _SapphireDirectorySymLink : NSManagedObject {}


- (NSString*)path;
- (void)setPath:(NSString*)value_;

//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;





- (NSData*)otherPropertiesData;
- (void)setOtherPropertiesData:(NSData*)value_;

//- (BOOL)validateOtherPropertiesData:(id*)value_ error:(NSError**)error_;




- (SapphireDirectoryMetaData*)containingDirectory;
- (void)setContainingDirectory:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateContainingDirectory:(id*)value_ error:(NSError**)error_;



- (SapphireDirectoryMetaData*)directory;
- (void)setDirectory:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateDirectory:(id*)value_ error:(NSError**)error_;


@end
