#import "_SapphireGenre.h"

#define SapphireGenreName		@"Genre"

@interface SapphireGenre : _SapphireGenre {}
+ (SapphireGenre *)createGenre:(NSString *)genre inContext:(NSManagedObjectContext *)moc;
+ (SapphireGenre *)genre:(NSString *)genre inContext:(NSManagedObjectContext *)moc;
+ (NSDictionary *)upgradeV1GenresFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
@end
