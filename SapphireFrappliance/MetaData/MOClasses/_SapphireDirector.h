// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireDirector.h instead.

#import <CoreData/CoreData.h>
#import "SapphireCategoryDirectory.h"


@class SapphireMovie;


@interface _SapphireDirector : SapphireCategoryDirectory {}


- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




- (void)addMovies:(NSSet*)value_;
- (void)removeMovies:(NSSet*)value_;
- (void)addMoviesObject:(SapphireMovie*)value_;
- (void)removeMoviesObject:(SapphireMovie*)value_;
- (NSMutableSet*)moviesSet;


@end
