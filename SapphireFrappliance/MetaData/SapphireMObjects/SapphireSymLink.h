#import "_SapphireSymLink.h"

#define SapphireSymLinkName		@"SymLink"

@interface SapphireSymLink : _SapphireSymLink {}
+ (SapphireSymLink *)linkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
@end
