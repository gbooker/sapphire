/*
 * SapphireMetaData.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 22, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SapphireMetaData.h"
#import <QTKit/QTKit.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>
#import "SapphireSettings.h"
#import "SapphirePredicates.h"
#import "SapphireMetaDataScanner.h"
#import "SapphireImportHelper.h"
#import "SapphireVideoTSParser.h"

//Structure Specific Keys
#define FILES_KEY					@"Files"
#define DIRS_KEY					@"Dirs"
#define META_VERSION_KEY			@"Version"
#define META_COLLECTION_OPTIONS		@"Options"
#define META_COLLECTION_HIDE		@"Hide"
#define META_COLLECTION_SKIP_SCAN	@"Skip"
#define META_COLLECTION_DIRS		@"Directories"
#define META_FILE_VERSION			2
#define META_COLLECTION_VERSION		4

//File Specific Keys
#define MODIFIED_KEY				@"Modified"
#define WATCHED_KEY					@"Watched"
#define FAVORITE_KEY				@"Favorite"
#define RESUME_KEY					@"Resume Time"
#define SIZE_KEY					@"Size"
#define DURATION_KEY				@"Duration"
#define AUDIO_DESC_KEY				@"Audio Description"
#define SAMPLE_RATE_KEY				@"Sample Rate"
#define VIDEO_DESC_KEY				@"Video Description"
#define AUDIO_FORMAT_KEY			@"Audio Format"
#define SUBTITLES_KEY				@"Subtitles"
#define JOINED_FILE_KEY				@"Joined File"

@implementation NSString (episodeSorting)

/*!
 * @brief Comparison for episode names
 *
 * @param other The other string to compare
 * @return The comparison result of the compare
 */
- (NSComparisonResult) directoryNameCompare:(NSString *)other
{
	NSString *myShortenedName=nil ;
	NSString *otherShortenedName=nil ;
	/* Make sure we get titles leading with "A" & "The" where the belong */
	if([[self lowercaseString] hasPrefix:@"a "] && [self length]>2)
		myShortenedName=[self substringFromIndex:2];
	else if([[self lowercaseString] hasPrefix:@"the "] && [self length]>4)
		myShortenedName=[self substringFromIndex:4];
	if([[other lowercaseString] hasPrefix:@"a "]&& [other length]>2)
		otherShortenedName=[other substringFromIndex:2];
	else if([[other lowercaseString] hasPrefix:@"the "] && [other length]>4)
		otherShortenedName=[other substringFromIndex:4];
	
	if(myShortenedName==nil)
		myShortenedName=self;
	if(otherShortenedName==nil)
		otherShortenedName=other;
	
	return [myShortenedName	compare:otherShortenedName options:NSCaseInsensitiveSearch | NSNumericSearch];
}
@end

@interface SapphireDirectoryMetaData (private)
- (void)reloadDirectoryContents;
- (SapphireFileMetaData *)cachedMetaDataForFile:(NSString *)file;
- (void)invokeRecursivelyOnFiles:(NSInvocation *)fileInv withPredicate:(SapphirePredicate *)predicate;
@end

static NSSet *coverArtExtentions = nil;
NSString *collectionArtPath = nil;

NSString *searchCoverArtExtForPath(NSString *path)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *directory = [path stringByDeletingLastPathComponent];
	NSArray *files = [fm directoryContentsAtPath:directory];
	NSString *lastComp = [path lastPathComponent];
	/*Search all files*/
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		NSString *ext = [file pathExtension];
		if([ext length] && 
		   [coverArtExtentions containsObject:ext] && 
		   [lastComp isEqualToString:[file stringByDeletingPathExtension]])
			return [directory stringByAppendingPathComponent:file];
	}
	/*Didn't find one*/
	return nil;
}

@implementation SapphireMetaData

// Static set of file extensions to filter
static NSSet *videoExtensions = nil;
static NSSet *audioExtensions = nil;
static NSSet *allExtensions = nil;

+(void)load
{
	videoExtensions = [[NSSet alloc] initWithObjects:
		@"avi", @"divx", @"xvid",
		@"mov",
		@"mpg", @"mpeg", @"m2v", @"ts",
		@"wmv", @"asx", @"asf",
		@"mkv",
		@"flv",
		@"mp4", @"m4v",
		@"3gp",
		@"pls",
		@"avc",
		@"ogm",
		@"dv",
		@"fli",
		nil];
	audioExtensions = [[NSSet alloc] initWithObjects:
		@"m4b", @"m4a",
		@"mp3", @"mp2",
		@"wma",
		@"wav",
		@"aif", @"aiff",
		@"flac",
		@"alac",
		@"m3u",
		@"ac3",
		nil];
	NSMutableSet *mutSet = [videoExtensions mutableCopy];
	[mutSet unionSet:audioExtensions];
	allExtensions = [[NSSet alloc] initWithSet:mutSet];
	[mutSet release];

	/*Initialize the set of cover art extensions*/
	coverArtExtentions = [[NSSet alloc] initWithObjects:
						  @"jpg",
						  @"jpeg",
						  @"tif",
						  @"tiff",
						  @"png",
						  @"gif",
						  nil];
	collectionArtPath=[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Collection Art"] retain];
}

+ (NSSet *)videoExtensions
{
	return videoExtensions;
}

+ (NSSet *)audioExtensions
{
	return audioExtensions;
}

+ (NSString *)collectionArtPath
{
	return collectionArtPath;
}

- (id)initWithDictionary:(NSMutableDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super init];
	if(!self)
		return nil;
	
	/*Create the mutable dictionary*/
	if(dict == nil)
		metaData = [NSMutableDictionary new];
	else
		metaData = [dict retain];
	path = [myPath retain];
	parent = myParent;
	
	return self;
}

- (void)dealloc
{
	[metaData release];
	[path release];
	[super dealloc];
}

- (void)parentDealloced
{
	parent = nil;
}

- (void)childDictionaryChanged:(SapphireMetaData *)child
{
}

- (void)replaceInfoWithDict:(NSDictionary *)dict
{
	NSMutableDictionary *newDict = [dict mutableCopy];
	[metaData release];
	metaData = newDict;
	[parent childDictionaryChanged:self];
}

/*!
 * @brief Returns the mutable dictionary object containing all the metadata
 *
 * @return The dictionary
 */
- (NSMutableDictionary *)dict
{
	return metaData;
}

- (NSString *)path
{
	return path;
}

- (id <SapphireMetaDataDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate
{
	delegate = newDelegate;
}

- (void)writeMetaData
{
	[parent writeMetaData];
}

- (SapphireMetaDataCollection *)collection
{
	return nil;
}

- (BOOL)hasVIDEO_TS:(NSString *)fullPath
{
	BOOL isDir = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"VIDEO_TS"] isDirectory:&isDir] && isDir)
		return YES;
	return NO;
}

