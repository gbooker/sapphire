// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMovieTranslation.h instead.

#import <CoreData/CoreData.h>



@class SapphireMovie;

@class SapphireMoviePoster;


@interface _SapphireMovieTranslation : NSManagedObject {}


- (NSString*)IMPLink;
- (void)setIMPLink:(NSString*)value_;

//- (BOOL)validateIMPLink:(id*)value_ error:(NSError**)error_;



- (NSNumber*)selectedPosterIndex;
- (void)setSelectedPosterIndex:(NSNumber*)value_;

- (short)selectedPosterIndexValue;
- (void)setSelectedPosterIndexValue:(short)value_;

//- (BOOL)validateSelectedPosterIndex:(id*)value_ error:(NSError**)error_;



- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (NSString*)IMDBLink;
- (void)setIMDBLink:(NSString*)value_;

//- (BOOL)validateIMDBLink:(id*)value_ error:(NSError**)error_;




- (SapphireMovie*)movie;
- (void)setMovie:(SapphireMovie*)value_;
//- (BOOL)validateMovie:(id*)value_ error:(NSError**)error_;



- (void)addPosters:(NSSet*)value_;
- (void)removePosters:(NSSet*)value_;
- (void)addPostersObject:(SapphireMoviePoster*)value_;
- (void)removePostersObject:(SapphireMoviePoster*)value_;
- (NSMutableSet*)postersSet;


@end
