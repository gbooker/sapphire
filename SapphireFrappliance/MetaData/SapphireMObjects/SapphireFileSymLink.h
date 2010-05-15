#import "_SapphireFileSymLink.h"

#define SapphireFileSymLinkName		@"FileSymLink"

@interface SapphireFileSymLink : _SapphireFileSymLink {}
+ (SapphireFileSymLink *)fileLinkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireFileSymLink *)createFileLinkWithPath:(NSString *)path toPath:(NSString *)target inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeFileLinksVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc directories:(NSDictionary *)dirLookup file:(NSDictionary *)fileLookup;
@end
