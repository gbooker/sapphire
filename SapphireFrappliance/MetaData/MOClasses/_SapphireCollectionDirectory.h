// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireCollectionDirectory.h instead.

#import <CoreData/CoreData.h>



@class SapphireDirectoryMetaData;


@interface _SapphireCollectionDirectory : NSManagedObject {}


- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





- (NSNumber*)isMount;
- (void)setIsMount:(NSNumber*)value_;

- (BOOL)isMountValue;
- (void)setIsMountValue:(BOOL)value_;

//- (BOOL)validateIsMount:(id*)value_ error:(NSError**)error_;



- (NSNumber*)hidden;
- (void)setHidden:(NSNumber*)value_;

- (BOOL)hiddenValue;
- (void)setHiddenValue:(BOOL)value_;

//- (BOOL)validateHidden:(id*)value_ error:(NSError**)error_;



- (NSNumber*)skip;
- (void)setSkip:(NSNumber*)value_;

- (BOOL)skipValue;
- (void)setSkipValue:(BOOL)value_;

//- (BOOL)validateSkip:(id*)value_ error:(NSError**)error_;



- (NSNumber*)manualCollection;
- (void)setManualCollection:(NSNumber*)value_;

- (BOOL)manualCollectionValue;
- (void)setManualCollectionValue:(BOOL)value_;

//- (BOOL)validateManualCollection:(id*)value_ error:(NSError**)error_;



- (NSData*)mountInformationData;
- (void)setMountInformationData:(NSData*)value_;

//- (BOOL)validateMountInformationData:(id*)value_ error:(NSError**)error_;




- (SapphireDirectoryMetaData*)directory;
- (void)setDirectory:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateDirectory:(id*)value_ error:(NSError**)error_;


@end
