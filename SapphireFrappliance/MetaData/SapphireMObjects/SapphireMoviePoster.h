#import "_SapphireMoviePoster.h"

#define SapphireMoviePosterName @"MoviePoster"

@interface SapphireMoviePoster : _SapphireMoviePoster {}
+ (SapphireMoviePoster *)createPosterWithLink:(NSString *)link index:(int)index translation:(SapphireMovieTranslation *)translation inContext:(NSManagedObjectContext *)moc;
+ (SapphireMoviePoster *)upgradeMoviePosterVersion:(int)version from:(NSManagedObject *)oldTran toTranslation:(SapphireMovieTranslation *)translation;
@end
