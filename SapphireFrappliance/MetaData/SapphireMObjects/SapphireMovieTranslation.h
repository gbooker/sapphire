#import "_SapphireMovieTranslation.h"

#define SapphireMovieTranslationName @"MovieTranslation"

@class SapphireMoviePoster;

@interface SapphireMovieTranslation : _SapphireMovieTranslation {}
+ (SapphireMovieTranslation *)movieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovieTranslation *)createMovieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovieTranslation *)upgradeMovieTranslationVersion:(int)version from:(NSManagedObject *)oldTran toMovie:(SapphireMovie *)movie;
+ (void)upgradeMovieLessMovieTranslationVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;

- (NSArray *)orderedPosters;
- (SapphireMoviePoster *)selectedPoster;
- (SapphireMoviePoster *)posterAtIndex:(int)index;
@end