- (BOOL)isDirectory:(NSString *)fullPath
{
	BOOL isDir = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL exists = [fm fileExistsAtPath:fullPath isDirectory:&isDir];
	if(exists && isDir)
	{
		if([self hasVIDEO_TS:fullPath])
			return NO;
	}
	return exists && isDir;
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order
{
	return nil;
}

@end

@interface SapphireMetaDataCollection (private)
- (SapphireMetaData *)dataForSubPath:(NSString *)absPath inDirectory:(SapphireDirectoryMetaData *)directory;
- (void)linkCollections;
- (void)realWriteMetaData;
@end

@implementation SapphireMetaDataCollection

- (void)insertDictionary:(NSDictionary *)dict atPath:(NSMutableArray *)pathComponents withinDictionary:(NSMutableDictionary *)source
{
	NSString *element = [pathComponents firstObject];
	NSMutableDictionary *dir = [source objectForKey:element];
	if(dir == nil)
	{
		dir = [[NSMutableDictionary alloc] init];
		[source setObject:dir forKey:element];
		[dir release];
	}
	if([pathComponents count] == 1)
	{
		/* insert here */
		[dir setDictionary:dict];
	}
	else
	{
		NSMutableDictionary *dirs = [dir objectForKey:DIRS_KEY];
		if(dirs == nil)
		{
			dirs = [[NSMutableDictionary alloc] init];
			[dir setObject:dirs forKey:DIRS_KEY];
			[dirs release];
		}
		
		[pathComponents removeObjectAtIndex:0];
		[self insertDictionary:dict atPath:pathComponents withinDictionary:dirs];
	}
}

- (int)upgradeFromVersion1
{
	NSString *oldRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
	[metaData removeObjectForKey:META_VERSION_KEY];
	NSMutableDictionary *newRoot = [NSMutableDictionary new];
	NSMutableArray *pathComponents = [[oldRoot pathComponents] mutableCopy];
	[self insertDictionary:metaData atPath:pathComponents withinDictionary:newRoot];
	[pathComponents release];
	metaData = newRoot;
	
	return 3;
}

- (int)finalUpgradeFromVersion1
{
	NSString *oldRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
	[(SapphireDirectoryMetaData *)[self dataForPath:oldRoot] setToImportFromSource:META_TVRAGE_IMPORT_KEY forPredicate:nil];

	return 3;
}

- (int)upgradeFromVersion2
{
	NSString *oldRoot = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
	NSMutableArray *pathComponents = [[oldRoot pathComponents] mutableCopy];
	NSDictionary *info = [metaData objectForKey:oldRoot];
	[self insertDictionary:info atPath:pathComponents withinDictionary:metaData];
	[pathComponents release];
	[metaData removeObjectForKey:oldRoot];
	return 3;
}

- (int)finalUpgradeFromVersion2
{
	return 3;
}

void recurseSetFileClass(NSMutableDictionary *metaData)
{
	if(metaData == nil)
		return;
	
	NSMutableDictionary *dirs = [metaData objectForKey:DIRS_KEY];
	if(dirs != nil)
	{
		NSEnumerator *dirEnum = [dirs keyEnumerator];
		NSString *dir = nil;
		while((dir = [dirEnum nextObject]) != nil)
			recurseSetFileClass([dirs objectForKey:dir]);		
	}
	
	NSMutableDictionary *files = [metaData objectForKey:FILES_KEY];
	if(files == nil)
		return;
	
	NSEnumerator *fileEnum = [files keyEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		NSMutableDictionary *fileDict = [files objectForKey:file];
		int epNum = [[[fileDict objectForKey:META_TVRAGE_IMPORT_KEY] objectForKey:META_EPISODE_NUMBER_KEY] intValue];
		FileClass fileCls = [[fileDict objectForKey:FILE_CLASS_KEY] intValue];
		if(epNum != 0 && fileCls == FILE_CLASS_UNKNOWN)
			[fileDict setObject:[NSNumber numberWithInt:FILE_CLASS_TV_SHOW] forKey:FILE_CLASS_KEY];
	}
}

- (int)upgradeFromVersion3
{
	recurseSetFileClass([metaData objectForKey:@"/"]);
	return 4;
}

- (int)finalUpgradeFromVersion3
{
	return 4;
}

- (id)initWithFile:(NSString *)dictionary
{
	/*Read the metadata*/
	NSData *fileData = [NSData dataWithContentsOfFile:dictionary];
	NSString *error = nil;
	NSMutableDictionary *mainDict = [NSPropertyListSerialization propertyListFromData:fileData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:&error];
	[error release];
	if(mainDict == nil)
		mainDict = [NSMutableDictionary dictionary];
	self = [super initWithDictionary:mainDict parent:nil path:nil];
	if(!self)
		return nil;
	
	dictionaryPath = [dictionary retain];
	/*Version upgrade*/
	int version = [[metaData objectForKey:META_VERSION_KEY] intValue];
	int oldVersion = version;

	if(version < META_COLLECTION_VERSION)
	{
		if(version < 2)
			version = [self upgradeFromVersion1];
		if(version < 3)
			version = [self upgradeFromVersion2];
		if(version < 4)
			version = [self upgradeFromVersion3];
	}
	/*version it*/
	[metaData setObject:[NSNumber numberWithInt:META_COLLECTION_VERSION] forKey:META_VERSION_KEY];

	NSMutableDictionary *collectionOptions = [metaData objectForKey:META_COLLECTION_OPTIONS];
	if(collectionOptions == nil)
	{
		collectionOptions = [[NSMutableDictionary alloc] init];
		[metaData setObject:collectionOptions forKey:META_COLLECTION_OPTIONS];
		[collectionOptions release];
	}
	
	skipCollection = [[collectionOptions objectForKey:META_COLLECTION_SKIP_SCAN] retain];
	if(skipCollection == nil)
	{
		skipCollection = [[NSMutableDictionary alloc] init];
		[collectionOptions setObject:skipCollection forKey:META_COLLECTION_SKIP_SCAN];
	}
	
	hideCollection = [[collectionOptions objectForKey:META_COLLECTION_HIDE] retain];
	if(hideCollection == nil)
	{
		hideCollection = [[NSMutableDictionary alloc] init];
		[collectionOptions setObject:hideCollection forKey:META_COLLECTION_HIDE];
	}
	
	collectionDirs = [[collectionOptions objectForKey:META_COLLECTION_DIRS] retain];
	if(collectionDirs == nil)
	{
		collectionDirs = [[NSMutableArray alloc] init];
		[collectionOptions setObject:collectionDirs forKey:META_COLLECTION_DIRS];
	}
	
	directories = [[NSMutableDictionary alloc] init];
	
	/* Hide and skip the / collection by default */
	if([hideCollection objectForKey:@"/"] == nil)
		[self setHide:YES forCollection:@"/"];
	if([skipCollection objectForKey:@"/"] == nil)
		[self setSkip:YES forCollection:@"/"];
	SapphireDirectoryMetaData *slash = [[SapphireDirectoryMetaData alloc] initWithDictionary:[metaData objectForKey:@"/"] parent:self path:@"/"];
	[metaData setObject:[slash dict] forKey:@"/"];
	[directories setObject:slash forKey:@"/"];
	[slash release];
	[self linkCollections];
	if(oldVersion < META_COLLECTION_VERSION)
	{
		if(oldVersion < 2)
			oldVersion = [self finalUpgradeFromVersion1];
		if(oldVersion < 3)
			oldVersion = [self finalUpgradeFromVersion2];
		if(oldVersion < 4)
			oldVersion = [self finalUpgradeFromVersion3];
	}
	[self writeMetaData];
	
	return self;
}

- (void)linkCollections
{
	NSMutableArray *collections = [[self collectionDirectories] mutableCopy];
	[collections sortUsingSelector:@selector(compare:)];
	NSEnumerator *collectionEnum = [collections objectEnumerator];
	NSString *dir = nil;
	SapphireDirectoryMetaData *highestMetaData = [directories objectForKey:[collectionEnum nextObject]];
	while((dir = [collectionEnum nextObject]) != nil)
	{
		[directories setObject:[self dataForSubPath:dir inDirectory:highestMetaData] forKey:dir];
	}
	
	[collections release];
}

- (void)dealloc
{
	[dictionaryPath release];
	[skipCollection release];
	[hideCollection release];
	[collectionDirs release];
	if(writeTimer != nil)
	{
		[writeTimer invalidate];
		[self realWriteMetaData];
	}
	[[directories objectForKey:@"/"] parentDealloced];
	[directories release];
	[super dealloc];
}

- (SapphireMetaData *)dataForSubPath:(NSString *)absPath inDirectory:(SapphireDirectoryMetaData *)directory
{
	SapphireMetaData *ret = directory;
	NSString *dirPath = [directory path];
	NSMutableArray *pathComp = [[absPath pathComponents] mutableCopy];
	int prefixCount = [[dirPath pathComponents] count];
	[pathComp removeObjectsInRange:NSMakeRange(0, prefixCount)];
	
	if([pathComp count])
	{
		NSString *subPath = [NSString pathWithComponents:pathComp];
		ret = [directory metaDataForSubPath:subPath];
	}
	[pathComp release];
	return ret;
}

- (SapphireMetaData *)dataForPath:(NSString *)absPath
{
	SapphireDirectoryMetaData *directory = [directories objectForKey:@"/"];
	return [self dataForSubPath:absPath inDirectory:directory];
}

- (SapphireMetaData *)dataForPath:(NSString *)absPath withData:(NSDictionary *)data
{
	SapphireMetaData *ret = [self dataForPath:absPath];
	
	if([data count] != 0)
		[ret replaceInfoWithDict:data];
	
	return ret;
}

- (SapphireDirectoryMetaData *)directoryForPath:(NSString *)absPath
{
	SapphireMetaData *ret = [self dataForPath:absPath];
	if([ret isKindOfClass:[SapphireDirectoryMetaData class]])
		return (SapphireDirectoryMetaData *)ret;
	return nil;
}

- (NSArray *)collectionDirectories
{
	NSMutableSet *colSet = [NSMutableSet set];
    struct statfs *mntbufp;

    int i, mountCount = getmntinfo(&mntbufp, MNT_NOWAIT);
	for(i=0; i<mountCount; i++)
	{
		if(!strcmp(mntbufp[i].f_fstypename, "autofs"))
			continue;
		if(!strcmp(mntbufp[i].f_fstypename, "volfs"))
			continue;
		if(!strcmp(mntbufp[i].f_mntonname, "/dev"))
			continue;
		[colSet addObject:[NSString stringWithCString:mntbufp[i].f_mntonname]];
	}
	[colSet removeObject:@"/mnt"];
	[colSet removeObject:@"/CIFS"];
	[colSet removeObject:NSHomeDirectory()];
	NSString *homeMoviesPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
	if([[NSFileManager defaultManager] fileExistsAtPath:homeMoviesPath])
		[colSet addObject:homeMoviesPath];
	[colSet addObjectsFromArray:collectionDirs];
	NSMutableArray *ret = [[colSet allObjects] mutableCopy];
	[ret sortUsingSelector:@selector(compare:)];
	return [ret autorelease];
}

/*Makes a director at a path, including its parents*/
static void makeParentDir(NSFileManager *manager, NSString *dir)
{
	NSString *parent = [dir stringByDeletingLastPathComponent];
	
	/*See if parent exists, and make if not*/
	BOOL isDir;
	if(![manager fileExistsAtPath:parent isDirectory:&isDir])
		makeParentDir(manager, parent);
	else if(!isDir)
		/*Can't work with this*/
		return;
	
	/*Create our dir*/
	[manager createDirectoryAtPath:dir attributes:nil];
}

- (void)writeMetaData
{
	[writeTimer invalidate];
	writeTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(realWriteMetaData) userInfo:nil repeats:NO];
}

