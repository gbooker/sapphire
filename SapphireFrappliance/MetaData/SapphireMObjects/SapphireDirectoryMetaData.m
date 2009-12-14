#import "SapphireDirectorySymLink.h"
#import "SapphireFileSymLink.h"
#import "NSFileManager-Extensions.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireMetaDataScanner.h"
#import "SapphireImportHelper.h"
#import "NSString-Extensions.h"
#import "SapphireMetaDataUpgrading.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "SapphireEpisode.h"
#import "SapphireSubEpisode.h"
#import "SapphireMovie.h"
#import "NSManagedObject-Extensions.h"
#import "SapphireCollectionDirectory.h"

@implementation SapphireDirectoryMetaData

+ (SapphireDirectoryMetaData *)directoryWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	SapphireMetaData *meta = [SapphireMetaData metaDataWithPath:path inContext:moc];
	if([meta isKindOfClass:[SapphireDirectoryMetaData class]])
		return (SapphireDirectoryMetaData *)meta;
	return nil;
}

+ (SapphireDirectoryMetaData *)internalCreateDirectoryWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc
{
	SapphireDirectoryMetaData *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectoryMetaDataName inManagedObjectContext:moc];
	ret.parent = parent;
	ret.path = path;
	
	return ret;
}

+ (SapphireDirectoryMetaData *)createDirectoryWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	SapphireDirectoryMetaData *ret = [SapphireDirectoryMetaData directoryWithPath:path inContext:moc];
	if(ret != nil)
		return ret;
	
	SapphireDirectoryMetaData *parent = [SapphireDirectoryMetaData createDirectoryWithPath:[path stringByDeletingLastPathComponent] inContext:moc];
	ret = [SapphireDirectoryMetaData internalCreateDirectoryWithPath:path parent:parent inContext:moc];
	
	return ret;
}

+ (SapphireDirectoryMetaData *)createDirectoryWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc
{
	SapphireDirectoryMetaData *ret = [SapphireDirectoryMetaData directoryWithPath:path inContext:moc];
	if(ret != nil)
		return ret;

	return [SapphireDirectoryMetaData internalCreateDirectoryWithPath:path parent:parent inContext:moc];
}

+ (NSDictionary *)upgradeV1DirectoriesFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSArray *dirs = doFetchRequest(SapphireDirectoryMetaDataName, oldMoc, nil);
	NSEnumerator *dirEnum = [dirs objectEnumerator];
	NSManagedObjectContext *oldDir;
	while((oldDir = [dirEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *newDir = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectoryMetaDataName inManagedObjectContext:newMoc];
		NSString *path = [oldDir valueForKey:@"path"];
		newDir.path = path;
		NSManagedObject *oldCollection = [newDir valueForKey:@"collectionDirectory"];
		if(oldCollection != nil)
			newDir.collectionDirectory = [SapphireCollectionDirectory upgradeV1CollectionDirectory:oldCollection toContext:newMoc];
		[lookup setObject:newDir forKey:path];
	}
	dirEnum = [dirs objectEnumerator];
	while((oldDir = [dirEnum nextObject]) != nil)
	{
		NSString *path = [oldDir valueForKey:@"path"];
		NSString *parentPath = [oldDir valueForKeyPath:@"parent.path"];
		if(parentPath != nil)
			((SapphireDirectoryMetaData *)[lookup objectForKey:path]).parent = [lookup objectForKey:parentPath];
	}
	return lookup;
}

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	if(self == nil)
		return self;
	
	Basic_Directory_Function_Inits
	importArray = [[NSMutableArray alloc] init];
	
	return self;
}	

- (void) dealloc
{
	[importArray release];
	[cachedLookup release];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}


