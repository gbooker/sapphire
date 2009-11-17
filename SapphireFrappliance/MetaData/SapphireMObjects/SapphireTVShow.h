#import "_SapphireTVShow.h"

#define SapphireTVShowName	@"TVShow"

@interface SapphireTVShow : _SapphireTVShow {}
+ (SapphireTVShow *)show:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc;
+ (SapphireTVShow *)showWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeV1ShowsFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
+ (NSArray *)sortMethods;

- (NSComparisonResult)compare:(SapphireTVShow *)other;
@end