- (void)realWriteMetaData
{
	writeTimer = nil;
	makeParentDir([NSFileManager defaultManager], [dictionaryPath stringByDeletingLastPathComponent]);
	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:metaData format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
	if(error == nil)
		[data writeToFile:dictionaryPath atomically:YES];
	else
		[error release];
}

- (SapphireMetaDataCollection *)collection
{
	return self;
}

- (BOOL)hideCollection:(NSString *)collection
{
	return [[hideCollection objectForKey:collection] boolValue];
}

- (void)setHide:(BOOL)hide forCollection:(NSString *)collection
{
	[hideCollection setObject:[NSNumber numberWithBool:hide] forKey:collection];
	[self writeMetaData];
}

- (BOOL)skipCollection:(NSString *)collection
{
	return [[skipCollection objectForKey:collection] boolValue];
}

- (void)setSkip:(BOOL)skip forCollection:(NSString *)collection
{
	[skipCollection setObject:[NSNumber numberWithBool:skip] forKey:collection];
	[self writeMetaData];
}

- (NSSet *)skipDirectories
{
	NSMutableSet *ret = [NSMutableSet set];
	NSEnumerator *colEnum = [skipCollection keyEnumerator];
	NSString *collection;
	while((collection = [colEnum nextObject]) != nil)
	{
		if([self skipCollection:collection])
			[ret addObject:collection];
	}
	
	return ret;
}

- (void)addCollectionDirectory:(NSString *)dir
{
	if(![collectionDirs containsObject:dir])
		[collectionDirs addObject:dir];
}

- (BOOL)isCollectionDirectory:(NSString *)dir
{
	return [collectionDirs containsObject:dir];
}

- (void)removeCollectionDirectory:(NSString *)dir
{
	[collectionDirs removeObject:dir];
}

@end

@implementation SapphireDirectoryMetaData

- (void)createSubDicts
{
	/*Get the file listing*/
	metaFiles = [metaData objectForKey:FILES_KEY];
	if(metaFiles == nil)
	{
		metaFiles = [NSMutableDictionary new];
		[metaData setObject:metaFiles forKey:FILES_KEY];
		[metaFiles release];
	}
	
	/*Get the directory listing*/
	metaDirs = [metaData objectForKey:DIRS_KEY];
	if(metaDirs == nil)
	{
		metaDirs = [NSMutableDictionary new];
		[metaData setObject:metaDirs forKey:DIRS_KEY];
		[metaDirs release];	
	}
}

- (id)initWithDictionary:(NSMutableDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:dict parent:myParent path:myPath];
	if(!self)
		return nil;
	
	[self createSubDicts];
	directories = [[NSMutableArray alloc] init];
	files = [[NSMutableArray alloc] init];
	
	/*Setup the cache*/
	cachedMetaDirs = [NSMutableDictionary new];
	cachedMetaFiles = [NSMutableDictionary new];
	
	return self;
}

- (void)postAllFilesRemoved
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSEnumerator *filesEnum = [cachedMetaFiles objectEnumerator];
	SapphireFileMetaData *meta = nil;
	while((meta = [filesEnum nextObject]) != nil)
		[nc postNotificationName:META_DATA_FILE_REMOVED_NOTIFICATION object:meta];	
}

- (void)dealloc
{
	[loadTimer invalidate];
	[self postAllFilesRemoved];
	[importArray release];
	[[cachedMetaDirs allValues] makeObjectsPerformSelector:@selector(parentDealloced)];	
	[cachedMetaDirs release];
	[[cachedMetaFiles allValues] makeObjectsPerformSelector:@selector(parentDealloced)];	
	[cachedMetaFiles release];
	[files release];
	[directories release];
	[super dealloc];
}

- (void)childDictionaryChanged:(SapphireMetaData *)child
{
	NSMutableDictionary *refDict = nil;
	if([child isKindOfClass:[SapphireDirectoryMetaData class]])
		refDict = metaDirs;
	else if([child isKindOfClass:[SapphireFileMetaData class]])
		refDict = metaFiles;
	else
		return;
	
	NSString *name = [[child path] lastPathComponent];
	[refDict removeObjectForKey:name];
	[refDict setObject:[child dict] forKey:name];
}

- (void)replaceInfoWithDict:(NSDictionary *)dict
{
	[self postAllFilesRemoved];
	[super replaceInfoWithDict:dict];
	[self createSubDicts];
	[directories removeAllObjects];
	[files removeAllObjects];
	[cachedMetaDirs removeAllObjects];
	[cachedMetaFiles removeAllObjects];
	[importArray release];
	importArray = nil;
	importing = NO;
	scannedDirectory = NO;
}