- (void)insertDictionary:(NSDictionary *)dict withDefer:(NSMutableDictionary *)defer andDisplay:(SapphireMetaDataUpgrading *)display
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSDictionary *dirs = [dict objectForKey:@"Dirs"];
	NSArray *allDirs = [[dirs allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSEnumerator *dirEnum = [allDirs objectEnumerator];
	NSString *dir;
	while((dir = [dirEnum nextObject]) != nil)
	{
		NSString *path = [self.path stringByAppendingPathComponent:dir];
		SapphireDirectoryMetaData *newDir = [SapphireDirectoryMetaData createDirectoryWithPath:path parent:self inContext:moc];
		[newDir insertDictionary:[dirs objectForKey:dir] withDefer:defer andDisplay:display];
		if([newDir.metaDirsSet count] == 0 && [newDir.metaFilesSet count] == 0)
		{
			newDir.parent = nil;
			[moc deleteObject:newDir];
		}
	}
	NSDictionary *files = [dict objectForKey:@"Files"];
	NSArray *allFiles = [[files allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSEnumerator *fileEnum = [allFiles objectEnumerator];
	NSString *file;
	while((file = [fileEnum nextObject]) != nil)
	{
		NSString *path = [self.path stringByAppendingPathComponent:file];
		[display setCurrentFile:[NSString stringByCroppingDirectoryPath:path toLength:3]];
		SapphireFileMetaData *newFile = [SapphireFileMetaData createFileWithPath:path parent:self inContext:moc];
		[newFile insertDictionary:[files objectForKey:file] withDefer:defer];
	}
}

- (BOOL)checkPredicate:(NSPredicate *)pred duplicateSet:(NSMutableSet *)dups
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSPredicate *pathPredicate = [NSPredicate predicateWithFormat:@"path BEGINSWITH %@", [self.path stringByAppendingString:@"/"]];
	NSPredicate *predicate;
	if(pred == nil)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pathPredicate, filterPredicate, nil]];
	else
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pathPredicate, pred, filterPredicate, nil]];
	if(entityExists(SapphireFileMetaDataName, moc, predicate))
		return YES;
	
	NSArray *array = doFetchRequest(SapphireFileSymLinkName, moc, pathPredicate);
	if([array count])
	{
		NSEnumerator *symEunm = [array objectEnumerator];
		SapphireFileSymLink *sym;
		while((sym = [symEunm nextObject]) != nil)
		{
			SapphireFileMetaData *file = sym.file;
			//Doing a predicate check is likely faster than these two property fetches and prefix match
/*			NSString *finalPath = file.path;
			if([finalPath hasPrefix:self.path])
				continue;*/
			if(pred == nil || [pred evaluateWithObject:file])
				return YES;
		}
	}
	
	array = doFetchRequest(SapphireDirectorySymLinkName, moc, pathPredicate);
	if([array count])
	{
		SapphireDirectorySymLink *sym = nil;
		NSEnumerator *symEnum = [array objectEnumerator];
		while((sym = [symEnum nextObject]) != nil)
		{
			SapphireDirectoryMetaData *dir = sym.directory;
			NSString *finalPath = dir.path;
			if([dups containsObject:finalPath] || [finalPath hasPrefix:self.path])
				continue;
			[dups addObject:finalPath];
			[dir setFilterPredicate:filterPredicate];
			if([dir checkPredicate:pred duplicateSet:dups])
				return YES;
		}
	}
	return NO;
}

NSComparisonResult fileAndLinkEpisodeCompare(id file1, id file2, void *context)
{
	/*Resolve link and try to sort by episodes*/
	SapphireFileMetaData *first;
	if([file1 isKindOfClass:[SapphireFileMetaData class]])
		first = (SapphireFileMetaData *)file1;
	else
		first = ((SapphireFileSymLink *)file1).file;

	SapphireFileMetaData *second;
	if([file2 isKindOfClass:[SapphireFileMetaData class]])
		second = (SapphireFileMetaData *)file2;
	else
		second = ((SapphireFileSymLink *)file2).file;
	
	NSComparisonResult result = [first episodeCompare:second];
	if(result != NSOrderedSame)
		return result;
	
	result = [first movieCompare:second];
	if(result != NSOrderedSame)
		return result;
	
	/*Finally sort by path*/
	return [[[file1 valueForKey:@"path"] lastPathComponent] nameCompare:[[file2 valueForKey:@"path"] lastPathComponent]];
}

