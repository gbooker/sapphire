#import "SapphireSymLink.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireSymLink

+ (SapphireSymLink *)linkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", path];
	return (SapphireSymLink *)doSingleFetchRequest(SapphireSymLinkName, moc, predicate);
}

@end