- (void)reloadDirectoryContents
{
	/*Flush saved information*/
	[files removeAllObjects];
	[directories removeAllObjects];
	NSMutableArray *fileMetas = [NSMutableArray array];
	
	/*Get content*/
	NSArray *names = [[NSFileManager defaultManager] directoryContentsAtPath:path];
	
	NSEnumerator *nameEnum = [names objectEnumerator];
	NSString *name = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	while((name = [nameEnum nextObject]) != nil)
	{
		/*Skip hidden files*/
		if([name hasPrefix:@"."])
			continue;
		/*Skip the Cover Art directory*/
		if([name isEqualToString:@"Cover Art"])
			continue;
		NSString *filePath = [path stringByAppendingPathComponent:name];
		SapphireMetaData *resolvedObject = nil;
		NSDictionary *attributes = [fm fileAttributesAtPath:filePath traverseLink:NO];
		if([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink])
		{
			/* Symbolic link, handle with care */
			NSMutableDictionary *refDict = nil;
			NSString *resolvedPath = [filePath stringByResolvingSymlinksInPath];

			if([self isDirectory:resolvedPath])
				refDict = metaDirs;
			else
				refDict = metaFiles;
			resolvedObject = [[self collection] dataForPath:resolvedPath withData:[refDict objectForKey:name]];
			if(resolvedObject == nil)
				continue;
			
			if([refDict objectForKey:name] != nil)
			{
				[refDict removeObjectForKey:name];
				[self writeMetaData];
			}
		}
		/*Only accept if it is a directory or right extension*/
		NSString *extension = [name pathExtension];
		if([self isDirectory:filePath])
		{
			[directories addObject:name];
			if(resolvedObject != nil)
				[cachedMetaDirs setObject:resolvedObject forKey:name];
		}
		else if([allExtensions containsObject:[extension lowercaseString]] || [self hasVIDEO_TS:filePath])
		{
			if(resolvedObject != nil)
				[cachedMetaFiles setObject:resolvedObject forKey:name];
			else
				resolvedObject = [self metaDataForFile:name];
			[fileMetas addObject:resolvedObject];
		}
	}
	/*Sort them*/
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[fileMetas sortUsingSelector:@selector(episodeCompare:)];
	/*Create the file listing just containing names*/
	nameEnum = [fileMetas objectEnumerator];
	SapphireFileMetaData *fileMeta = nil;
	while((fileMeta = [nameEnum nextObject]) != nil)
	{
		NSString *joinedPath = [fileMeta joinedFile];
		if([fm fileExistsAtPath:joinedPath])
			continue;
		[files addObject:[[fileMeta path] lastPathComponent]];		
	}
	/*Check to see if any data is out of date*/
	[self updateMetaData];
	if([self pruneMetaData] || [importArray count])
		[self writeMetaData];
	/*Mark directory as scanned*/
	scannedDirectory = YES;
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
	
	if(parents != 0 && [parent isKindOfClass:[SapphireDirectoryMetaData class]])
		return [(SapphireDirectoryMetaData *)parent coverArtPathUpToParents:parents-1];
	return nil;
}

- (NSString *)coverArtPath
{
	return [self coverArtPathUpToParents:2];
}

- (NSArray *)files
{
	return files;
}

- (NSArray *)directories
{
	return directories;
}

/*!
 * @brief Returns whether the directory has any files which match the predicate
 *
 * @param predicate The predictate to match
 * @return YES if a file exists, NO otherwise
 */
- (BOOL)hasPredicatedFiles:(SapphirePredicate *)predicate
{
	/*Get file listing*/
	NSArray *filesToScan = files;
	if(!scannedDirectory)
		/*Don't do a scan, just returned cached data*/
		filesToScan = [metaFiles allKeys];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		/*Check predicate*/
		BOOL include = NO;
		SapphireFileMetaData *meta = [self cachedMetaDataForFile:file];
		if(meta != nil)
			include = [predicate accept:[meta path] meta:meta];
		else
			include = [predicate accept:[path stringByAppendingPathComponent:file] meta:nil];
		if(include)
			/*Predicate matched*/
			return YES;
	}
	/*No matches found*/
	return NO;
}

/*!
 * @brief Returns whether the directory has any directories which match the predicate
 *
 * @param predicate The predicate to match
 * @return YES if a file exists, NO otherwise
 */
- (BOOL)hasPredicatedDirectories:(SapphirePredicate *)predicate
{
	/*Get directory listing*/
	NSArray *directoriesToScan = directories;
	if(!scannedDirectory)
		/*Don't do a scan, just return cached data*/
		directoriesToScan = [metaDirs allKeys];
	NSEnumerator *directoryEnum = [directoriesToScan objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		/*Check predicate*/
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		/*If we are not fast, go ahead and scan*/
		if(![[SapphireSettings sharedSettings] fastSwitching])
			[meta reloadDirectoryContents];
		
		/*If the dir has any files or any dirs, it matches*/
		if([meta hasPredicatedFiles:predicate] || [meta hasPredicatedDirectories:predicate])
			return YES;
	}
	/*No matches found*/
	return NO;
}

- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate
{
	/*Get file listing*/
	NSMutableArray *ret = [NSMutableArray array];
	NSArray *filesToScan = files;
	if(!scannedDirectory)
		/*Don't do a scan, just return cached data*/
		filesToScan = [metaFiles allKeys];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		/*Check predicate*/
		BOOL include = NO;
		SapphireFileMetaData *meta = [self cachedMetaDataForFile:file];
		if(meta != nil)
			include = [predicate accept:[meta path] meta:meta];
		else
			include = [predicate accept:[path stringByAppendingPathComponent:file] meta:nil];
		if(include)
			/*Predicate matched, add to list*/
			[ret addObject:file];
	}
	/*Return the list*/
	return ret;
}

- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate
{
	/*Get directory listing*/
	NSMutableArray *ret = [NSMutableArray array];
	NSArray *directoriesToScan = directories;
	if(!scannedDirectory)
		/*Don't do a scan, just return cached data*/
		directoriesToScan = [metaDirs allKeys];
	NSEnumerator *directoryEnum = [directoriesToScan objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		/*Check predicate*/
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		if(![[SapphireSettings sharedSettings] fastSwitching])
			[meta reloadDirectoryContents];

		/*If dir has any files or any dirs, it matches*/
		if([meta hasPredicatedFiles:predicate] || [meta hasPredicatedDirectories:predicate])
			/*Add to list*/
			[ret addObject:directory];
	}
	/*Return the list*/
	return ret;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	/*Check cache*/
	SapphireFileMetaData *ret = [cachedMetaFiles objectForKey:file];
	if(ret == nil)
	{
		/*Create it*/
		NSMutableDictionary *dict = [metaFiles objectForKey:file];
		ret = [[SapphireFileMetaData alloc] initWithDictionary:dict parent:self path:[path stringByAppendingPathComponent:file]];
		if(dict == nil)
			[metaFiles setObject:[ret dict] forKey:file];
		/*Add to cache*/
		[cachedMetaFiles setObject:ret forKey:file];
		[ret autorelease];
	}
	/*Return it*/
	return ret;
}

- (SapphireFileMetaData *)cachedMetaDataForFile:(NSString *)file
{
	if([metaFiles objectForKey:file] != nil)
		return [self metaDataForFile:file];
	else
		return [cachedMetaFiles objectForKey:file];
}

- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)dir
{
	/*Check cache*/
	SapphireDirectoryMetaData *ret = [cachedMetaDirs objectForKey:dir];
	if(ret == nil)
	{
		/*Create it*/
		NSMutableDictionary *dict = [metaDirs objectForKey:dir];
		ret = [[SapphireDirectoryMetaData alloc] initWithDictionary:dict parent:self path:[path stringByAppendingPathComponent:dir]];
		if(dict == nil)
			[metaDirs setObject:[ret dict] forKey:dir];
		/*Add to cache*/
		[cachedMetaDirs setObject:ret forKey:dir];
		[ret autorelease];		
	}
	/*Return it*/
	return ret;
}

- (BOOL)pruneMetaData
{
	BOOL ret = NO;
	/*Check for empty dir.  May be a missing mount, so skip*/
	if([files count] + [directories count] == 0)
		return ret;
	/*Get missing file list*/
	NSSet *existingSet = [NSSet setWithArray:files];
	NSArray *metaArray = [metaFiles allKeys];
	NSMutableSet *pruneSet = [NSMutableSet setWithArray:metaArray];
	
	[pruneSet minusSet:existingSet];
	/*Prune each item*/
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		NSFileManager *fm = [NSFileManager defaultManager];
		while((pruneKey = [pruneEnum nextObject]) != nil)
		{
			NSString *filePath = [path stringByAppendingPathComponent:pruneKey];
			NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO];
			/*If it is a broken link, skip*/
			if([[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink])
				continue;
			SapphireFileMetaData *meta = [cachedMetaFiles objectForKey:pruneKey];
			/*If it is a joined File, skip*/
			NSString *joinedPath = [meta joinedFile];
			if([fm fileExistsAtPath:joinedPath])
				continue;
			/*Remove and mark as we did an update*/
			if(meta != nil)
				[[NSNotificationCenter defaultCenter] postNotificationName:META_DATA_FILE_REMOVED_NOTIFICATION object:meta];
			[metaFiles removeObjectForKey:pruneKey];
			[cachedMetaFiles removeObjectForKey:pruneKey];
			ret = YES;
		}
	}
	
	/*Get missing directory list*/
	existingSet = [NSSet setWithArray:directories];
	metaArray = [metaDirs allKeys];
	pruneSet = [NSMutableSet setWithArray:metaArray];
	
	[pruneSet minusSet:existingSet];
	/*Prune each item*/
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		while((pruneKey = [pruneEnum nextObject]) != nil)
		{
			NSString *filePath = [path stringByAppendingPathComponent:pruneKey];
			NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO];
			/*If it is a broken link, skip*/
			if(![[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink])
			{
				/*Remove and mark as we did an update*/
				[metaDirs removeObjectForKey:pruneKey];
				[cachedMetaDirs removeObjectForKey:pruneKey];
				ret = YES;
			}
		}
	}
	
	/*Return whether we did a prune*/
	return ret;
}

