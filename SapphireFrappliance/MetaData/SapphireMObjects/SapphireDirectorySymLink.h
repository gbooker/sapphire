#import "_SapphireDirectorySymLink.h"

#define SapphireDirectorySymLinkName		@"DirectorySymLink"

@interface SapphireDirectorySymLink : _SapphireDirectorySymLink {}
+ (SapphireDirectorySymLink *)directoryLinkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireDirectorySymLink *)createDirectoryLinkWithPath:(NSString *)path toPath:(NSString *)target inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeDirLinksVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc directories:(NSDictionary *)dirLookup;
@end
