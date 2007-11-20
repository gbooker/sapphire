//
//  SapphireMetaData.m
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMetaData.h"
#import <QTKit/QTKit.h>
#include <sys/types.h>
#include <sys/stat.h>
#import "SapphireSettings.h"
#import "SapphirePredicates.h"
#import "SapphireMetaDataScanner.h"

//Structure Specific Keys
#define FILES_KEY					@"Files"
#define DIRS_KEY					@"Dirs"
#define META_VERSION_KEY			@"Version"
#define META_COLLECTION_OPTIONS		@"Options"
#define META_COLLECTION_HIDE		@"Hide"
#define META_COLLECTION_SKIP_SCAN	@"Skip"
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
#define JOINED_FILE_KEY				@"Joined File"
//#define FILE_CLASS_KEY				@"File Class"

@implementation NSString (episodeSorting)

/*!
 * @brief Comparison for episode names
 *
 * @param other The other string to compare
 * @return The comparison result of the compare
 */
- (NSComparisonResult) directoryNameCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@interface SapphireDirectoryMetaData (private)
- (void)reloadDirectoryContents;
- (SapphireFileMetaData *)cachedMetaDataForFile:(NSString *)file;
- (void)invokeRecursivelyOnFiles:(NSInvocation *)fileInv withPredicate:(SapphirePredicate *)predicate;
@end

static NSSet *coverArtExtentions = nil;

static NSString *searchExtForPath(NSString *path)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	/*Search all extensions*/
	NSEnumerator *extEnum = [coverArtExtentions objectEnumerator];
	NSString *ext = nil;
	while((ext = [extEnum nextObject]) != nil)
	{
		NSString *candidate = [path stringByAppendingPathExtension:ext];
		/*Check the candidate*/
		if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
			return candidate;
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
}

/*!
 * @brief Returns a set of all the video extensions
 *
 * @return The set of all video extensions
 */
+ (NSSet *)videoExtensions
{
	return videoExtensions;
}

/*!
 * @brief Returns a set of all the audio extensions
 *
 * @return The set of all audio extensions
 */
+ (NSSet *)audioExtensions
{
	return audioExtensions;
}

/*!
 * @brief Creates a new meta data object
 *
 * @param dict The configuration dictionary.  Note, this dictionary is copied and the copy is modified
 * @param myParent The parent meta data
 * @param The path for this meta data
 * @return The meta data object
 */
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
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
 * @brief Returns the mutable dictionary object containing all the meta data
 *
 * @return The dictionary
 */
- (NSMutableDictionary *)dict
{
	return metaData;
}

/*!
 * @brief Returns the path of the current meta data
 *
 * @return The path
 */
- (NSString *)path
{
	return path;
}

/*!
 * @brief Sets the delegate for the meta data
 *
 * @param newDelegate The new delegate
 */
- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate
{
	delegate = newDelegate;
}

/*!
 * @brief Write all the meta data to a file.  This function is called on the parents
 */
- (void)writeMetaData
{
	[parent writeMetaData];
}

- (SapphireMetaDataCollection *)collection
{
	return nil;
}

- (BOOL)isDirectory:(NSString *)fullPath
{
	BOOL isDir = NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir;
}