- (BOOL)updateMetaData
{
	/*Look at each file*/
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *fileName = nil;
	importArray = [[NSMutableArray alloc] init];
	while((fileName = [fileEnum nextObject]) != nil)
	{
		/*If the file exists, and no metadata, add to update list*/
		NSDictionary *fileMeta = [metaFiles objectForKey:fileName];
		if(fileMeta == nil)
		{
			[self metaDataForFile:fileName];
			[importArray addObject:fileName];
		}
		else
		{
			/*If file has been modified since last import, add to update list*/
			SapphireFileMetaData *file = [self metaDataForFile:fileName];
			if([file needsUpdating])
				[importArray addObject:fileName];
		}
	}
	/*We didn't do any updates yet, so return NO*/
	return NO;
}

/*function to process a single file*/
- (void)processNextFile
{
	if(![importArray count])
		return;
	NSString *file = [importArray objectAtIndex:0];
	
	/*Get the file and update it*/
	importing |= 2;
	[[SapphireImportHelper sharedHelper] importAllData:[self metaDataForFile:file] inform:self];
}

- (oneway void)informComplete:(BOOL)updated
{
	/*Write the file info out and tell delegate we updated*/
	[self writeMetaData];
	NSString *file = [importArray objectAtIndex:0];
	[delegate updateCompleteForFile:file];
	
	/*Remove from list and redo timer*/
	[importArray removeObjectAtIndex:0];
	if(importing & 1)
		[self processNextFile];
	else
		importing = 0;
}

- (void)cancelImport
{
	importing &= ~1;
}

- (void)resumeImport
{
	importing |= 1;
	if(!(importing & 2))
		[self processNextFile];
}

- (SapphireMetaData *)metaDataForSubPath:(NSString *)subPath
{
	/*Get next level to examine*/
	NSArray *components = [subPath pathComponents];
	if(![components count])
		/*Must mean ourself*/
		return self;
	NSString *file = [components objectAtIndex:0];
	
	NSString *fullPath = [path stringByAppendingPathComponent:file];
	/*Go to the next dir*/
	if([self isDirectory:fullPath])
	{
		NSMutableArray *newComp = [components mutableCopy];
		[newComp removeObjectAtIndex:0];
		[newComp autorelease];
		SapphireDirectoryMetaData *nextLevel = [self metaDataForDirectory:file];
		return [nextLevel metaDataForSubPath:[NSString pathWithComponents:newComp]];
	}
	/*If it matches a file, and more path components, this doesn't exist, return nil*/
	else if([components count] > 1 || ![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
		return nil;
	/*Return our file's metadata*/
	return [self metaDataForFile:file];
}

- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
	/*Scan dir and create scanner*/
	[self reloadDirectoryContents];
	SapphireMetaDataScanner *scanner = [[SapphireMetaDataScanner alloc] initWithDirectoryMetaData:self delegate:subDelegate];
	/*Add ourselves to not rescan*/
	[skip addObject:[self path]];
	[scanner setSkipDirectories:skip];
	/*We want results*/
	[scanner setGivesResults:YES];
	[scanner release];
}

- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
	/*Scan dir and create scanner*/
	[self reloadDirectoryContents];
	SapphireMetaDataScanner *scanner = [[SapphireMetaDataScanner alloc] initWithDirectoryMetaData:self delegate:subDelegate];
	/*Add ourselves to not rescan*/
	[skip addObject:[self path]];
	[scanner setSkipDirectories:skip];
	/*We don't want results*/
	[scanner setGivesResults:NO];
	[scanner release];
}

- (void)internalLoadMetaData:(NSMutableArray *)queue
{
	[loadTimer invalidate];
	loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(loadMetaDataTimer:) userInfo:queue repeats:NO];
}

- (void)loadMetaData
{
	[[NSNotificationCenter defaultCenter] postNotificationName:META_DATA_FILE_INFO_STARTED_LOADING object:self];
	[self internalLoadMetaData:[NSMutableArray arrayWithObject:self]];
}

- (void)loadMyMetaData:(NSMutableArray *)queue
{
	NSArray *keys = [NSArray arrayWithArray:[metaFiles allKeys]];
	NSEnumerator *fileEnum = [keys objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		[queue insertObject:file atIndex:0];
	}
	keys = [NSArray arrayWithArray:[metaDirs allKeys]];
	NSEnumerator *dirEnum = [keys objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *nextMeta = [self metaDataForDirectory:dir];
		if(nextMeta == nil)
			continue;
		[queue addObject:nextMeta];
	}
}

- (void)loadMetaDataTimer:(NSTimer *)timer
{
	loadTimer = nil;
	NSMutableArray *queue = [timer userInfo];
	id nextObj = [[queue objectAtIndex:0] retain];
	[queue removeObjectAtIndex:0];
	if([nextObj isKindOfClass:[SapphireDirectoryMetaData class]])
		[self loadMyMetaData:queue];
	else
		[self metaDataForFile:(NSString *)nextObj];
	[nextObj release];
	if([queue count])
	{
		nextObj = [queue objectAtIndex:0];
		if([nextObj isKindOfClass:[SapphireDirectoryMetaData class]])
			[(SapphireDirectoryMetaData *)nextObj internalLoadMetaData:queue];
		else
			loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(loadMetaDataTimer:) userInfo:queue repeats:NO];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:META_DATA_FILE_INFO_FINISHED_LOADING object:self];
	}
}

/*Quick function to setup file and directory lists for other functions*/
- (void)setupFiles:(NSArray * *)filesToScan andDirectories:(NSArray * *)directoriesToScan arraysForPredicate:(SapphirePredicate *)predicate
{
	if(predicate)
	{
		*filesToScan = [self predicatedFiles:predicate];
		*directoriesToScan = [self predicatedDirectories:predicate];
	}
	else if(!scannedDirectory)
	{
		/*Haven't scanned the directory yet, so use cached*/
		*filesToScan = [metaFiles allKeys];
		*directoriesToScan = [metaDirs allKeys];
	}
}