NSComparisonResult dirAndLinkPathCompare(id dir1, id dir2, void *context)
{
	return [[[dir1 valueForKey:@"path"] lastPathComponent] nameCompare:[[dir2 valueForKey:@"path"] lastPathComponent]];
}

- (NSArray *)files
{
	return cachedFiles;
}

- (NSArray *)directories
{
	return cachedDirs;
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	SapphireDirectoryMetaData *ret = [cachedLookup objectForKey:directory];
	if(ret != nil)
	{
		if([ret isKindOfClass:[SapphireDirectorySymLink class]])
			ret = [(SapphireDirectorySymLink *)ret directory];
		return ret;
	}
	SapphireLog(SAPPHIRE_LOG_GENERAL, SAPPHIRE_LOG_LEVEL_ERROR, @"Somehow couldn't get cache for %@ in %@", directory, self.path);
	NSString *path = [self.path stringByAppendingPathComponent:directory];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"path == %@", path];
	NSArray *candidates = [[self.metaDirsSet allObjects] filteredArrayUsingPredicate:pred];
	if([candidates count])
		ret = [candidates objectAtIndex:0];
	else
	{
		candidates  = [[self.linkedDirsSet allObjects] filteredArrayUsingPredicate:pred];
		if([candidates count])
			ret = ((SapphireDirectorySymLink *)[candidates objectAtIndex:0]).directory;		
	}
	[ret setFilterPredicate:filterPredicate];
	
	return nil;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	SapphireFileMetaData *ret = [cachedLookup objectForKey:file];
	if(ret != nil)
	{
		if([ret isKindOfClass:[SapphireFileSymLink class]])
			ret = [(SapphireFileSymLink *)ret file];
		return ret;
	}
	NSString *path = [self.path stringByAppendingPathComponent:file];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"path == %@", path];
	NSArray *candidates = [[self.metaFilesSet allObjects] filteredArrayUsingPredicate:pred];
	if([candidates count])
		return [candidates objectAtIndex:0];
	
	candidates  = [[self.linkedFilesSet allObjects] filteredArrayUsingPredicate:pred];
	if([candidates count])
		return ((SapphireFileSymLink *)[candidates objectAtIndex:0]).file;
	
	return nil;
}

