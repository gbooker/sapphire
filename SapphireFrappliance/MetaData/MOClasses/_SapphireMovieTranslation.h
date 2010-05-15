// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMovieTranslation.h instead.

#import <CoreData/CoreData.h>
#import "SapphireTranslation.h"


@class SapphireMoviePoster;

@class SapphireMovie;


@interface _SapphireMovieTranslation : SapphireTranslation {}


- (NSNumber*)selectedPosterIndex;
- (void)setSelectedPosterIndex:(NSNumber*)value_;

- (short)selectedPosterIndexValue;
- (void)setSelectedPosterIndexValue:(short)value_;

//- (BOOL)validateSelectedPosterIndex:(id*)value_ error:(NSError**)error_;




- (void)addPosters:(NSSet*)value_;
- (void)removePosters:(NSSet*)value_;
- (void)addPostersObject:(SapphireMoviePoster*)value_;
- (void)removePostersObject:(SapphireMoviePoster*)value_;
- (NSMutableSet*)postersSet;



- (SapphireMovie*)movie;
- (void)setMovie:(SapphireMovie*)value_;
//- (BOOL)validateMovie:(id*)value_ error:(NSError**)error_;


@end
