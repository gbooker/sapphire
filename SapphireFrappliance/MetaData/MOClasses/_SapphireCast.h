// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireCast.h instead.

#import <CoreData/CoreData.h>
#import "SapphireCategoryDirectory.h"


@class SapphireMovie;


@interface _SapphireCast : SapphireCategoryDirectory {}


- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (NSNumber*)hasMajorRole;
- (void)setHasMajorRole:(NSNumber*)value_;

- (BOOL)hasMajorRoleValue;
- (void)setHasMajorRoleValue:(BOOL)value_;

//- (BOOL)validateHasMajorRole:(id*)value_ error:(NSError**)error_;




- (void)addMovies:(NSSet*)value_;
- (void)removeMovies:(NSSet*)value_;
- (void)addMoviesObject:(SapphireMovie*)value_;
- (void)removeMoviesObject:(SapphireMovie*)value_;
- (NSMutableSet*)moviesSet;


@end
