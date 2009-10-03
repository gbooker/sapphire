#import "_SapphireSeason.h"

#define SapphireSeasonName		@"Season"

@interface SapphireSeason : _SapphireSeason {}
+ (SapphireSeason *)season:(int)season forShow:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc;
+ (SapphireSeason *)upgradeV1Season:(NSManagedObject *)oldSeason toShow:(SapphireTVShow *)show;

- (NSComparisonResult)compare:(SapphireSeason *)other;
- (NSString *)seasonName;
@end
