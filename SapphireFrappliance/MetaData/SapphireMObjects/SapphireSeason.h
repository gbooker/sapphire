#import "_SapphireSeason.h"

#define SapphireSeasonName		@"Season"

@interface SapphireSeason : _SapphireSeason {}
+ (SapphireSeason *)season:(int)season forShow:(NSString *)show inContext:(NSManagedObjectContext *)moc;
+ (SapphireSeason *)upgradeSeasonVersion:(int)version from:(NSManagedObject *)oldSeason toShow:(SapphireTVShow *)show;

- (NSComparisonResult)compare:(SapphireSeason *)other;
- (NSString *)seasonName;
- (NSString *)autoSortPath;
@end
