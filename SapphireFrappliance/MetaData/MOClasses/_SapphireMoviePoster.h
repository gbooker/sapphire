// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMoviePoster.h instead.

#import <CoreData/CoreData.h>



@class SapphireMovieTranslation;


@interface _SapphireMoviePoster : NSManagedObject {}


- (NSString*)link;
- (void)setLink:(NSString*)value_;

//- (BOOL)validateLink:(id*)value_ error:(NSError**)error_;



- (NSNumber*)index;
- (void)setIndex:(NSNumber*)value_;

- (short)indexValue;
- (void)setIndexValue:(short)value_;

//- (BOOL)validateIndex:(id*)value_ error:(NSError**)error_;




- (SapphireMovieTranslation*)movieTranslation;
- (void)setMovieTranslation:(SapphireMovieTranslation*)value_;
//- (BOOL)validateMovieTranslation:(id*)value_ error:(NSError**)error_;


@end