/*Function to check a result in a subtree*/
- (BOOL)checkResult:(BOOL)result recursivelyOnFiles:(NSInvocation *)fileInv forPredicate:(SapphirePredicate *)predicate
{
	/*Get file and directory list*/
	NSArray *filesToScan = files;
	NSArray *directoriesToScan = directories;
	[self setupFiles:&filesToScan andDirectories:&directoriesToScan arraysForPredicate:predicate];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	/*Check for a file which matches result*/
	while((file = [fileEnum nextObject]) != nil)
	{
		[fileInv invokeWithTarget:[self metaDataForFile:file]];
		BOOL thisResult = NO;
		[fileInv getReturnValue:&thisResult];
		if(thisResult == result)
			/*Found, return it*/
			return result;
	}

	/*Check the directories now*/
	NSEnumerator *dirEnum = [directoriesToScan objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		if([[self metaDataForDirectory:dir] checkResult:result recursivelyOnFiles:fileInv forPredicate:predicate] == result)
			/*Found, return it*/
			return result;
	
	/*Not found*/
	return !result;
}

/*Function to invoke a command on all files in a subtree*/
- (void)invokeRecursivelyOnFiles:(NSInvocation *)fileInv withPredicate:(SapphirePredicate *)predicate
{
	/*Get all files and dirs*/
	[self reloadDirectoryContents];
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	/*Invoke same thing on directories*/
	while((dir = [dirEnum nextObject]) != nil)
		[[self metaDataForDirectory:dir] invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	/*Invoke on the files*/
	while((file = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *fileMeta = [self metaDataForFile:file];
		/*Only if they match a predicate, or if there is not predicate*/
		if(!predicate || [predicate accept:[fileMeta path] meta:fileMeta])
			[fileInv invokeWithTarget:fileMeta];
	}
}

- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(watched);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	return [self checkResult:NO recursivelyOnFiles:fileInv forPredicate:predicate];
}

- (void)setWatched:(BOOL)watched forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setWatched:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&watched atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(favorite);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	return [self checkResult:YES recursivelyOnFiles:fileInv forPredicate:predicate];	
}

- (void)setFavorite:(BOOL)favorite forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setFavorite:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&favorite atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (void)setToImportFromSource:(NSString *)source forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setToImportFromSource:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&source atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (void)setFileClass:(FileClass)fileClass forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setFileClass:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&fileClass atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (void)clearMetaDataForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(clearMetaData);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (SapphireMetaDataCollection *)collection
{
	if(collection == nil)
		collection = [parent collection];
	
	return collection;
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;
{
	if(order != nil)
		*order = nil;
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[path lastPathComponent], META_TITLE_KEY,
		nil];
}

@end

@interface SapphireFileMetaData (private)
- (void)constructCombinedData;
- (void)combinedDataChanged;
@end

@implementation SapphireFileMetaData

/*Makes metadata easier to deal with in terms of display*/
static NSDictionary *metaDataSubstitutions = nil;
static NSSet *displayedMetaData = nil;
static NSArray *displayedMetaDataOrder = nil;

+ (void) initialize
{
	metaDataSubstitutions = [[NSDictionary alloc] initWithObjectsAndKeys:
		//These substitute keys in the metadata to nicer display keys
		BRLocalizedString(@"Video", @"Video format in metadata display"), VIDEO_DESC_KEY,
		BRLocalizedString(@"Audio", @"Audio format in metadata display"), AUDIO_DESC_KEY,
		BRLocalizedString(META_EPISODE_AND_SEASON_KEY, @"Season / Epsiode in metadata display"), META_EPISODE_AND_SEASON_KEY,
		BRLocalizedString(META_SEASON_NUMBER_KEY, @"Season in metadata display"), META_SEASON_NUMBER_KEY,
		BRLocalizedString(META_EPISODE_NUMBER_KEY, @"Epsiode in metadata display"), META_EPISODE_NUMBER_KEY,
		BRLocalizedString(SIZE_KEY, @"filesize in metadata display"), SIZE_KEY,
		BRLocalizedString(DURATION_KEY, @"file duration in metadata display"), DURATION_KEY,
		nil];
	//These keys are before the above translation
	displayedMetaDataOrder = [NSArray arrayWithObjects:
		//These are not shown in the list
		META_MOVIE_MPAA_RATING_KEY,
		META_RATING_KEY,
		META_DESCRIPTION_KEY,
		META_MOVIE_PLOT_KEY,
		META_COPYRIGHT_KEY,
		META_TITLE_KEY,
		META_MOVIE_TITLE_KEY,
		META_SHOW_AIR_DATE,
		META_MOVIE_WIRTERS_KEY,
		META_MOVIE_RELEASE_DATE_KEY,
		META_MOVIE_IMDB_250_KEY,
		META_MOVIE_IMDB_RATING_KEY,					  
		//These are displayed as line items
		META_MOVIE_DIRECTOR_KEY,
		META_MOVIE_CAST_KEY,
		META_MOVIE_GENRES_KEY,
		META_EPISODE_AND_SEASON_KEY,
		META_SEASON_NUMBER_KEY,
		META_EPISODE_NUMBER_KEY,
		META_MOVIE_IMDB_STATS_KEY,
		SIZE_KEY,
		DURATION_KEY,
		VIDEO_DESC_KEY,
		AUDIO_DESC_KEY,
		SUBTITLES_KEY,
		nil];
	displayedMetaData = [[NSSet alloc] initWithArray:displayedMetaDataOrder];
	
	/*Remove non-displayed data from the displayed order, and use the display keys*/
	int excludedKeys = 12;
	NSMutableArray *modified = [[displayedMetaDataOrder subarrayWithRange:NSMakeRange(excludedKeys, [displayedMetaDataOrder count] - excludedKeys)] mutableCopy];
	
	int i;
	for(i=0; i<[modified count]; i++)
	{
		NSString *newKey = [metaDataSubstitutions objectForKey:[modified objectAtIndex:i]];
		if(newKey != nil)
			[modified replaceObjectAtIndex:i withObject:newKey];
	}
	displayedMetaDataOrder = [[NSArray alloc] initWithArray:modified];
	[modified release];
}

- (void)fileClsUpgrade
{
	if([self fileClass] == FILE_CLASS_UNKNOWN && [self episodeNumber] != 0)
		[self setFileClass:FILE_CLASS_TV_SHOW];
}

- (id)initWithDictionary:(NSMutableDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:dict parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	if([self hasVIDEO_TS:myPath])
		[self setFileContainerType:FILE_CONTAINER_TYPE_VIDEO_TS];
	[[NSNotificationCenter defaultCenter] postNotificationName:META_DATA_FILE_ADDED_NOTIFICATION object:self];
	
	return self;
}

- (void)dealloc
{
	[combinedInfo release];
	[super dealloc];
}

- (void)replaceInfoWithDict:(NSDictionary *)dict
{
	[super replaceInfoWithDict:dict];
	[combinedInfo release];
	combinedInfo = nil;
}

- (NSString *)coverArtPath
{
	/*Find cover art for the current file in the "Cover Art" dir */
	NSString *subPath = [[self path] stringByDeletingPathExtension];
	NSString *fileName = [subPath lastPathComponent];
	NSString * myArtPath=nil;
	if([self fileClass]==FILE_CLASS_TV_SHOW)
		myArtPath=[NSString stringWithFormat:@"%@/@TV/%@/%@/%@",
															[SapphireMetaData collectionArtPath],
															[self showName],
															[NSString stringWithFormat:@"Season %d",[self seasonNumber]],
															fileName];
	if([self fileClass]==FILE_CLASS_MOVIE)
		myArtPath=[NSString stringWithFormat:@"%@/@MOVIES/%@",
															[SapphireMetaData collectionArtPath],
															fileName];
	
	/* Check the Collection Art location */
	NSString *ret=searchCoverArtExtForPath(myArtPath);

	if(ret != nil)
		return ret;
	
	/* Try Legacy Folders with the file */
	ret=searchCoverArtExtForPath([[[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:fileName]);
	
	if(ret != nil)
		return ret;
	
	/*Find cover art for the current file in the current dir*/
	ret = searchCoverArtExtForPath(subPath);
	
	if(ret != nil)
		return ret;

	
	return nil;
}

- (BOOL)needsUpdating
{
	/*Check modified date*/
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
	
	if(props == nil)
		/*No file*/
		return FALSE;
	
	/*Has it been modified since last import?*/
	if(modTime != [self modified] || [[metaData objectForKey:META_VERSION_KEY] intValue] != META_FILE_VERSION)
		return YES;
	return NO;
}

- (oneway void)addFileData:(bycopy NSDictionary *)fileMeta
{
	/*Add the metadata*/
	[metaData addEntriesFromDictionary:fileMeta];
	[self combinedDataChanged];	
}

BOOL updateMetaData(id <SapphireFileMetaDataProtocol> file)
{
	BOOL updated =FALSE;
	if([file needsUpdating])
	{
		/*We did an update*/
		updated=TRUE ;
		NSMutableDictionary *fileMeta = [NSMutableDictionary dictionary];
		NSString *path = [file path];
		
		NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
		/*Set modified, size, and version*/
		[fileMeta setObject:[NSNumber numberWithInt:modTime] forKey:MODIFIED_KEY];
		[fileMeta setObject:[props objectForKey:NSFileSize] forKey:SIZE_KEY];
		[fileMeta setObject:[NSNumber numberWithInt:META_FILE_VERSION] forKey:META_VERSION_KEY];
		
		if([file fileContainerType] == FILE_CONTAINER_TYPE_QT_MOVIE)
		{
			/*Open the movie*/
			NSError *error = nil;
			QTMovie *movie = [QTMovie movieWithFile:path error:&error];
			QTTime duration = [movie duration];
			[fileMeta setObject:[NSNumber numberWithFloat:(float)duration.timeValue/(float)duration.timeScale] forKey:DURATION_KEY];
			NSArray *audioTracks = [movie tracksOfMediaType:@"soun"];
			NSNumber *audioSampleRate = nil;
			if([audioTracks count])
			{
				/*Get the audio track*/
				QTTrack *track = [audioTracks objectAtIndex:0];
				QTMedia *media = [track media];
				if(media != nil)
				{
					/*Get the audio format*/
					Media qtMedia = [media quickTimeMedia];
					Handle sampleDesc = NewHandle(1);
					GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc);
					AudioStreamBasicDescription asbd;
					ByteCount	propSize = 0;
					QTSoundDescriptionGetProperty((SoundDescriptionHandle)sampleDesc, kQTPropertyClass_SoundDescription, kQTSoundDescriptionPropertyID_AudioStreamBasicDescription, sizeof(asbd), &asbd, &propSize);
					
					if(propSize != 0)
					{
						/*Set the format and sample rate*/
						NSNumber *format = [NSNumber numberWithUnsignedInt:asbd.mFormatID];
						[fileMeta setObject:format forKey:AUDIO_FORMAT_KEY];
						audioSampleRate = [NSNumber numberWithDouble:asbd.mSampleRate];
					}
					
					CFStringRef userText = nil;
					propSize = 0;
					QTSoundDescriptionGetProperty((SoundDescriptionHandle)sampleDesc, kQTPropertyClass_SoundDescription, kQTSoundDescriptionPropertyID_UserReadableText, sizeof(userText), &userText, &propSize);
					if(userText != nil)
					{
						/*Set the description*/
						[fileMeta setObject:(NSString *)userText forKey:AUDIO_DESC_KEY];
						CFRelease(userText);
					}
					DisposeHandle(sampleDesc);
				}
			}
			/*Set the sample rate*/
			if(audioSampleRate != nil)
				[fileMeta setObject:audioSampleRate forKey:SAMPLE_RATE_KEY];
			NSArray *videoTracks = [movie tracksOfMediaType:@"vide"];
			if([videoTracks count])
			{
				/*Get the video track*/
				QTTrack *track = [videoTracks objectAtIndex:0];
				QTMedia *media = [track media]; 
				if(media != nil) 
				{ 
					/*Get the video description*/ 
					Media qtMedia = [media quickTimeMedia]; 
					Handle sampleDesc = NewHandle(1); 
					GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc); 
					CFStringRef userText = nil; 
					ByteCount propSize = 0; 
					ICMImageDescriptionGetProperty((ImageDescriptionHandle)sampleDesc, kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_SummaryString, sizeof(userText), &userText, &propSize); 
					DisposeHandle(sampleDesc); 
					
					if(userText != nil) 
					{ 
						/*Set the description*/ 
						[fileMeta setObject:(NSString *)userText forKey:VIDEO_DESC_KEY]; 
						CFRelease(userText); 
					} 
				} 
			}
		} //QTMovie
		else if([file fileContainerType] == FILE_CONTAINER_TYPE_VIDEO_TS)
		{
			SapphireVideoTsParser *dvd = [[SapphireVideoTsParser alloc] initWithPath:path];

			[fileMeta setObject:[dvd videoFormatsString ] forKey:VIDEO_DESC_KEY];
			[fileMeta setObject:[dvd audioFormatsString ] forKey:AUDIO_DESC_KEY];
			[fileMeta setObject:[dvd subtitlesString    ] forKey:SUBTITLES_KEY ];
			[fileMeta setObject:[dvd mainFeatureDuration] forKey:DURATION_KEY  ];
			[fileMeta setObject:[dvd totalSize          ] forKey:SIZE_KEY      ];

			[dvd release];
		} // VIDEO_TS
		[file addFileData:fileMeta];
	}
	return updated ;
}

- (BOOL)updateMetaData
{
	return updateMetaData(self);
}

- (int)modified
{
	return [[metaData objectForKey:MODIFIED_KEY] intValue];
}

- (BOOL)watched
{
	return [[metaData objectForKey:WATCHED_KEY] boolValue];
}

- (void)setWatched:(BOOL)watched
{
	[metaData setObject:[NSNumber numberWithBool:watched] forKey:WATCHED_KEY];
}

- (BOOL)favorite
{
	return [[metaData objectForKey:FAVORITE_KEY] boolValue];
}

- (void)setFavorite:(BOOL)favorite
{
	[metaData setObject:[NSNumber numberWithBool:favorite] forKey:FAVORITE_KEY];
}

- (long)importedTimeFromSource:(NSString *)source
{
	return [[[metaData objectForKey:source] objectForKey:MODIFIED_KEY] longValue];
}

- (void)setToImportFromSource:(NSString *)source
{
	NSMutableDictionary *sourceDict = [[metaData objectForKey:source] mutableCopy];
	if(sourceDict != nil)
	{
		[metaData setObject:sourceDict forKey:source];
		[sourceDict removeObjectForKey:MODIFIED_KEY];
		[sourceDict release];
	}
}

- (oneway void)importInfo:(bycopy NSMutableDictionary *)newMeta fromSource:(bycopy NSString *)source withTime:(long)modTime
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *info = [NSDictionary dictionaryWithObject:source forKey:META_DATA_FILE_INFO_KIND];
	[nc postNotificationName:META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION object:self userInfo:info];
	[newMeta setObject:[NSNumber numberWithInt:modTime] forKey:MODIFIED_KEY];
	[metaData setObject:newMeta forKey:source];
	[self combinedDataChanged];
	[nc postNotificationName:META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION object:self userInfo:info];
}