/*!
 * @brief Get the meta data for display
 *
 * @param order A pointer to an NSArray * in which to store the order in which the meta data is to be displayed
 * @return The display meta data with the titles as keys
 */
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
		dir = [[NSMutableDictionary alloc] init];
	else
		dir = [dir mutableCopy];
	[source setObject:dir forKey:element];
	[dir release];
	if([pathComponents count] == 1)
	{
		/* insert here */
		[dir setDictionary:dict];
	}
	else
	{
		NSMutableDictionary *dirs = [dir objectForKey:DIRS_KEY];
		if(dirs == nil)
			dirs = [[NSMutableDictionary alloc] init];
		else
			dirs = [dirs mutableCopy];
		[dir setObject:dirs forKey:DIRS_KEY];
		[dirs release];
		
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

/*!
 * @brief Create a collection from a file and browsing a directory
 *
 * @param dictionary The path to the dictionary storing the meta data
 * @param myPath The path to browse for the meta data
 * @return The meta data collection
 */
- (id)initWithFile:(NSString *)dictionary
{
	/*Read the meta data*/
	dictionaryPath = [dictionary retain];
	NSData *fileData = [NSData dataWithContentsOfFile:dictionary];
	NSString *error = nil;
	NSMutableDictionary *mainDict = [NSPropertyListSerialization propertyListFromData:fileData mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL errorDescription:&error];
	[error release];
	if(mainDict == nil)
		mainDict = [NSMutableDictionary dictionary];
	self = [super initWithDictionary:mainDict parent:nil path:nil];
	if(!self)
		return nil;
	
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

	NSMutableDictionary *collectionOptions = [[metaData objectForKey:META_COLLECTION_OPTIONS] mutableCopy];
	if(collectionOptions == nil)
		collectionOptions = [[NSMutableDictionary alloc] init];
	[metaData setObject:collectionOptions forKey:META_COLLECTION_OPTIONS];
	[collectionOptions release];
	
	skipCollection = [[collectionOptions objectForKey:META_COLLECTION_SKIP_SCAN] mutableCopy];
	if(skipCollection == nil)
		skipCollection = [[NSMutableDictionary alloc] init];
	[collectionOptions setObject:skipCollection forKey:META_COLLECTION_SKIP_SCAN];
	
	hideCollection = [[collectionOptions objectForKey:META_COLLECTION_HIDE] mutableCopy];
	if(hideCollection == nil)
		hideCollection = [[NSMutableDictionary alloc] init];
	[collectionOptions setObject:hideCollection forKey:META_COLLECTION_HIDE];
	
	directories = [[NSMutableDictionary alloc] init];
	
	/* Hide and skip the / collection */
	[self setHide:YES forCollection:@"/"];
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
	if(writeTimer != nil)
	{
		[writeTimer invalidate];
		[self realWriteMetaData];
	}
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

/*!
 * @brief Returns the meta data for a particular path
 *
 * @param path The path to find
 * @return The directory meta data for the path, or nil if none exists
 */
- (SapphireMetaData *)dataForPath:(NSString *)absPath
{
	SapphireDirectoryMetaData *directory = [directories objectForKey:@"/"];
	return [self dataForSubPath:absPath inDirectory:directory];
}

/*!
 * @brief Returns the meta data for a particular path
 *
 * @param path The path to find
 * @param data The meta data to use in place of the source's data
 * @return The directory meta data for the path, or nil if none exists
 */
- (SapphireMetaData *)dataForPath:(NSString *)absPath withData:(NSDictionary *)data
{
	SapphireMetaData *ret = [self dataForPath:absPath];
	
	if([data count] != 0)
		[ret replaceInfoWithDict:data];
	
	return ret;
}

/*!
 * @brief Returns the directory meta data for a particular path
 *
 * @param path The path to find
 * @return The directory meta data for the path, or nil if none exists
 */
- (SapphireDirectoryMetaData *)directoryForPath:(NSString *)absPath
{
	SapphireMetaData *ret = [self dataForPath:absPath];
	if([ret isKindOfClass:[SapphireDirectoryMetaData class]])
		return (SapphireDirectoryMetaData *)ret;
	return nil;
}

/*!
 * @brief Gets a listing of all valid collection directories.  These are all mounted disks
 * plus homedir/Movies
 *
 * @return All the directory locations
 */

- (NSArray *)collectionDirectories
{
	NSWorkspace *mywork = [NSWorkspace sharedWorkspace];
	NSMutableArray *ret = [[mywork mountedLocalVolumePaths] mutableCopy];
	[ret removeObject:@"/mnt"];
	[ret removeObject:@"/CIFS"];
	[ret removeObject:NSHomeDirectory()];
	[ret addObject:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"]];
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

/*!
 * @brief Write all meta data to a file
 */
- (void)writeMetaData
{
	[writeTimer invalidate];
	writeTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(realWriteMetaData) userInfo:nil repeats:NO];
}

- (void)realWriteMetaData
{
	[writeTimer invalidate];
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

/*!
 * @brief Returns whether the collection is hidden or not
 *
 * @return YES if the collection is hidden, NO otherwise
 */
- (BOOL)hideCollection:(NSString *)collection
{
	return [[hideCollection objectForKey:collection] boolValue];
}

/*!
 * @brief Set whether to hide the collection or not
 *
 * @param hide YES to hide this collection, NO otherwise
 */
- (void)setHide:(BOOL)hide forCollection:(NSString *)collection
{
	[hideCollection setObject:[NSNumber numberWithBool:hide] forKey:collection];
	[self writeMetaData];
}

/*!
 * @brief Returns whether the collection is skipped or not
 *
 * @return YES if the collection is skipped, NO otherwise
 */
- (BOOL)skipCollection:(NSString *)collection
{
	return [[skipCollection objectForKey:collection] boolValue];
}

/*!
 * @brief Set whether to skip the collection or not
 *
 * @param skip YES to skip this collection, NO otherwise
 */
- (void)setSkip:(BOOL)skip forCollection:(NSString *)collection
{
	[skipCollection setObject:[NSNumber numberWithBool:skip] forKey:collection];
	[self writeMetaData];
}

@end

@implementation SapphireDirectoryMetaData

- (void)createSubDicts
{
	/*Get the file listing*/
	metaFiles = [metaData objectForKey:FILES_KEY];
	if(metaFiles == nil)
		metaFiles = [NSMutableDictionary new];
	else
		metaFiles = [metaFiles mutableCopy];
	[metaData setObject:metaFiles forKey:FILES_KEY];
	[metaFiles release];
	
	/*Get the directory listing*/
	metaDirs = [metaData objectForKey:DIRS_KEY];
	if(metaDirs == nil)
		metaDirs = [NSMutableDictionary new];
	else
		metaDirs = [metaDirs mutableCopy];
	[metaData setObject:metaDirs forKey:DIRS_KEY];
	[metaDirs release];	
}

/*!
 * @brief Creates a new meta data object
 *
 * @param dict The configuration dictionary.  Note, this dictionary is copied and the copy is modified
 * @param myParent The parent meta data
 * @param myPath The path for this meta data object
 * @return The meta data object
 */
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
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
	[self postAllFilesRemoved];
	[importTimer invalidate];
	[importArray release];
	[cachedMetaDirs release];
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
	[importTimer invalidate];
	importTimer = nil;
	scannedDirectory = NO;
}

/*!
 * @brief Reloads the directory contents from what is present on disk
 */
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
			
			BOOL rewrite = NO;
			if([refDict objectForKey:name] != nil)
				rewrite = YES;
			[refDict removeObjectForKey:name];
			if(rewrite)
				[self writeMetaData];
		}
		/*Only accept if it is a directory or right extension*/
		NSString *extension = [name pathExtension];
		if([self isDirectory:filePath])
		{
			[directories addObject:name];
			if(resolvedObject != nil)
				[cachedMetaDirs setObject:resolvedObject forKey:name];
		}
		else if([allExtensions containsObject:[extension lowercaseString]])
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
	if([importArray count] || [self pruneMetaData])
		[self writeMetaData];
	/*Mark directory as scanned*/
	scannedDirectory = YES;
}


- (NSString *)coverArtPathUpToParents:(int)parents
{
	NSString *ret = searchExtForPath([[self path] stringByAppendingPathComponent:@"Cover Art/cover"]);
	if(ret != nil)
		return ret;
	
	ret = searchExtForPath([[self path] stringByAppendingPathComponent:@"Cover Art/cover"]);
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

/*!
 * @brief Retrieve a list of all file names
 *
 * @return An NSArray of all file names
 */
- (NSArray *)files
{
	return files;
}

/*!
 * @brief Retrieve a list of all directory names
 *
 * @return An NSArray of all directory names
 */
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

/*!
 * @brief Get a listing of predicate files
 *
 * @param predicate The predicate to match
 * @return An NSArray of matches
 */
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

/*!
 * @brief Get a listing of predicated directories
 *
 * @param predicate The predicate to match
 * @return An NSArray of matches
 */
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

/*!
 * @brief Get the meta data object for a file.  Creates one if it doesn't already exist
 *
 * @param file The file within this dir
 * @return The file's meta data
 */
- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	/*Check cache*/
	SapphireFileMetaData *ret = [cachedMetaFiles objectForKey:file];
	if(ret == nil)
	{
		/*Create it*/
		ret = [[SapphireFileMetaData alloc] initWithDictionary:[metaFiles objectForKey:file] parent:self path:[path stringByAppendingPathComponent:file]];
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

/*!
 * @brief Get the meta data object for a directory.  Creates one if it doesn't alreay exist
 *
 * @param dir The directory within this dir
 * @return The directory's meta data
 */
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)dir
{
	/*Check cache*/
	SapphireDirectoryMetaData *ret = [cachedMetaDirs objectForKey:dir];
	if(ret == nil)
	{
		/*Create it*/
		ret = [[SapphireDirectoryMetaData alloc] initWithDictionary:[metaDirs objectForKey:dir] parent:self path:[path stringByAppendingPathComponent:dir]];
		[metaDirs setObject:[ret dict] forKey:dir];
		/*Add to cache*/
		[cachedMetaDirs setObject:ret forKey:dir];
		[ret autorelease];		
	}
	/*Return it*/
	return ret;
}

/*!
 * @brief Prunes off non-existing files and directories from the meta data.  This does not prune a directory's content if it contains no files and directories.  In addition, broken sym links are also not pruned.  The theory is these may be the signs of missing mounts.
 *
 * @return YES if any data was pruned, NO otherwise
 */
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

/*!
 * @brief See if any files need to be updated
 *
 * @return YES if any files need an update, NO otherwise
 */
- (BOOL)updateMetaData
{
	/*Look at each file*/
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *fileName = nil;
	importArray = [[NSMutableArray alloc] init];
	while((fileName = [fileEnum nextObject]) != nil)
	{
		/*If the file exists, and no meta data, add to update list*/
		NSDictionary *fileMeta = [metaFiles objectForKey:fileName];
		if(fileMeta == nil)
		{
			[self metaDataForFile:fileName];
			[importArray addObject:fileName];
		}
		else
		{
			/*If file has been modified since last import, add to update list*/
			NSString *filePath = [path stringByAppendingPathComponent:fileName];
			struct stat sb;
			memset(&sb, 0, sizeof(struct stat));
			stat([filePath fileSystemRepresentation], &sb);
			long modTime = sb.st_mtimespec.tv_sec;
			if([[fileMeta objectForKey:MODIFIED_KEY] intValue] != modTime || [[fileMeta objectForKey:META_VERSION_KEY] intValue] != META_FILE_VERSION)
				[importArray addObject:fileName];
		}
	}
	/*We didn't do any updates yet, so return NO*/
	return NO;
}

/*Timer function to process a single file*/
- (void)processFiles:(NSTimer *)timer
{
	NSString *file = [importArray objectAtIndex:0];
	
	/*Get the file and update it*/
	[[self metaDataForFile:file] updateMetaData];
	
	/*Write the file info out and tell delegate we updated*/
	[self writeMetaData];
	[delegate updateCompleteForFile:file];
	
	/*Remove from list and redo timer*/
	[importArray removeObjectAtIndex:0];
	[self resumeImport];
}

/*!
 * @brief Cancel the import process
 */
- (void)cancelImport
{
	/*Kill the timer*/
	[importTimer invalidate];
	importTimer = nil;
}

/*!
 * @brief Resume the import process
 */
- (void)resumeImport
{
	/*Sanity check*/
	[importTimer invalidate];
	/*Check if we need to import*/
	if([importArray count])
		/*Wait 1.1 seconds and do an import*/
		importTimer = [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(processFiles:) userInfo:nil repeats:NO];
	else
	{
		/*No import, so clean up*/
		importTimer = nil;
		[importArray release];
		importArray = nil;
	}
}

/*!
 * @brief Delay the import process a while before starting again
 */
- (void)resumeDelayedImport
{
	/*Sanity check*/
	[importTimer invalidate];
	/*Check if we need to import*/
	if([importArray count])
		/*Wait 5 seconds before starting the import process*/
		importTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resumeImport) userInfo:nil repeats:NO];
	else
		/*No import, clean up*/
		importTimer = nil;
}

