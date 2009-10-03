#import "_SapphireMovieTranslation.h"

#define SapphireMovieTranslationName @"MovieTranslation"

@class SapphireMoviePoster;

@interface SapphireMovieTranslation : _SapphireMovieTranslation {}
+ (SapphireMovieTranslation *)movieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovieTranslation *)createMovieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovieTranslation *)upgradeV1MovieTranslation:(NSManagedObject *)oldTran toMovie:(SapphireMovie *)movie;

- (NSArray *)orderedPosters;
- (SapphireMoviePoster *)selectedPoster;
- (SapphireMoviePoster *)posterAtIndex:(int)index;
@end
