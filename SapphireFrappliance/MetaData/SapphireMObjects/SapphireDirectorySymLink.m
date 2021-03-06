#import "SapphireDirectorySymLink.h"
#import "SapphireDirectoryMetaData.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireDirectorySymLink

+ (SapphireDirectorySymLink *)directoryLinkWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", path];
	return (SapphireDirectorySymLink *)doSingleFetchRequest(SapphireDirectorySymLinkName, moc, predicate);
}

+ (SapphireDirectorySymLink *)createDirectoryLinkWithPath:(NSString *)path toPath:(NSString *)target inContext:(NSManagedObjectContext *)moc
{
	SapphireDirectorySymLink *ret = [SapphireDirectorySymLink directoryLinkWithPath:path inContext:moc];
	if(ret == nil)
	{
		SapphireDirectoryMetaData *parent = [SapphireDirectoryMetaData createDirectoryWithPath:[path stringByDeletingLastPathComponent] inContext:moc];
		ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectorySymLinkName inManagedObjectContext:moc];
		ret.containingDirectory = parent;
	}
	ret.path = path;
	SapphireDirectoryMetaData *resolvedTarget = [SapphireDirectoryMetaData createDirectoryWithPath:target inContext:moc];		
	ret.directory = resolvedTarget;
	
	return ret;
}

+ (void)upgradeDirLinksVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc directories:(NSDictionary *)dirLookup
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *links = doFetchRequest(SapphireDirectorySymLinkName, oldMoc, nil);
	NSEnumerator *linkEnum = [links objectEnumerator];
	NSManagedObject *oldLink;
	while((oldLink = [linkEnum nextObject]) != nil)
	{
		NSString *destinationPath = [oldLink valueForKeyPath:@"directory.path"];
		SapphireDirectoryMetaData *destination = nil;
		if(destinationPath != nil)
			destination = [dirLookup objectForKey:destinationPath];
		if(destination == nil)
			continue;
		
		NSString *containingPath = [oldLink valueForKeyPath:@"containingDirectory.path"];
		SapphireDirectoryMetaData *containing = nil;
		if(containingPath != nil)
			containing = [dirLookup objectForKey:containingPath];
		if(containing == nil)
			continue;
		
		SapphireDirectorySymLink *newLink = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectorySymLinkName inManagedObjectContext:newMoc];
		newLink.path = [oldLink valueForKey:@"path"];
		newLink.directory = destination;
		newLink.containingDirectory = containing;
	}
	[pool drain];
}

@end