- (void)clearMetaData
{
	[metaData removeAllObjects];
	[self combinedDataChanged];
}

- (unsigned int)resumeTime
{
	return [[metaData objectForKey:RESUME_KEY] unsignedIntValue];
}

- (void)setResumeTime:(unsigned int)resumeTime
{
	[metaData setObject:[NSNumber numberWithUnsignedInt:resumeTime] forKey:RESUME_KEY];
}

- (FileClass)fileClass
{
	return [[metaData objectForKey:FILE_CLASS_KEY] intValue];
}

- (void)setFileClass:(FileClass)fileClass
{
	[metaData setObject:[NSNumber numberWithInt:fileClass] forKey:FILE_CLASS_KEY];
}

- (FileContainerType)fileContainerType
{
	return [[metaData objectForKey:FILE_CONTAINER_TYPE_KEY] intValue];
}

- (void)setFileContainerType:(FileContainerType)fileContainerType
{
	[metaData setObject:[NSNumber numberWithInt:fileContainerType] forKey:FILE_CONTAINER_TYPE_KEY];
}


- (NSString *)joinedFile;
{
	return [metaData objectForKey:JOINED_FILE_KEY];
}

- (void)setJoinedFile:(NSString *)join
{
	if(join == nil)
		[metaData removeObjectForKey:JOINED_FILE_KEY];
	else
		[metaData setObject:join forKey:JOINED_FILE_KEY];
}

- (long long)size
{
	return [[metaData objectForKey:SIZE_KEY] longLongValue];
}

- (float)duration
{
	return [[metaData objectForKey:DURATION_KEY] floatValue];
}

- (Float64)sampleRate
{
	return [[metaData objectForKey:SAMPLE_RATE_KEY] intValue];
}

- (UInt32)audioFormatID
{
	return [[metaData objectForKey:AUDIO_FORMAT_KEY] unsignedIntValue];
}

- (BOOL)hasVideo
{
	return [metaData objectForKey:VIDEO_DESC_KEY] != nil;
}

/*Combine the metadata from multiple sources*/
- (void)constructCombinedData
{
	/*Return cached data*/
	if(combinedInfo != nil)
		return;
	/*Combine from in order of priority: xml, tvrage, and file*/
	NSMutableDictionary *ret = [metaData mutableCopy];
	[ret addEntriesFromDictionary:[ret objectForKey:META_TVRAGE_IMPORT_KEY]];
	[ret addEntriesFromDictionary:[ret objectForKey:META_IMDB_IMPORT_KEY]];
	[ret addEntriesFromDictionary:[ret objectForKey:META_XML_IMPORT_KEY]];
	combinedInfo = ret;
}

