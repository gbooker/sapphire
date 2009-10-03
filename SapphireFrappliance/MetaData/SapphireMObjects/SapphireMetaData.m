#import "SapphireMetaData.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireMetaData

+ (SapphireMetaData *)metaDataWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", path];
	return (SapphireMetaData *)doSingleFetchRequest(SapphireMetaDataName, moc, predicate);
}

- (NSString *)name
{
	return [self.path lastPathComponent];
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order
{
	return nil;
}

@end