/*!
 * @brief Get the meta data for some file or directory beneath this one
 *
 * @param subPath The subpath to get the meta data
 * @return The meta data object
 */
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
	/*Return our file's meta data*/
	return [self metaDataForFile:file];
}

/*!
 * @brief Get the meta data for all the files contained within this directory tree
 *
 * @param subDelegate The delegate to inform when scan is complete
 * @param skip A set of directories to skip.  Note, this set is modified
 */
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

/*!
 * @brief Scan for all files contained within this directory tree
 *
 * @param subDelegate The delegate to inform when scan is complete
 * @param skip A set of directories to skip.  Note, this set is modified
 */
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

/*!
 * @brief Load all the cached meta data so that dynamic directories can build
 */
- (void)loadMetaData
{
	NSArray *keys = [NSArray arrayWithArray:[metaDirs allKeys]];
	NSEnumerator *dirEnum = [keys objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
	{
		[[self metaDataForDirectory:dir] loadMetaData];
	}
	keys = [NSArray arrayWithArray:[metaFiles allKeys]];
	NSEnumerator *fileEnum = [keys objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		[self metaDataForFile:file];
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

/*!
 * @brief Returns if directory contains any watched files
 *
 * @param predicate The predicate to match on
 * @return YES if at least one exists, NO otherwise
 */
- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(watched);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	return [self checkResult:NO recursivelyOnFiles:fileInv forPredicate:predicate];
}

/*!
 * @brief Set subtree as watched
 *
 * @param watched YES if set to watched, NO if set to unwatched
 * @param predicate The predicate which to restrict setting
 */
- (void)setWatched:(BOOL)watched forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setWatched:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&watched atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

/*!
 * @brief Returns if directory contains any favorite files
 *
 * @param predicate The predicate to match on
 * @return YES if at least one exists, NO otherwise
 */
- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(favorite);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	return [self checkResult:YES recursivelyOnFiles:fileInv forPredicate:predicate];	
}

/*!
 * @brief Set subtree as favorite
 *
 * @param watched YES if set to favorite, NO if set to not favorite
 * @param predicate The predicate which to restrict setting
 */
- (void)setFavorite:(BOOL)favorite forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setFavorite:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&favorite atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

/*!
 * @brief Set subtree to re-import from the specified source
 *
 * @param source The source on which to re-import
 * @param predicate The predicate which to restrict setting
 */
- (void)setToImportFromSource:(NSString *)source forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setToImportFromSource:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&source atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

/*!
 * @brief Set subtree to the specified class
 *
 * @param fileClass The file class
 * @param predicate The predicate which to restrict setting
 */
- (void)setFileClass:(FileClass)fileClass forPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setFileClass:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&fileClass atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	[self writeMetaData];
}

