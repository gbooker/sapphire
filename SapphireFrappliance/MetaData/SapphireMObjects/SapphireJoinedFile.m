#import "SapphireJoinedFile.h"
#import "SapphireFileMetaData.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireJoinedFile

+ (SapphireJoinedFile *)joinedFileForPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", path];
	SapphireFileMetaData *joinedFile = (SapphireFileMetaData *)doSingleFetchRequest(SapphireFileMetaDataName, moc, predicate);
	if(joinedFile == nil)
		return nil;
	
	SapphireJoinedFile *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireJoinedFileName inManagedObjectContext:moc];
	ret.file = joinedFile;
	
	return ret;
}

+ (void)upgradeV1JoinedFileFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup
{
	NSArray *joins = doFetchRequest(SapphireJoinedFileName, oldMoc, nil);
	NSEnumerator *joinEnum = [joins objectEnumerator];
	NSManagedObject *oldJoin;
	while((oldJoin = [joinEnum nextObject]) != nil)
	{
		NSString *destinationPath = [oldJoin valueForKeyPath:@"file.path"];
		SapphireFileMetaData *destination = nil;
		if(destinationPath != nil)
			destination = [fileLookup objectForKey:destinationPath];
		if(destination == nil)
			continue;
		
		NSArray *containingPaths = [oldJoin valueForKeyPath:@"joinedFiles.path"];
		NSEnumerator *pathEnum = [containingPaths objectEnumerator];
		NSString *path;
		NSMutableSet *joined = [NSMutableSet set];
		while((path = [pathEnum nextObject]) != nil)
		{
			SapphireFileMetaData *join = [fileLookup objectForKey:path];
			if(join != nil)
				[joined addObject:join];
		}
		if([joined count] == 0)
			continue;
		
		SapphireJoinedFile *newJoin = [NSEntityDescription insertNewObjectForEntityForName:SapphireJoinedFileName inManagedObjectContext:newMoc];
		newJoin.file = destination;
		[newJoin.joinedFilesSet setSet:joined];
	}
}

@end
