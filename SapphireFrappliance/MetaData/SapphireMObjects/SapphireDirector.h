#import "_SapphireDirector.h"

#define SapphireDirectorName		@"Director"

@interface SapphireDirector : _SapphireDirector {}
+ (SapphireDirector *)createDirector:(NSString *)director inContext:(NSManagedObjectContext *)moc;
+ (SapphireDirector *)director:(NSString *)director inContext:(NSManagedObjectContext *)moc;
+ (NSDictionary *)upgradeDirectorsVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
@end
