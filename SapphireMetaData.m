//
//  SapphireMetaData.m
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMetaData.h"
#import <QTKit/QTKit.h>

#define FILES_KEY @"Files"
#define DIRS_KEY @"Dirs"
#define META_VERSION_KEY @"Version"
#define META_VERSION 1

#define MODIFIED_KEY @"Modified"
#define WATCHED_KEY @"Watched"
#define SIZE_KEY @"Size"
#define DURATION_KEY @"Duration"
#define SAMPLE_RATE_KEY @"Sample Rate"

@implementation NSString (episodeSorting)

// Custom TV Episode handler 
- (NSComparisonResult) episodeCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@interface SapphireFileMetaData (private)
- (void)updateMetaData;
@end

@implementation SapphireMetaData

// Static set of file extensions to filter
static NSArray *extensions = nil;

+(void)load
{
	extensions = [[NSArray alloc] initWithObjects:@"avi", @"mov", @"mpg", @"wmv", nil];
}

- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super init];
	if(!self)
		return nil;
	
	else if(dict == nil)
		metaData = [NSMutableDictionary new];
	else
		metaData = [dict mutableCopy];
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

- (NSMutableDictionary *)dict
{
	return metaData;
}

- (NSString *)path
{
	return path;
}

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate
{
	delegate = newDelegate;
}

- (void)writeMetaData
{
	[parent writeMetaData];
}

- (void)cancelImport
{
}

- (void)resumeImport
{
}

- (BOOL)isDirectory:(NSString *)fullPath
{
	BOOL isDir = NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir;
}

@end

@implementation SapphireMetaDataCollection

- (id)initWithFile:(NSString *)dictionary path:(NSString *)myPath
{
	self = [super init];
	if(!self)
		return nil;
	
	NSMutableDictionary *mainMetaDictionary = [[NSDictionary dictionaryWithContentsOfFile:dictionary] mutableCopy];
	if(mainMetaDictionary == nil)
	{
		mainMetaDictionary = [[NSMutableDictionary alloc] init];
	}
	else if([[mainMetaDictionary objectForKey:META_VERSION_KEY] intValue] < META_VERSION)
	{
		[mainMetaDictionary removeAllObjects];
		[mainMetaDictionary setObject:[NSNumber numberWithInt:META_VERSION] forKey:META_VERSION_KEY];
	}	
	self = [self initWithDictionary:mainMetaDictionary parent:nil path:myPath];
	if(!self)
		return nil;
	
	dictionaryPath = [dictionary retain];
	mainDirectory = [[SapphireDirectoryMetaData alloc] initWithDictionary:mainMetaDictionary parent:self path:myPath];
	
	return self;
}

- (void)dealloc
{
	[mainDirectory release];
	[dictionaryPath release];
	[super dealloc];
}

- (SapphireDirectoryMetaData *)rootDirectory
{
	return mainDirectory;
}

static void makeParentDir(NSFileManager *manager, NSString *dir)
{
	NSString *parent = [dir stringByDeletingLastPathComponent];
	
	BOOL isDir;
	if(![manager fileExistsAtPath:parent isDirectory:&isDir])
		makeParentDir(manager, parent);
	else if(!isDir)
		//Can't work with this
		return;
	
	[manager createDirectoryAtPath:dir attributes:nil];
}

- (void)writeMetaData
{
	makeParentDir([NSFileManager defaultManager], [dictionaryPath stringByDeletingLastPathComponent]);
	[metaData writeToFile:dictionaryPath atomically:YES];
}

@end

@interface SapphireDirectoryMetaData (private)
- (void)reloadDirectoryContents;
@end

@implementation SapphireDirectoryMetaData

- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:dict parent:myParent path:myPath];
	if(!self)
		return nil;
	
	metaFiles = [metaData objectForKey:FILES_KEY];
	if(metaFiles == nil)
		metaFiles = [NSMutableDictionary dictionary];
	else
		metaFiles = [[metaFiles mutableCopy] autorelease];
	[metaData setObject:metaFiles forKey:FILES_KEY];

	metaDirs = [metaData objectForKey:DIRS_KEY];
	if(metaDirs == nil)
		metaDirs = [NSMutableDictionary dictionary];
	else
		metaDirs = [[metaDirs mutableCopy] autorelease];
	[metaData setObject:metaDirs forKey:DIRS_KEY];
	cachedMetaDirs = [NSMutableDictionary new];
	cachedMetaFiles = [NSMutableDictionary new];
	
	importTimer = nil;
	[self reloadDirectoryContents];
	if([self pruneMetaData] || [self updateMetaData])
		[self writeMetaData];
	[directories sortUsingSelector:@selector(episodeCompare:)];
	[files sortUsingSelector:@selector(episodeCompare:)];
	
	return self;
}

- (void)dealloc
{
	[importTimer invalidate];
	[importArray release];
	[cachedMetaDirs release];
	[cachedMetaFiles release];
	[files release];
	[directories release];
	[super dealloc];
}

- (void)reloadDirectoryContents
{
	[files release];
	[directories release];
	files = [NSMutableArray new];
	directories = [NSMutableArray new];
	
	NSArray *names = [[[NSFileManager defaultManager] directoryContentsAtPath:path] retain];
	
	NSEnumerator *nameEnum = [names objectEnumerator];
	NSString *name = nil;
	// Display Menu Items
	while((name = [nameEnum nextObject]) != nil)
	{
		if([name hasPrefix:@"."])
			continue;
		//Only accept if it is a directory or right extension
		NSString *extension = [name pathExtension];
		if([extensions containsObject:extension])
			[files addObject:name];
		else if([self isDirectory:[path stringByAppendingPathComponent:name]])
			[directories addObject:name];
	}
}

- (NSArray *)files
{
	return files;
}

- (NSArray *)directories
{
	return directories;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	SapphireFileMetaData *ret = [cachedMetaFiles objectForKey:file];
	if(ret == nil)
	{
		ret = [[SapphireFileMetaData alloc] initWithDictionary:[metaFiles objectForKey:file] parent:self path:[path stringByAppendingPathComponent:file]];
		[metaFiles setObject:[ret dict] forKey:file];
		[cachedMetaFiles setObject:ret forKey:file];
		[ret autorelease];
	}
	return ret;
}

- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)file
{
	SapphireDirectoryMetaData *ret = [cachedMetaDirs objectForKey:file];
	if(ret == nil)
	{
		ret = [[SapphireDirectoryMetaData alloc] initWithDictionary:[metaDirs objectForKey:file] parent:self path:[path stringByAppendingPathComponent:file]];
		[metaDirs setObject:[ret dict] forKey:file];
		[cachedMetaDirs setObject:ret forKey:file];
		[ret autorelease];		
	}
	return ret;
}

- (BOOL)pruneMetaData
{
	BOOL ret = NO;
	NSSet *existingSet = [NSSet setWithArray:files];
	NSArray *metaArray = [metaFiles allKeys];
	NSMutableSet *pruneSet = [NSMutableSet setWithArray:metaArray];
	
	[pruneSet minusSet:existingSet];
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		while((pruneKey = [pruneEnum nextObject]) != nil)
			[metaFiles removeObjectForKey:pruneKey];
		ret = YES;		
	}
	
	existingSet = [NSSet setWithArray:directories];
	metaArray = [metaDirs allKeys];
	pruneSet = [NSMutableSet setWithArray:metaArray];
	
	[pruneSet minusSet:existingSet];
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		while((pruneKey = [pruneEnum nextObject]) != nil)
			[metaDirs removeObjectForKey:pruneKey];
		ret = YES;
	}
	
	return ret;
}

