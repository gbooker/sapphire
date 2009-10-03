#import "SapphireCollectionDirectory.h"
#import "SapphireDirectoryMetaData.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireDirectorySymLink.h"
#import "NSFileManager-Extensions.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>

#define MOUNT_INFORMATION_KEY	@"mountInformation"
#define MOUNT_INFORMATION_DATA	@"mountInformationData"

@implementation SapphireCollectionDirectory

+ (SapphireCollectionDirectory *)collectionAtPath:(NSString *)path mount:(BOOL)isMount skip:(BOOL)skip hidden:(BOOL)hidden manual:(BOOL)manual inContext:(NSManagedObjectContext *)moc
{
	SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData createDirectoryWithPath:path inContext:moc];
	SapphireCollectionDirectory *ret = dir.collectionDirectory;
	if(ret != nil)
	{
		if(isMount)
			ret.isMountValue = isMount;
		return ret;
	}
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireCollectionDirectoryName inManagedObjectContext:moc];
	
	ret.manualCollectionValue = manual;
	ret.isMountValue = isMount;
	ret.skipValue = skip;
	ret.hiddenValue = hidden;
	ret.directory = dir;
	
	return ret;
}

+ (SapphireCollectionDirectory *)collectionAtPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	return [SapphireCollectionDirectory collectionAtPath:path mount:YES skip:NO hidden:NO manual:NO inContext:moc];
}

+ (SapphireCollectionDirectory *)upgradeV1CollectionDirectory:(NSManagedObject *)oldCol toContext:(NSManagedObjectContext *)newMoc
{
	SapphireCollectionDirectory *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireCollectionDirectoryName inManagedObjectContext:newMoc];
	ret.hidden = [oldCol valueForKey:@"hidden"];
	ret.isMount = [oldCol valueForKey:@"isMount"];
	ret.manualCollection = [oldCol valueForKey:@"manualCollection"];
	ret.skip = [oldCol valueForKey:@"skip"];
	
	return ret;
}

+ (NSString *)resolveSymLinksInCollectionPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	NSArray *components = [path pathComponents];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSEnumerator *pathCompEnum = [components objectEnumerator];
	NSString *pathComp;
	NSString *subPath = [pathCompEnum nextObject];  //Skip "/"
	while((pathComp = [pathCompEnum nextObject]) != nil)
	{
		subPath = [subPath stringByAppendingPathComponent:pathComp];
		if([fm isDirectory:subPath])
		{
			NSDictionary *attributes = [fm fileAttributesAtPath:subPath traverseLink:NO];
			if([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink])
			{
				SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData directoryWithPath:subPath inContext:moc];
				if(dir != nil)
				{
					NSString *resolvedPath = [subPath stringByResolvingSymlinksInPath];
					SapphireDirectoryMetaData *redundant = [SapphireDirectoryMetaData directoryWithPath:resolvedPath inContext:moc];
					if(redundant != nil)
						[moc deleteObject:redundant];
					[dir setPath:resolvedPath];
					[SapphireDirectorySymLink createDirectoryLinkWithPath:subPath toPath:resolvedPath inContext:moc];
				}
			}
		}
	}
	return [path stringByResolvingSymlinksInPath];
}

