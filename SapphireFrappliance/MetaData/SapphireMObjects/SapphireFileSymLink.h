#import "_SapphireFileSymLink.h"

#define SapphireFileSymLinkName		@"FileSymLink"

@interface SapphireFileSymLink : _SapphireFileSymLink {}
+ (SapphireFileSymLink *)fileLinkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireFileSymLink *)createFileLinkWithPath:(NSString *)path toPath:(NSString *)target inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeV1FileLinksFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc directories:(NSDictionary *)dirLookup file:(NSDictionary *)fileLookup;

- (NSNumber *)watched;
- (BOOL)watchedValue;
- (NSNumber *)favorite;
- (BOOL)favoriteValue;
@end
