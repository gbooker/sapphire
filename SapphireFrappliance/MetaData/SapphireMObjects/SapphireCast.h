#import "_SapphireCast.h"

#define SapphireCastName		@"Cast"

@interface SapphireCast : _SapphireCast {}
+ (SapphireCast *)cast:(NSString *)cast inContext:(NSManagedObjectContext *)moc;
+ (SapphireCast *)createCast:(NSString *)cast inContext:(NSManagedObjectContext *)moc;
+ (NSDictionary *)upgradeV1CastFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
@end