+ (NSArray *)availableCollectionDirectoriesInContext:(NSManagedObjectContext *)moc includeHiddenOverSkipped:(BOOL)hidden
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableSet *colSet = [NSMutableSet set];
    struct statfs *mntbufp;
	
	NSMutableSet *dvds = [NSMutableSet set];
	NSEnumerator *dvdEnum = [[NSClassFromString(@"BRDiskArbHandler") mountedDVDs] objectEnumerator];
	BRDiskInfo *dvdInfo;
	while((dvdInfo = [dvdEnum nextObject]) != nil)
		[dvds addObject:[dvdInfo mountpoint]];
	
    int i, mountCount = getmntinfo(&mntbufp, MNT_NOWAIT);
	for(i=0; i<mountCount; i++)
	{
		if(!strcmp(mntbufp[i].f_fstypename, "autofs"))
			continue;
		if(!strcmp(mntbufp[i].f_fstypename, "volfs"))
			continue;
		if(!strcmp(mntbufp[i].f_mntonname, "/dev"))
			continue;
		[colSet addObject:[fm stringWithFileSystemRepresentation:mntbufp[i].f_mntonname length:strlen(mntbufp[i].f_mntonname)]];
	}
	[colSet removeObject:@"/mnt"];
	[colSet removeObject:@"/CIFS"];
	[colSet removeObject:NSHomeDirectory()];
	NSString *homeMoviesPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
	if([[NSFileManager defaultManager] fileExistsAtPath:homeMoviesPath])
		[colSet addObject:homeMoviesPath];
	NSEnumerator *mountEnum = [[NSSet setWithSet:colSet] objectEnumerator];
	NSString *mountPoint;
	while((mountPoint = [mountEnum nextObject]) != nil)
	{
		if([dvds containsObject:mountPoint])
			//Don't show DVDs as collections
			continue;
		NSString *newPath = [SapphireCollectionDirectory resolveSymLinksInCollectionPath:mountPoint inContext:moc];
		[SapphireCollectionDirectory collectionAtPath:newPath mount:YES skip:NO hidden:NO manual:NO inContext:moc];
		if(![newPath isEqualToString:mountPoint])
		{
			[colSet removeObject:mountPoint];
			[colSet addObject:newPath];
		}
	}
	
	NSPredicate *predicate;
	if(hidden)
		predicate = [NSPredicate predicateWithFormat:@"(skip == NO) AND ((manualCollection == YES) OR (directory.path IN %@))", colSet];
	else
		predicate = [NSPredicate predicateWithFormat:@"(hidden == NO) AND ((manualCollection == YES) OR (directory.path IN %@))", colSet];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"directory.path" ascending:YES];
	NSArray *ret = doSortedFetchRequest(SapphireCollectionDirectoryName, moc, predicate, sort);

	[sort release];
	return ret;
}

+ (NSArray *)skippedCollectionDirectoriesInContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"skip == YES"];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"directory.path" ascending:YES];
	NSArray *ret = doSortedFetchRequest(SapphireCollectionDirectoryName, moc, predicate, sort);
	
	[sort release];
	return ret;
}

+ (NSArray *)allCollectionsInContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(manualCollection == YES) OR (isMount == YES)"];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"directory.path" ascending:YES];
	NSArray *ret = doSortedFetchRequest(SapphireCollectionDirectoryName, moc, predicate, sort);
	
	[sort release];
	return ret;
}

- (BOOL)deleteValue
{
	return toDelete;
}

- (void)setDeleteValue:(BOOL)del
{
	toDelete = del;
}

- (NSString *)rename:(NSString *)name
{
	self.name = name;
	[SapphireMetaDataSupport save:[self managedObjectContext]];
	return nil;
}

- (NSString *)name
{
	NSString *name = super.name;
	if(name == nil)
		return [self.directory path];
	return name;
}

- (NSDictionary *)mountInformation
{
	[self willAccessValueForKey:MOUNT_INFORMATION_KEY];
	NSDictionary *ret = [self primitiveValueForKey:MOUNT_INFORMATION_KEY];
	[self didAccessValueForKey:MOUNT_INFORMATION_KEY];
	if(ret == nil)
	{
		NSData *propData = [self valueForKey:MOUNT_INFORMATION_DATA];
		if(propData != nil)
		{
			ret = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
			[self setPrimitiveValue:ret forKey:MOUNT_INFORMATION_KEY];
		}
	}
	return ret;
}

- (void)setMountInformation:(NSDictionary *)info
{
	[self willChangeValueForKey:MOUNT_INFORMATION_KEY];
	[self setPrimitiveValue:info forKey:MOUNT_INFORMATION_KEY];
	[self didChangeValueForKey:MOUNT_INFORMATION_KEY];
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:info] forKey:MOUNT_INFORMATION_DATA];
}

@end