- (void)rescanDirWithExistingDirs:(NSMutableArray *)existingDirs files:(NSMutableArray *)existingFiles symDirs:(NSMutableArray *)existingSymDirs symFiles:(NSMutableArray *)existingSymFiles;
{
	[importArray removeAllObjects];

	NSMutableDictionary *dirs = [[NSMutableDictionary alloc] init];
	NSEnumerator *cachedEnum = [existingDirs objectEnumerator];
	NSManagedObject *object;
	while((object = [cachedEnum nextObject]) != nil)
	{
		[dirs setObject:object forKey:[object valueForKeyPath:@"path.lastPathComponent"]];
	}
	
	NSMutableDictionary *files = [[NSMutableDictionary alloc] init];
	cachedEnum = [existingFiles objectEnumerator];
	while((object = [cachedEnum nextObject]) != nil)
	{
		[files setObject:object forKey:[object valueForKeyPath:@"path.lastPathComponent"]];
	}

	NSMutableDictionary *linkedDirs = [[NSMutableDictionary alloc] init];
	cachedEnum = [existingSymDirs objectEnumerator];
	while((object = [cachedEnum nextObject]) != nil)
	{
		[linkedDirs setObject:object forKey:[object valueForKeyPath:@"path.lastPathComponent"]];
	}

	NSMutableDictionary *linkedFiles = [[NSMutableDictionary alloc] init];
	cachedEnum = [existingSymFiles objectEnumerator];
	while((object = [cachedEnum nextObject]) != nil)
	{
		[linkedFiles setObject:object forKey:[object valueForKeyPath:@"path.lastPathComponent"]];
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSManagedObjectContext *moc = [self managedObjectContext];
	
	NSArray *names = [fm directoryContentsAtPath:self.path];
	NSEnumerator *nameEnum = [names objectEnumerator];
	NSString *name;
	BOOL modified = NO;	
	while((name = [nameEnum nextObject]) != nil)
	{
		NSString *filePath = [self.path stringByAppendingPathComponent:name];
		if(![fm acceptFilePath:filePath])
			continue;
		
		NSDictionary *attributes = [fm fileAttributesAtPath:filePath traverseLink:NO];
		if([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink])
		{
			/*Sym links are fun*/
			NSString *resolvedPath = [filePath stringByResolvingSymlinksInPath];
			if(![fm acceptFilePath:resolvedPath])
				continue;
			
			if(![fm fileExistsAtPath:resolvedPath])
				continue;
			
			if([fm isDirectory:resolvedPath])
			{
				if([dirs objectForKey:name] != nil)
				{
					//Dir moved, but original data is still here
					SapphireDirectoryMetaData *resolved = [SapphireDirectoryMetaData directoryWithPath:resolvedPath inContext:moc];
					if(resolved != nil)
						[moc deleteObject:resolved];
					
					resolved = [dirs objectForKey:name];
					resolved.parent = [SapphireDirectoryMetaData createDirectoryWithPath:[resolvedPath stringByDeletingLastPathComponent] inContext:moc];
					resolved.path = resolvedPath;
					[dirs removeObjectForKey:name];
				}
				SapphireDirectorySymLink *newLink = [SapphireDirectorySymLink createDirectoryLinkWithPath:filePath toPath:resolvedPath inContext:moc];
				if([linkedDirs objectForKey:name] != nil)
					[linkedDirs removeObjectForKey:name];
				else
					[existingSymDirs addObject:newLink];
			}
			else
			{
				if([files objectForKey:name] != nil)
				{
					//File moved, but original data is still here
					SapphireFileMetaData *resolved = [SapphireFileMetaData fileWithPath:resolvedPath inContext:moc];
					if(resolved != nil)
						[moc deleteObject:resolved];
					
					resolved = [files objectForKey:name];
					resolved.parent = [SapphireDirectoryMetaData createDirectoryWithPath:[resolvedPath stringByDeletingLastPathComponent] inContext:moc];
					resolved.path = resolvedPath;
					[files removeObjectForKey:name];
				}
				SapphireFileSymLink *newLink = [SapphireFileSymLink createFileLinkWithPath:filePath toPath:resolvedPath inContext:moc];
				if([linkedFiles objectForKey:name] != nil)
					[linkedFiles removeObjectForKey:name];
				else
					[existingSymFiles addObject:newLink];
			}
			/*	It's not always modified, but rather than figuring out all the cases where it is or isn't
			 just set it to YES for a rare case and figure it out later if it's an issue*/
			modified = YES;
		}
		else if([fm isDirectory:filePath])
		{
			SapphireDirectoryMetaData *subDir = [dirs objectForKey:name];
			if(subDir == nil)
			{
				subDir = [SapphireDirectoryMetaData createDirectoryWithPath:filePath parent:self inContext:moc];
				[existingDirs addObject:subDir];
				modified = YES;
			}
			else
				[dirs removeObjectForKey:name];
		}
		else
		{
			SapphireFileMetaData *subFile = [files objectForKey:name];
			if(subFile == nil)
			{
				subFile = [SapphireFileMetaData createFileWithPath:filePath parent:self inContext:moc];
				[existingFiles addObject:subFile];
				[importArray addObject:subFile];
				modified = YES;
			}
			else
			{
				[files removeObjectForKey:name];
				if([subFile needsImporting])
					[importArray addObject:subFile];				
			}
			if([fm hasVIDEO_TS:filePath])
				subFile.fileContainerTypeValue = FILE_CONTAINER_TYPE_VIDEO_TS;
			else
				subFile.fileContainerTypeValue = FILE_CONTAINER_TYPE_QT_MOVIE;
		}
	}
	
	NSEnumerator *objectEnum = [files objectEnumerator];
	while((object = [objectEnum nextObject]) != nil)
	{
		[existingFiles removeObject:object];
		[moc deleteObject:object];
		modified = YES;
	}
	[files release];
	
	objectEnum = [dirs objectEnumerator];
	while((object = [objectEnum nextObject]) != nil)
	{
		[existingDirs removeObject:object];
		[moc deleteObject:object];
		modified = YES;
	}
	[dirs release];
	
	objectEnum = [linkedFiles objectEnumerator];
	while((object = [objectEnum nextObject]) != nil)
	{
		[existingSymFiles removeObject:object];
		[moc deleteObject:object];
		modified = YES;
	}
	[linkedFiles release];
	
	objectEnum = [linkedDirs objectEnumerator];
	while((object = [objectEnum nextObject]) != nil)
	{
		[existingSymDirs removeObject:object];
		[moc deleteObject:object];
		modified = YES;
	}
	[linkedDirs release];
	
	if(modified)
	{
		[self clearPredicateCache];
		[SapphireMetaDataSupport save:moc];
	}
}

- (void)reloadDirectoryContents
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	[moc refreshObject:self mergeChanges:YES];
	
	[cachedLookup release];
	cachedLookup = [[NSMutableDictionary alloc] init];

	NSPredicate *fetchPred = [NSPredicate predicateWithFormat:@"parent == %@", self];
	NSMutableArray *fetchedFiles = [doFetchRequest(SapphireFileMetaDataName, moc, fetchPred) mutableCopy];
	NSMutableArray *fetchedDirs = [doFetchRequest(SapphireDirectoryMetaDataName, moc, fetchPred) mutableCopy];
	NSMutableArray *linkedFiles = [[self.linkedFilesSet allObjects] mutableCopy];
	NSMutableArray *linkedDirs = [[self.linkedDirsSet allObjects] mutableCopy];
	
	[self rescanDirWithExistingDirs:fetchedDirs files:fetchedFiles symDirs:linkedDirs symFiles:linkedFiles];
	
	NSMutableArray *allFiles = [fetchedFiles mutableCopy];
	[allFiles addObjectsFromArray:linkedFiles];
	if(filterPredicate != nil)
		[allFiles filterUsingPredicate:filterPredicate];

	if([allFiles count])
	{
		NSMutableSet *files = [NSMutableSet setWithArray:fetchedFiles];
		[files addObjectsFromArray:[linkedFiles valueForKey:@"file"]];
		NSSet *allEps = [files valueForKeyPath:@"tvEpisode.objectID"];
		if([allEps count])
		{
			NSPredicate *fetchPred = [NSPredicate predicateWithFormat:@"SELF IN %@", allEps];
			NSArray *episodes = doFetchRequest(SapphireEpisodeName, moc, fetchPred);
			if([episodes count])
			{
				fetchPred = [NSPredicate predicateWithFormat:@"episode IN %@", episodes];
				doFetchRequest(SapphireSubEpisodeName, moc, fetchPred);
			}
		}
		NSSet *allMovies = [files valueForKeyPath:@"movie.objectID"];
		if([allMovies count])
		{
			NSPredicate *fetchPred = [NSPredicate predicateWithFormat:@"SELF IN %@", allMovies];
			doFetchRequest(SapphireMovieName, moc, fetchPred);
		}
	}		
	[allFiles sortUsingFunction:fileAndLinkEpisodeCompare context:nil];
	[cachedFiles release];
	cachedFiles = [[NSMutableArray alloc] init];
	NSEnumerator *objEnum = [allFiles objectEnumerator];
	SapphireFileMetaData *file;
	while((file = [objEnum nextObject]) != nil)
	{
		NSString *name = [file.path lastPathComponent];
		[cachedFiles addObject:name];
		[cachedLookup setObject:file forKey:name];
	}
	[allFiles release];
	[fetchedFiles release];
	[linkedFiles release];
	
	NSMutableArray *allDirs = [fetchedDirs mutableCopy];
	if(filterPredicate != nil)
	{
		int i, count = [allDirs count];
		for(i=0; i<count; i++)
		{
			SapphireDirectoryMetaData *dir = [allDirs objectAtIndex:i];
			if(filterPredicate != [SapphireApplianceController unfilteredPredicate] && ![dir containsFileMatchingFilterPredicate:filterPredicate])
			{
				[allDirs removeObjectAtIndex:i];
				i--;
				count--;
			}
			else
			{
				[dir setFilterPredicate:filterPredicate];
			}
		}
	}
	if(filterPredicate != nil)
	{
		int i, count = [linkedDirs count];
		for(i=0; i<count; i++)
		{
			SapphireDirectorySymLink *link = [linkedDirs objectAtIndex:i];
			SapphireDirectoryMetaData *dir = [link directory];
			if([dir containsFileMatchingFilterPredicate:filterPredicate])
			{
				[allDirs addObject:link];
				[dir setFilterPredicate:filterPredicate];
			}
		}
	}
	else
		[allDirs addObjectsFromArray:linkedDirs];
	[allDirs sortUsingFunction:dirAndLinkPathCompare context:nil];
	[cachedDirs release];
	cachedDirs = [[NSMutableArray alloc] init];
	objEnum = [allDirs objectEnumerator];
	SapphireDirectoryMetaData *dir;
	while((dir = [objEnum nextObject]) != nil)
	{
		NSString *name = [dir.path lastPathComponent];
		[cachedDirs addObject:name];
		[cachedLookup setObject:dir forKey:name];
	}
	[allDirs release];
	[fetchedDirs release];
	[linkedDirs release];
	[delegate directoryContentsChanged];
}

