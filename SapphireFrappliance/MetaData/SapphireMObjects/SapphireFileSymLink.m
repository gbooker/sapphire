#import "SapphireFileSymLink.h"
#import "SapphireFileMetaData.h"
#import "SapphireDirectoryMetaData.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireFileSymLink

+ (SapphireFileSymLink *)fileLinkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", path];
	return (SapphireFileSymLink *)doSingleFetchRequest(SapphireFileSymLinkName, moc, predicate);
}

+ (SapphireFileSymLink *)createFileLinkWithPath:(NSString *)path toPath:(NSString *)target inContext:(NSManagedObjectContext *)moc
{
	SapphireFileSymLink *ret = [SapphireFileSymLink fileLinkWithPath:path inContext:moc];
	if(ret == nil)
	{
		SapphireDirectoryMetaData *parent = [SapphireDirectoryMetaData createDirectoryWithPath:[path stringByDeletingLastPathComponent] inContext:moc];
		ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireFileSymLinkName inManagedObjectContext:moc];
		ret.containingDirectory = parent;
	}
	ret.path = path;
	SapphireDirectoryMetaData *targetParent = [SapphireDirectoryMetaData createDirectoryWithPath:[target stringByDeletingLastPathComponent] inContext:moc];
	SapphireFileMetaData *resolvedTarget = [SapphireFileMetaData createFileWithPath:target parent:targetParent inContext:moc];		
	ret.file = resolvedTarget;
	
	return ret;
}

+ (void)upgradeFileLinksVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc directories:(NSDictionary *)dirLookup file:(NSDictionary *)fileLookup
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *links = doFetchRequest(SapphireFileSymLinkName, oldMoc, nil);
	NSEnumerator *linkEnum = [links objectEnumerator];
	NSManagedObject *oldLink;
	while((oldLink = [linkEnum nextObject]) != nil)
	{
		NSString *destinationPath = [oldLink valueForKeyPath:@"file.path"];
		SapphireFileMetaData *destination = nil;
		if(destinationPath != nil)
			destination = [fileLookup objectForKey:destinationPath];
		if(destination == nil)
			continue;
		
		NSString *containingPath = [oldLink valueForKeyPath:@"containingDirectory.path"];
		SapphireDirectoryMetaData *containing = nil;
		if(containingPath != nil)
			containing = [dirLookup objectForKey:containingPath];
		if(containing == nil)
			continue;
		
		SapphireFileSymLink *newLink = [NSEntityDescription insertNewObjectForEntityForName:SapphireFileSymLinkName inManagedObjectContext:newMoc];
		newLink.path = [oldLink valueForKey:@"path"];
		newLink.file = destination;
		newLink.containingDirectory = containing;
	}
	[pool drain];
}

- (NSNumber *)watched
{
	return self.file.watched;
}

- (BOOL)watchedValue
{
	return self.file.watchedValue;
}

- (NSNumber *)favorite
{
	return self.file.favorite;
}

- (BOOL)favoriteValue
{
	return self.file.favoriteValue;
}

- (SapphireJoinedFile *)joinedToFile
{
	return self.file.joinedToFile;
}

@end
