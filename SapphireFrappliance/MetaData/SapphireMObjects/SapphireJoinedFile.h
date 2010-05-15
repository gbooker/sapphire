#import "_SapphireJoinedFile.h"

#define SapphireJoinedFileName		@"JoinedFile"

@interface SapphireJoinedFile : _SapphireJoinedFile {}
+ (SapphireJoinedFile *)joinedFileForPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeJoinedFileVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup;
@end
