#import "_SapphireJoinedFile.h"

#define SapphireJoinedFileName		@"JoinedFile"

@interface SapphireJoinedFile : _SapphireJoinedFile {}
+ (SapphireJoinedFile *)joinedFileForPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeV1JoinedFileFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup;
@end
