#import "SapphireCategoryDirectory.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "SapphireFileSorter.h"
#import "CoreDataSupportFunctions.h"
#import "NSManagedObject-Extensions.h"

@implementation SapphireCategoryDirectory

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	if(self == nil)
		return self;
	
	cachedLookup = [[NSMutableDictionary alloc] init];
	cachedFiles = [[NSMutableArray alloc] init];
	cachedDirs = [[NSMutableArray alloc] init];
	cachedMetaFiles = [[NSMutableArray alloc] init];
	Basic_Directory_Function_Inits

	return self;
}

- (void) dealloc
{
	[cachedLookup release];
	[cachedFiles release];
	[cachedDirs release];
	[cachedMetaFiles release];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (NSString *)dirsValueFromFiles
{
	return nil;
}

- (NSString *)fileNameValue
{
	return @"path";
}

- (NSString *)dirNameValue
{
	return nil;
}

- (NSPredicate *)metaFileFetchPredicate
{
	return nil;
}

- (NSArray *)fileSorters
{
	return nil;
}

- (void)defaultDirectorySort:(NSMutableArray *)dirs
{
	[dirs sortUsingSelector:@selector(nameCompare:)];
}

- (NSMutableArray *)internalFileFetch
{
	NSPredicate *fetchPredicate = [self metaFileFetchPredicate];
	if(fetchPredicate == nil)
		return nil;
	
	NSPredicate *combPredicate;
	if(filterPredicate != nil)
		combPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:fetchPredicate, filterPredicate, nil]];
	else
		combPredicate = fetchPredicate;
	
	NSMutableArray *files = [doFetchRequest(SapphireFileMetaDataName, [self managedObjectContext], combPredicate) mutableCopy];
	
	[cachedMetaFiles setArray:files];
	return [files autorelease];
}

- (NSArray *)files
{
	return cachedFiles;
}

- (NSMutableArray *)internalDirectoryFetchFromFiles:(NSArray *)files
{
	return nil;
}

- (void)prefetch:(NSArray *)files
{
}

- (NSArray *)directories
{
	return cachedDirs;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	return [cachedLookup objectForKey:file];
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	return [cachedLookup objectForKey:directory];
}

- (void)reloadDirectoryContents
{
	[[self managedObjectContext] refreshObject:self mergeChanges:NO];
	[cachedLookup removeAllObjects];
	[cachedFiles removeAllObjects];
	[cachedDirs removeAllObjects];
	
	int sortValue = self.sortMethodValue;
	NSMutableArray *files = [self internalFileFetch];
	[self prefetch:files];
	if([files count] != 0)
	{
		NSString *fileNameKey = [self fileNameValue];
		if(![SapphireFileSorter sortFiles:files withSorter:sortValue inAllowedSorts:[self fileSorters]])
		{
			self.sortMethodValue = 0;
		}
		
		NSEnumerator *fileEnum = [files objectEnumerator];
		SapphireFileMetaData *file;
		while((file = [fileEnum nextObject]) != nil)
		{
			NSString *name = [file valueForKeyPath:fileNameKey];
			[cachedLookup setObject:file forKey:name];
			[cachedFiles addObject:name];
		}		
	}
	
	NSMutableArray *dirs = [self internalDirectoryFetchFromFiles:files];
	if([dirs count] != 0)
	{
		NSString *dirNameKey = [self dirNameValue];
		[self defaultDirectorySort:dirs];
		
		NSEnumerator *dirEnum = [dirs objectEnumerator];
		SapphireDirectoryMetaData *dir;
		while((dir = [dirEnum nextObject]) != nil)
		{
			NSString *name = [dir valueForKeyPath:dirNameKey];
			[dir setFilterPredicate:filterPredicate];
			[cachedLookup setObject:dir forKey:name];
			[cachedDirs addObject:name];
		}		
	}
	
	[delegate directoryContentsChanged];
}

- (NSString *)path
{
	return [@"@MOVIES" stringByAppendingPathComponent:[[self entity] name]];
}

- (NSString *)coverArtSearch:(NSString *)path PathUpToParents:(int)parents
{
	NSString *ret = searchCoverArtExtForPath([path stringByAppendingPathComponent:@"cover"]);
	if(ret != nil)
		return ret;
	
	if(parents != 0)
		return [self coverArtSearch:[path stringByDeletingLastPathComponent] PathUpToParents:parents-1];
	return nil;
}

- (NSString *)classDefaultCoverPath
{
	return nil;
}

- (NSString *)coverArtPath
{
	NSString *path = [self path];
	int count = [[path pathComponents] count];
	NSString *ret = [self coverArtSearch:[[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:path] PathUpToParents:count];
	if(ret != nil)
		return ret;
	
	return [self classDefaultCoverPath];
}

- (void)faultAllObjects
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *objEnum;
	NSManagedObject *obj;
	
	objEnum = [cachedLookup objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
	{
		[obj faultOjbectInContext:moc];
	}

	[self faultOjbectInContext:moc];
}

- (id <SapphireDirectory>)parentDirectory
{
	return nil;
}

- (void)invokeOnAllFiles:(NSInvocation *)fileInv
{
	NSArray *files = cachedMetaFiles;
	if(![files count])
		files = [self internalFileFetch];
	if([files count])
	{
		SapphireFileMetaData *file;
		NSEnumerator *fileEnum = [files objectEnumerator];
		while((file = [fileEnum nextObject]) != nil)
		{
			[fileInv invokeWithTarget:file];
		}
	}
}

- (BOOL)checkPredicate:(NSPredicate *)pred
{
	NSPredicate *fetchPred = [self metaFileFetchPredicate];
	if(fetchPred == nil)
		return NO;
	NSPredicate *final;
	if(pred == nil)
		final = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:fetchPred, filterPredicate, nil]];
	else
		final = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pred, fetchPred, filterPredicate, nil]];
	return entityExists(SapphireFileMetaDataName, [self managedObjectContext], final);	
}

- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
}

- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
}

- (void)cancelImport
{
}

- (void)resumeImport
{
}

- (BOOL)objectIsDeleted
{
	return [self objectHasBeenDeleted];
}

#define RECURSIVE_FUNCTIONS_ALREADY_DEFINED

#include "SapphireBasicDirectoryFunctions.h"

@end