- (SapphireMetaDataCollection *)collection
{
	if(collection == nil)
		collection = [parent collection];
	
	return collection;
}

/*See super documentation*/
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

/*Makes meta data easier to deal with in terms of display*/
static NSDictionary *metaDataSubstitutions = nil;
static NSSet *displayedMetaData = nil;
static NSArray *displayedMetaDataOrder = nil;

+ (void) initialize
{
	metaDataSubstitutions = [[NSDictionary alloc] initWithObjectsAndKeys:
		//These substitute keys in the meta data to nicer display keys
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
		META_RATING_KEY,
		META_DESCRIPTION_KEY,
		META_MOVIE_PLOT_KEY,
		META_COPYRIGHT_KEY,
		META_TITLE_KEY,
		META_MOVIE_TITLE_KEY,
		META_SHOW_AIR_DATE,
		META_MOVIE_RELEASE_DATE_KEY,
		META_MOVIE_DIRECTOR_KEY,
		META_MOVIE_GENRES_KEY,
		META_MOVIE_CAST_KEY,
		META_MOVIE_WIRTERS_KEY,
		//These are displayed as line items
		META_EPISODE_AND_SEASON_KEY,
		META_SEASON_NUMBER_KEY,
		META_EPISODE_NUMBER_KEY,
		SIZE_KEY,
		DURATION_KEY,
		VIDEO_DESC_KEY,
		AUDIO_DESC_KEY,
		nil];
	displayedMetaData = [[NSSet alloc] initWithArray:displayedMetaDataOrder];
	
	/*Remove non-displayed data from the displayed order, and use the display keys*/
	int excludedKeys = 5;
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

- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:dict parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
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
	/*Find cover art for the current file in the "Cover Art" dir*/
	NSString *subPath = [[self path] stringByDeletingPathExtension];
	NSString *fileName = [subPath lastPathComponent];
	NSString *ret = searchExtForPath([[[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:fileName]);
	if(ret != nil)
		return ret;
	
	/*Find cover art for the current file in the current dir*/
	ret = searchExtForPath(subPath);
	if(ret != nil)
		return ret;
	
	return [(SapphireDirectoryMetaData *)parent coverArtPath];
}

/*See super documentation*/
- (BOOL) updateMetaData
{
	/*Check modified date*/
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
	BOOL updated =FALSE;
	
	if(props == nil)
		/*No file*/
		return FALSE;
	
	/*Has it been modified since last import?*/
	if(modTime != [self modified] || [[metaData objectForKey:META_VERSION_KEY] intValue] != META_FILE_VERSION)
	{
		/*We did an update*/
		updated=TRUE ;
		NSMutableDictionary *fileMeta = [NSMutableDictionary dictionary];
		
		/*Set modified, size, and version*/
		[fileMeta setObject:[NSNumber numberWithInt:modTime] forKey:MODIFIED_KEY];
		[fileMeta setObject:[props objectForKey:NSFileSize] forKey:SIZE_KEY];
		[fileMeta setObject:[NSNumber numberWithInt:META_FILE_VERSION] forKey:META_VERSION_KEY];
		
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
		/*Add the meta data*/
		[metaData addEntriesFromDictionary:fileMeta];
		[self combinedDataChanged];
	}
	return updated ;
}

/*!
 * @brief Get date of last modification of the file
 *
 * @return Seconds since 1970 of last modification
 */
- (int)modified
{
	return [[metaData objectForKey:MODIFIED_KEY] intValue];
}

/*!
 * @brief Returns whether the file has been watched
 *
 * @return YES if watched, NO otherwise
 */
- (BOOL)watched
{
	return [[metaData objectForKey:WATCHED_KEY] boolValue];
}

/*!
 * @brief Sets the file as watch or not watched
 *
 * @param watched YES if set to watched, NO if set to unwatched
 */
- (void)setWatched:(BOOL)watched
{
	[metaData setObject:[NSNumber numberWithBool:watched] forKey:WATCHED_KEY];
}

/*!
 * @brief Returns whether the file is favorite
 *
 * @return YES if favorite, NO otherwise
 */
- (BOOL)favorite
{
	return [[metaData objectForKey:FAVORITE_KEY] boolValue];
}

/*!
 * @brief Sets the file as favorite or not favorite
 *
 * @param watched YES if set to favorite, NO if set to not favorite
 */
- (void)setFavorite:(BOOL)favorite
{
	[metaData setObject:[NSNumber numberWithBool:favorite] forKey:FAVORITE_KEY];
}

/*!
 * @brief Returns the time of import from a source
 *
 * @param source The source to check
 * @return The seconds since 1970 of the import
 */
- (long)importedTimeFromSource:(NSString *)source
{
	return [[[metaData objectForKey:source] objectForKey:MODIFIED_KEY] longValue];
}

/*!
 * @brief Sets the file to re-import from source
 *
 * @param source The source to re-import
 */
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

/*!
 * @brief Add data to import from a source
 *
 * @param newMeta The new meta data
 * @param source The source we imported from
 * @param modTime The modification time of the source
 */
- (void)importInfo:(NSMutableDictionary *)newMeta fromSource:(NSString *)source withTime:(long)modTime
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *info = [NSDictionary dictionaryWithObject:source forKey:META_DATA_FILE_INFO_KIND];
	[nc postNotificationName:META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION object:self userInfo:info];
	[newMeta setObject:[NSNumber numberWithInt:modTime] forKey:MODIFIED_KEY];
	[metaData setObject:newMeta forKey:source];
	[self combinedDataChanged];
	[nc postNotificationName:META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION object:self userInfo:info];
}

/*!
 * @brief The resume time of the file
 *
 * @return The number of seconds from the begining of the file to resume
 */
- (unsigned int)resumeTime
{
	return [[metaData objectForKey:RESUME_KEY] unsignedIntValue];
}

/*!
 * @brief Sets the resume time of the file
 *
 * @param resumeTime The number of seconds from the beginning of the file to resume
 */
- (void)setResumeTime:(unsigned int)resumeTime
{
	[metaData setObject:[NSNumber numberWithUnsignedInt:resumeTime] forKey:RESUME_KEY];
}

/*!
 * @brief The file type
 *
 * @return The file type
 */
- (FileClass)fileClass
{
	if([[metaData objectForKey:FILE_CLASS_KEY] intValue]==nil)
		return FILE_CLASS_UNKNOWN;
	else
	return [[metaData objectForKey:FILE_CLASS_KEY] intValue];
}

/*!
 * @brief Sets the file type
 *
 * @param fileClass The file type
 */
- (void)setFileClass:(FileClass)fileClass
{
	[metaData setObject:[NSNumber numberWithInt:fileClass] forKey:FILE_CLASS_KEY];
}

/*!
 * @brief The file this has been joined to
 *
 * @return The file this has been joined to
 */
- (NSString *)joinedFile;
{
	return [metaData objectForKey:JOINED_FILE_KEY];
}

/*!
 * @brief Sets the file this has been joined to
 *
 * @param fileClass The file this has been joined to
 */
- (void)setJoinedFile:(NSString *)join
{
	if(join == nil)
		[metaData removeObjectForKey:JOINED_FILE_KEY];
	else
		[metaData setObject:join forKey:JOINED_FILE_KEY];
}

/*!
 * @brief Returns the file size
 *
 * @return The file size
 */
- (long long)size
{
	return [[metaData objectForKey:SIZE_KEY] longLongValue];
}

/*!
 * @brief Returns the file's duration
 *
 * @return The file's duration
 */
- (float)duration
{
	return [[metaData objectForKey:DURATION_KEY] floatValue];
}

/*!
 * @brief Returns the sample rate of the file
 *
 * @return The sample rate of the file
 */
- (Float64)sampleRate
{
	return [[metaData objectForKey:SAMPLE_RATE_KEY] intValue];
}

/*!
 * @brief Returns the audio format of the file
 *
 * @return The audio format of the file
 */
- (UInt32)audioFormatID
{
	return [[metaData objectForKey:AUDIO_FORMAT_KEY] unsignedIntValue];
}

/*!
 * @brief Returns whether the file has video
 *
 * @return YES if the file has video, NO otherwise
 */
- (BOOL)hasVideo
{
	return [metaData objectForKey:VIDEO_DESC_KEY] != nil;
}

/*Combine the meta data from multiple sources*/
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

/*Destroy cached meta data*/
- (void)combinedDataChanged
{
	/*Remove cached data*/
	[combinedInfo release];
	combinedInfo = nil;
}

/*!
 * @brief Returns the epsiode number of the file
 *
 * @return The episode number of the file
 */
- (int)episodeNumber
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_EPISODE_NUMBER_KEY] intValue] ;
}