- (BOOL)updateMetaData
{
	BOOL ret = NO;
	NSArray *metaArray = [metaDirs allKeys];
	NSSet *metaSet = [NSSet setWithArray:metaArray];
	NSMutableSet *newSet = [NSMutableSet setWithArray:directories];
	
	[newSet minusSet:metaSet];
	if([newSet anyObject] != nil)
	{
		NSEnumerator *newEnum = [newSet objectEnumerator];
		NSString *newKey = nil;
		while((newKey = [newEnum nextObject]) != nil)
			[metaDirs setObject:[NSMutableDictionary dictionary] forKey:newKey];
		ret = YES;
	}
	
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *fileName = nil;
	importArray = [[NSMutableArray alloc] init];
	while((fileName = [fileEnum nextObject]) != nil)
	{
		NSDictionary *fileMeta = [metaFiles objectForKey:fileName];
		if(fileMeta == nil)
			[importArray addObject:fileName];
		else
		{
			NSString *filePath = [path stringByAppendingPathComponent:fileName];
			NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
			NSDate *modDate = [props objectForKey:NSFileModificationDate];
			if([[fileMeta objectForKey:MODIFIED_KEY] intValue] != [modDate timeIntervalSince1970])
				[importArray addObject:fileName];
		}
	}
	[self resumeImport];
	
	return ret;
}

- (void)processFiles:(NSTimer *)timer
{
	NSString *file = [importArray objectAtIndex:0];
	
	[[self metaDataForFile:file] updateMetaData];
	
	[self writeMetaData];
	[delegate updateComplete];
	
	[importArray removeObjectAtIndex:0];
	[self resumeImport];
}

- (void)cancelImport
{
	[importTimer invalidate];
	importTimer = nil;
}

- (void)resumeImport
{
	if([importArray count])
		importTimer = [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(processFiles:) userInfo:nil repeats:NO];
	else
	{
		importTimer = nil;
		[importArray release];
		importArray = nil;
	}
}

- (SapphireMetaData *)metaDataForSubPath:(NSString *)subPath
{
	NSArray *components = [subPath pathComponents];
	NSString *file = [components objectAtIndex:0];
	
	if([self isDirectory:file])
	{
		NSMutableArray *newComp = [components mutableCopy];
		[newComp removeObjectAtIndex:0];
		[newComp autorelease];
		SapphireDirectoryMetaData *nextLevel = [self metaDataForDirectory:file];
		return [nextLevel metaDataForSubPath:[NSString pathWithComponents:newComp]];
	}
	else if([components count] > 1)
		return nil;
	return [self metaDataForFile:file];
}

- (void)scanDirectory
{
	
}

@end

@implementation SapphireFileMetaData : SapphireMetaData

- (void) updateMetaData
{
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	
	if(props != nil)
	{
		NSMutableDictionary *fileMeta = [NSMutableDictionary dictionary];
		
		[fileMeta setObject:[NSNumber numberWithInt:[[props objectForKey:NSFileModificationDate] timeIntervalSince1970]] forKey:MODIFIED_KEY];
		[fileMeta setObject:[props objectForKey:NSFileSize] forKey:SIZE_KEY];
		
		NSError *error = nil;
		QTMovie *movie = [QTMovie movieWithFile:path error:&error];
		QTTime duration = [movie duration];
		[fileMeta setObject:[NSNumber numberWithFloat:(float)duration.timeValue/(float)duration.timeScale] forKey:DURATION_KEY];
		NSArray *audioTracks = [movie tracksOfMediaType:@"soun"];
		NSNumber *audioSampleRate = nil;
		if([audioTracks count])
			[[[audioTracks objectAtIndex:0] media] attributeForKey:QTMediaTimeScaleAttribute];
		if(audioSampleRate != nil)
			[fileMeta setObject:audioSampleRate forKey:SAMPLE_RATE_KEY];
		[metaData addEntriesFromDictionary:fileMeta];
	}
}

- (int)modified
{
	return [[metaData objectForKey:MODIFIED_KEY] intValue];
}

- (BOOL)watched
{
	return [[metaData objectForKey:WATCHED_KEY] boolValue];
}

- (void)setWatched
{
	[metaData setObject:[NSNumber numberWithBool:YES] forKey:WATCHED_KEY];
}

- (long long)size
{
	return [[metaData objectForKey:SIZE_KEY] longLongValue];
}

- (float)duration
{
	return [[metaData objectForKey:DURATION_KEY] floatValue];
}

- (int)sampleRate
{
	return [[metaData objectForKey:SAMPLE_RATE_KEY] intValue];
}

@end