- (NSString *)coverArtPathUpToParents:(int)parents
{
	NSString *ret = searchCoverArtExtForPath([[self path] stringByAppendingPathComponent:@"Cover Art/cover"]);
	if(ret != nil)
		return ret;
	
	ret = searchCoverArtExtForPath([[self path] stringByAppendingPathComponent:@"cover"]);
	if(ret != nil)
		return ret;
	
	if(parents != 0)
		return [[self parent] coverArtPathUpToParents:parents-1];
	return nil;
}

- (NSString *)coverArtPath
{
	return [self coverArtPathUpToParents:2];
}

- (void)invokeOnAllFiles:(NSInvocation *)fileInv
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path BEGINSWITH %@", [self.path stringByAppendingString:@"/"]];
	if(filterPredicate != nil)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, filterPredicate, nil]];
	NSArray *array = doFetchRequest(SapphireFileMetaDataName, moc, predicate);

	if([array count])
	{
		SapphireFileMetaData *file;
		NSEnumerator *fileEnum = [array objectEnumerator];
		while((file = [fileEnum nextObject]) != nil)
		{
			[fileInv invokeWithTarget:file];
		}
	}
}

- (BOOL)checkPredicate:(NSPredicate *)pred
{
	NSMutableSet *dupSet = [[NSMutableSet alloc] init];
	BOOL ret = [self checkPredicate:pred duplicateSet:dupSet];
	[dupSet release];
	return ret;
}