/*!
 * @brief Returns the season number of the file
 *
 * @return The season number of the file
 */
- (int)seasonNumber
{
	[self constructCombinedData];
	return [[combinedInfo objectForKey:META_SEASON_NUMBER_KEY] intValue];
}

/*!
 * @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSString *)episodeTitle
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_TITLE_KEY] ;
}

/*!
* @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSString *)movieTitle
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_TITLE_KEY] ;
}

/*!
 * @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSDate *)movieReleaseDate
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_RELEASE_DATE_KEY] ;
}

/*!
 * @brief Returns the show ID of the file
 *
 * @return The show ID of the file
 */
- (NSString *)showID
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_SHOW_IDENTIFIER_KEY];
}

/*!
 * @brief Returns the show name of the file
 *
 * @return The show name of the file
 */
- (NSString *)showName
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_SHOW_NAME_KEY];
}

/*!
* @brief Returns the genre of the movie file
 *
 * @return The genre type of the movie file
 */
- (NSArray *)movieGenres
{
	[self constructCombinedData];
	return [combinedInfo objectForKey:META_MOVIE_GENRES_KEY];
}

/*Makes a pretty size string for the file*/
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

/*See super documentation*/
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
		[ret setObject:[NSString stringWithFormat:@"%@ - %d / %d",[self showName], season, ep] forKey:META_EPISODE_AND_SEASON_KEY];
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
	/*Sort by season first*/
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
	if(myNum == 0)
		myNum = INT_MAX;
	if(theirNum == 0)
		theirNum = INT_MAX;
	if(myNum > theirNum)
		return NSOrderedDescending;
	if(theirNum > myNum)
		return NSOrderedAscending;
	/*Finally sort by name*/
	return [[path lastPathComponent] compare:[[other path] lastPathComponent] options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end