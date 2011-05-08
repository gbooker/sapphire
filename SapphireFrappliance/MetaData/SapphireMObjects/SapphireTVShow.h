#import "_SapphireTVShow.h"

#define SapphireTVShowName	@"TVShow"

@interface SapphireTVShow : _SapphireTVShow {}
+ (SapphireTVShow *)show:(NSString *)show inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeShowsVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
+ (NSArray *)sortMethods;

- (NSComparisonResult)compare:(SapphireTVShow *)other;
- (NSSet *)calculateAutoSortPaths;
- (NSString *)autoSortPath;
- (void)setAutoSortPath:(NSString *)path;
@end