- (void)conductScanWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip andResults:(BOOL)results
{
	/*Scan dir and create scanner*/
	SapphireMetaDataScanner *scanner = [[SapphireMetaDataScanner alloc] initWithDirectoryMetaData:self delegate:subDelegate];
	
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"path BEGINSWITH %@", [self.path stringByAppendingString:@"/"]];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"path" ascending:YES];
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSArray *dirs = doSortedFetchRequest(SapphireDirectoryMetaDataName, moc, fetchPredicate, sort);
	NSArray *files = doSortedFetchRequest(SapphireFileMetaDataName, moc, fetchPredicate, sort);
	NSArray *symDirs = doSortedFetchRequest(SapphireDirectorySymLinkName, moc, fetchPredicate, sort);
	NSArray *symFiles = doSortedFetchRequest(SapphireFileSymLinkName, moc, fetchPredicate, sort);
	[sort release];
	
	[scanner setSubDirs:dirs files:files symDirs:symDirs symFiles:symFiles];
	
	/*Add ourselves to not rescan*/
	[skip addObject:self.path];
	[scanner setSkipDirectories:skip];
	/*We want results*/
	[scanner setGivesResults:results];
	[scanner release];
}

- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
	[self conductScanWithDelegate:subDelegate skipDirectories:skip andResults:YES];
}

- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
	[self conductScanWithDelegate:subDelegate skipDirectories:skip andResults:NO];
}

- (void)processNextFile
{
	if(![importArray count])
	{
		importing &= ~2;
		return;
	}
	SapphireFileMetaData *file = [importArray objectAtIndex:0];
	
	/*Get the file and update it*/
	importing |= 2;
	[[SapphireImportHelper sharedHelperForContext:[self managedObjectContext]] importAllData:file inform:self];
}

- (void)realInformComplete
{
	/*Tell delegate we updated*/
	[SapphireMetaDataSupport save:[self managedObjectContext]];
	SapphireFileMetaData *file = [importArray objectAtIndex:0];
	[delegate updateCompleteForFile:[[file path] lastPathComponent]];
	
	/*Remove from list and redo timer*/
	[importArray removeObjectAtIndex:0];
	if(importing & 1)
		[self processNextFile];
	else
		importing = 0;
}

- (oneway void)informComplete:(BOOL)updated onPath:(NSString *)path
{
	[self performSelectorOnMainThread:@selector(realInformComplete) withObject:nil waitUntilDone:NO];
}

- (void)cancelImport
{
	importing &= ~1;
}

- (void)resumeImport
{
	importing |= 1;
	if(!(importing & 2) && ![self isDeleted])
		[self processNextFile];
}

- (NSArray *)importFilePaths
{
	return [importArray valueForKey:@"path"];
}

- (void)addImportFilePaths:(NSArray *)newPaths
{
	NSSet *currentPaths = [NSSet setWithArray:[self importFilePaths]];
	
	NSEnumerator *pathEnum = [newPaths objectEnumerator];
	NSString *path;
	while((path = [pathEnum nextObject]) != nil)
	{
		if([currentPaths containsObject:path])
			continue;
		
		[importArray addObject:[SapphireFileMetaData fileWithPath:path inContext:[self managedObjectContext]]];
	}
}