/*Destroy cached metadata*/
- (void)combinedDataChanged
{
	/*Remove cached data*/
	[combinedInfo release];
	combinedInfo = nil;
}

- (int)episodeNumber
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_EPISODE_NUMBER_KEY] intValue] ;
}

- (int)secondEpisodeNumber
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_EPISODE_2_NUMBER_KEY] intValue];
}

- (int)seasonNumber
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_SEASON_NUMBER_KEY] intValue];
}

- (int)overriddenSeasonNumber
{
	[self constructCombinedData];
	NSNumber *info = [combinedInfo objectForKey:META_SEARCH_SEASON_NUMBER_KEY];
	if(info != nil)
		return [info intValue];
	return -1;
}

- (int)overriddenEpisodeNumber
{
	[self constructCombinedData];
	NSNumber *info = [combinedInfo objectForKey:META_SEARCH_EPISODE_NUMBER_KEY];
	if(info != nil)
		return [info intValue];
	return -1;
}

- (int)overriddenSecondEpisodeNumber
{
	[self constructCombinedData];
	NSNumber *info = [combinedInfo objectForKey:META_SEARCH_EPISODE_2_NUMBER_KEY];
	if(info != nil)
		return [info intValue];
	return -1;
}

- (NSDate *)airDate
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_SHOW_AIR_DATE];
}

- (int)oscarsWon
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_MOVIE_OSCAR_KEY] intValue];
}

- (int)imdbTop250
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_MOVIE_IMDB_250_KEY] intValue];
}

- (NSString *)episodeTitle
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_TITLE_KEY] ;
}

- (NSString *)movieTitle
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_TITLE_KEY] ;
}

- (NSDate *)movieReleaseDate
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_RELEASE_DATE_KEY] ;
}

- (NSString *)movieStatsOscar
{
	[self constructCombinedData];
	return [NSString stringWithFormat:@"%dx",[[combinedInfo objectForKey:META_MOVIE_OSCAR_KEY] intValue]];
}

- (NSString *)movieStatsTop250
{
	[self constructCombinedData];
	return [NSString stringWithFormat:@"#%d ",[[combinedInfo objectForKey:META_MOVIE_IMDB_250_KEY] intValue]];
}

- (NSString *)movieID
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_IDENTIFIER_KEY];
}

- (NSString *)showID
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_SHOW_IDENTIFIER_KEY];
}

- (NSString *)showName
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_SHOW_NAME_KEY];
}

- (NSArray *)movieGenres
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_GENRES_KEY];
}

- (NSArray *)movieCast
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_CAST_KEY];
}

- (NSArray *)movieDirectors
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_DIRECTOR_KEY];
}

- (NSString *)sizeString
{
	/*Get size*/
	float size = [self size];
	if(size == 0)
		return @"-";

	/*The letter for magnitude*/
	char letter = ' ';
	if(size >= 1024000)
	{
		if(size >= 1024*1024000)
		{
			/*GB*/
			size /= 1024 * 1024 * 1024;
			letter = 'G';
		}
		else
		{
			/*MB*/
			size /= 1024 * 1024;
			letter = 'M';
		}
	}
	else if (size >= 1000)
	{
		/*KB*/
		size /= 1024;
		letter = 'K';
	}
	return [NSString stringWithFormat:@"%.1f%cB", size, letter];	
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;
{
	NSString *name = [path lastPathComponent];
	/*Create duration string*/
	int duration = [self duration];
	int secs = duration % 60;
	int mins = (duration /60) % 60;
	int hours = duration / 3600;
	NSString *durationStr = nil;
	if(hours != 0)
		durationStr = [NSString stringWithFormat:@"%d:%02d:%02d", hours, mins, secs];
	else if (mins != 0)
		durationStr = [NSString stringWithFormat:@"%d:%02d", mins, secs];
	else
		durationStr = [NSString stringWithFormat:@"%ds", secs];
	/*Set the order*/
	if(order != nil)
		*order = displayedMetaDataOrder;
	[self constructCombinedData];
	NSMutableDictionary *ret = [combinedInfo mutableCopy];
	/*Remove keys we don't display*/
	NSMutableSet *currentKeys = [NSMutableSet setWithArray:[ret allKeys]];
	[currentKeys minusSet:displayedMetaData];
	[ret removeObjectsForKeys:[currentKeys allObjects]];
	
	/*Substitute display titles for internal keys*/
	NSEnumerator *subEnum = [metaDataSubstitutions keyEnumerator];
	NSString *key = nil;
	while((key = [subEnum nextObject]) != nil)
	{
		NSString *value = [ret objectForKey:key];
		if(value != nil)
		{
			/*Found object at a key, set it for the display title*/
			[ret setObject:value forKey:[metaDataSubstitutions objectForKey:key]];
			[ret removeObjectForKey:key];
		}
	}
	if([self duration])
	{
		if([self size])
		{
			/*If we have a duration and size, combine into a single line*/
			[ret setObject:[NSString stringWithFormat:@"%@ (%@)", durationStr, [self sizeString]] forKey:DURATION_KEY];
			[ret removeObjectForKey:SIZE_KEY];
		}
		else
			/*Otherwse, just set the duration*/
			[ret setObject:durationStr forKey:DURATION_KEY];
	}
	else if([self size])
		/*If no duration, set the size*/
		[ret setObject:[self sizeString] forKey:SIZE_KEY];
	else
		/*Otherwise, remove the size*/
		[ret removeObjectForKey:SIZE_KEY];
	
	/*Set the title*/
	if([ret objectForKey:META_TITLE_KEY] == nil)
		[ret setObject:name forKey:META_TITLE_KEY];
	/*Set the season and episode*/
	int season = [self seasonNumber];
	int ep = [self episodeNumber];
	if(season != 0 && ep != 0) 
	{
		int secondEp = [self secondEpisodeNumber];
		if(secondEp != nil)
			[ret setObject:[NSString stringWithFormat:@"%@ - %d / %d-%d",[self showName], season, ep, secondEp] forKey:META_EPISODE_AND_SEASON_KEY];
		else
			[ret setObject:[NSString stringWithFormat:@"%@ - %d / %d",[self showName], season, ep] forKey:META_EPISODE_AND_SEASON_KEY];
	}
	return ret;
}

/*Custom TV Episode handler*/
- (NSComparisonResult) episodeCompare:(SapphireFileMetaData *)other
{
	/*Sort by show first*/
	/*Put items with no show at the bottom*/
	NSString *myShow = [self showName];
	NSString *theirShow = [other showName];
	if(myShow != nil || theirShow != nil)
	{
		if(myShow == nil)
			return NSOrderedDescending;
		else if(theirShow == nil)
			return NSOrderedAscending;
		else
		{
			/*Both have a show*/
			NSComparisonResult result = [myShow compare:theirShow options:NSCaseInsensitiveSearch];
			if(result != NSOrderedSame)
				return result;
		}		
	}
	/*Sort by season next*/
	/*Put shows with no season at the bottom*/
	int myNum = [self seasonNumber];
	int theirNum = [other seasonNumber];
	if(myNum == 0)
		myNum = INT_MAX;
	if(theirNum == 0)
		theirNum = INT_MAX;
	if(myNum > theirNum)
		return NSOrderedDescending;
	if(theirNum > myNum)
		return NSOrderedAscending;
	
	/*Sort by episode next*/
	myNum = [self episodeNumber];
	theirNum = [other episodeNumber];
	if(myNum == 0 || theirNum == 0)
	{
		NSDate *otherDate = [other airDate];
		NSDate *myDate = [self airDate];
		if(otherDate != nil && myDate != nil)
			return [myDate compare:otherDate];
		if(myNum == 0)
			myNum = INT_MAX;
		if(theirNum == 0)
			theirNum = INT_MAX;
	}
	if(myNum > theirNum)
		return NSOrderedDescending;
	if(theirNum > myNum)
		return NSOrderedAscending;
	/*Finally sort by name*/
	return [[path lastPathComponent] compare:[[other path] lastPathComponent] options:NSCaseInsensitiveSearch | NSNumericSearch];
}
@end