- (void)faultAllObjects
{
	if([self isFault] || delegate != nil)
		return;
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *objEnum;
	NSManagedObject *obj;
	
	objEnum = [self.metaFilesSet objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
		[obj faultOjbectInContext:moc];
	
	objEnum = [self.metaDirsSet objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
		[obj faultOjbectInContext:moc];
	
	objEnum = [self.linkedFilesSet objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
	{
		SapphireFileSymLink *link = (SapphireFileSymLink *)obj;
		if(![link isFault])
		{
			[link.file faultOjbectInContext:moc];
			[link faultOjbectInContext:moc];
		}
	}
	
	objEnum = [self.linkedDirsSet objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
	{
		SapphireDirectorySymLink *link = (SapphireDirectorySymLink *)obj;
		if(![link isFault])
		{
			[link.directory faultOjbectInContext:moc];
			[link faultOjbectInContext:moc];
		}
	}
	
	[self faultOjbectInContext:moc];
}

- (id <SapphireDirectory>)parentDirectory
{
	return self.parent;
}

- (void)setPath:(NSString *)path
{
	if([path isEqualToString:super.path])
		return;
	super.path = path;
	//Correct underlings
	NSEnumerator *underlingEnum = [self.metaDirsSet objectEnumerator];
	SapphireDirectoryMetaData *dir;
	while((dir = [underlingEnum nextObject]) != nil)
		dir.path = [path stringByAppendingPathComponent:[dir.path lastPathComponent]];

	underlingEnum = [self.metaFilesSet objectEnumerator];
	SapphireFileMetaData *file;
	while((file = [underlingEnum nextObject]) != nil)
		file.path = [path stringByAppendingPathComponent:[file.path lastPathComponent]];

	underlingEnum = [self.linkedDirsSet objectEnumerator];
	SapphireDirectorySymLink *symDir;
	while((symDir = [underlingEnum nextObject]) != nil)
		symDir.path = [path stringByAppendingPathComponent:[symDir.path lastPathComponent]];

	underlingEnum = [self.linkedFilesSet objectEnumerator];
	SapphireFileSymLink *symFile;
	while((symFile = [underlingEnum nextObject]) != nil)
		symFile.path = [path stringByAppendingPathComponent:[symFile.path lastPathComponent]];
}

static BOOL moving = NO;
static BOOL moveSuccess = NO;
static NSString *movingFromPath = @"From";
static NSString *movingToPath = @"To";

- (void)threadedMove:(NSDictionary *)pathInfo
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	moveSuccess = [[NSFileManager defaultManager] movePath:[pathInfo objectForKey:movingFromPath] toPath:[pathInfo objectForKey:movingToPath] handler:nil];
	moving = NO;
	[pool drain];
}

- (NSString *)moveToPath:(NSString *)newPath pathForMoveError:(NSString *)errorPath inDir:(SapphireDirectoryMetaData *)newParent
{
	NSString *oldPath = [self path];
	NSFileManager *fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:newPath])
		return [NSString stringWithFormat:BRLocalizedString(@"The name %@ is already taken", @"Name taken on a file/directory rename; parameter is name"), [newPath lastPathComponent]];
	if(newParent != nil)
	{
		moving = YES;
		[NSThread detachNewThreadSelector:@selector(threadedMove:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
																							 oldPath, movingFromPath,
																							 newPath, movingToPath,
																							 nil]];
		while(moving)
			[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:1]];
	}
	else
		moveSuccess = [fm movePath:oldPath toPath:newPath handler:nil];
	if(!moveSuccess)
		return [NSString stringWithFormat:BRLocalizedString(@"Could not move to %@.  Is the filesystem read-only?", @"Unknown error renaming file/directory; parameter is name"), errorPath];
	[self setPath:newPath];
	if(newParent != nil)
	{
		SapphireDirectoryMetaData *oldParent = self.parent;
		self.parent = newParent;
		[oldParent clearPredicateCache];
		[newParent clearPredicateCache];
	}
	[SapphireMetaDataSupport save:[self managedObjectContext]];
	return nil;
}

- (NSString *)moveToDir:(SapphireDirectoryMetaData *)dir
{
	NSString *destination = [dir path];
	NSString *newPath = [destination stringByAppendingPathComponent:[[self path] lastPathComponent]];
	return [self moveToPath:newPath pathForMoveError:[newPath lastPathComponent] inDir:dir];
}

- (NSString *)rename:(NSString *)newName
{
	int componentCount = [[newName pathComponents] count];
	if(componentCount != 1)
		return BRLocalizedString(@"A Directory name should not contain any '/' characters", @"Error indicating that filenames cannot contain / characters");
	NSString *oldPath = [self path];
	NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
	return [self moveToPath:newPath pathForMoveError:newName inDir:nil];
}

- (BOOL)objectIsDeleted
{
	return [self objectHasBeenDeleted];
}

#define RECURSIVE_FUNCTIONS_ALREADY_DEFINED
#include "SapphireBasicDirectoryFunctions.h"

@end
