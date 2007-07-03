//
//  SapphireMetaData.m
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMetaData.h"
#import <QTKit/QTKit.h>
#include <sys/types.h>
#include <sys/stat.h>
#import "SapphireSettings.h"

//Structure Specific Keys
#define FILES_KEY					@"Files"
#define DIRS_KEY					@"Dirs"
#define META_VERSION_KEY			@"Version"
#define META_VERSION				1

//File Specific Keys
#define MODIFIED_KEY					@"Modified"
#define WATCHED_KEY					@"Watched"
#define FAVORITE_KEY					@"Favorite"
#define RESUME_KEY					@"Resume Time"
#define SIZE_KEY						@"Size"
#define DURATION_KEY					@"Duration"
#define AUDIO_DESC_KEY				@"Audio Description"
#define SAMPLE_RATE_KEY				@"Sample Rate"
#define VIDEO_DESC_KEY				@"Video Description"

//TV Show Specific Keys
#define EPISODE_NUMBER_KEY			@"Episode"
#define EPISODE_TITLE_KEY				@"Title"
#define SEASON_NUMBER_KEY			@"Season"
#define SHOW_NAME_KEY				@"Show Name"
#define SHOW_DESCRIPTION_KEY		@"Show Description"
#define SHOW_AIR_DATE				@"Air Date"

//ATV Extra Info
/*
#define SHOW_BROADCASTER_KEY		@"Broadcast Company"
#define SHOW_PUBLISHED_DATE_KEY	@"Published Date"
#define SHOW_AQUIRED_DATE			@"Date Aquired"
#define SHOW_RATING_KEY				@"Rating"
#define SHOW_FAVORITE_RATING		@"User Rating"
*/
//IMDB Type Info


@implementation NSString (episodeSorting)

- (NSComparisonResult) directoryNameCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@implementation SapphireMetaData

// Static set of file extensions to filter
static NSSet *extensions = nil;

+(void)load
{
	extensions = [[NSSet alloc] initWithObjects:@"avi", @"mov", @"mpg", @"mpeg", @"wmv",@"mkv", @"flv", @"divx", @"mp4", nil];
}

- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath
{
	self = [super init];
	if(!self)
		return nil;
	
	if(dict == nil)
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

- (BOOL)isDirectory:(NSString *)fullPath
{
	BOOL isDir = NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir;
}

- (NSMutableDictionary *)getDisplayedMetaData
{
	return nil;
}

@end

@implementation SapphireMetaDataCollection

- (id)initWithFile:(NSString *)dictionary path:(NSString *)myPath
{
	self = [super init];
	if(!self)
		return nil;
	
	dictionaryPath = [dictionary retain];
	NSDictionary *metaDict = [NSDictionary dictionaryWithContentsOfFile:dictionary];
	mainDirectory = [[SapphireDirectoryMetaData alloc] initWithDictionary:metaDict parent:self path:myPath];
	metaData = [[mainDirectory dict] retain];
	[metaData setObject:[NSNumber numberWithInt:META_VERSION] forKey:META_VERSION_KEY];
	
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
	[[mainDirectory dict] writeToFile:dictionaryPath atomically:YES];
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
		metaFiles = [NSMutableDictionary new];
	else
		metaFiles = [metaFiles mutableCopy];
	[metaData setObject:metaFiles forKey:FILES_KEY];
	[metaFiles release];

	metaDirs = [metaData objectForKey:DIRS_KEY];
	if(metaDirs == nil)
		metaDirs = [NSMutableDictionary new];
	else
		metaDirs = [metaDirs mutableCopy];
	[metaData setObject:metaDirs forKey:DIRS_KEY];
	[metaDirs release];
	
	cachedMetaDirs = [NSMutableDictionary new];
	cachedMetaFiles = [NSMutableDictionary new];
	
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
	NSMutableArray *fileMetas = [NSMutableArray array];
	
	NSArray *names = [[NSFileManager defaultManager] directoryContentsAtPath:path];
	
	NSEnumerator *nameEnum = [names objectEnumerator];
	NSString *name = nil;
	// Display Menu Items
	while((name = [nameEnum nextObject]) != nil)
	{
		if([name hasPrefix:@"."])
			continue;
		if([name isEqualToString:@"Cover Art"])
			continue;
		//Only accept if it is a directory or right extension
		NSString *extension = [name pathExtension];
		if([self isDirectory:[path stringByAppendingPathComponent:name]])
			[directories addObject:name];
		else if([extensions containsObject:extension])
			[fileMetas addObject:[self metaDataForFile:name]];
	}
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[fileMetas sortUsingSelector:@selector(episodeCompare:)];
	nameEnum = [fileMetas objectEnumerator];
	SapphireFileMetaData *fileMeta = nil;
	while((fileMeta = [nameEnum nextObject]) != nil)
		[files addObject:[[fileMeta path] lastPathComponent]];
	[self updateMetaData];
	if([importArray count])
		[self writeMetaData];
	scannedDirectory = YES;
}

- (NSArray *)files
{
	return files;
}

- (NSArray *)directories
{
	return directories;
}

- (BOOL)hasPredicatedFiles:(SapphirePredicate *)predicate
{
	NSArray *filesToScan = files;
	if(!scannedDirectory)
		filesToScan = [metaFiles allKeys];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		BOOL include = NO;
		if([metaFiles objectForKey:file] != nil)
		{
			SapphireFileMetaData *meta = [self metaDataForFile:file];
			include = [predicate accept:[meta path] meta:meta];
		}
		else
			include = [predicate accept:[path stringByAppendingPathComponent:file] meta:nil];
		if(include)
			return YES;
	}
	return NO;
}

- (BOOL)hasXMLMetaData:(NSString *)file
{
//	NSString *extension = [file pathExtension] ;

	return FALSE ;
}

- (BOOL)hasPredicatedDirectories:(SapphirePredicate *)predicate
{
	NSArray *directoriesToScan = directories;
	if(!scannedDirectory)
		directoriesToScan = [metaDirs allKeys];
	NSEnumerator *directoryEnum = [directoriesToScan objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		if(![[SapphireSettings sharedSettings] fastSwitching])
			[meta reloadDirectoryContents];
		
		if([meta hasPredicatedFiles:predicate] || [meta hasPredicatedDirectories:predicate])
			return YES;
	}
	return NO;
}

- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate
{
	NSMutableArray *ret = [NSMutableArray array];
	NSArray *filesToScan = files;
	if(!scannedDirectory)
		filesToScan = [metaFiles allKeys];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		BOOL include = NO;
		if([metaFiles objectForKey:file] != nil)
		{
			SapphireFileMetaData *meta = [self metaDataForFile:file];
			include = [predicate accept:[meta path] meta:meta];
		}
		else
			include = [predicate accept:[path stringByAppendingPathComponent:file] meta:nil];
		if(include)
			[ret addObject:file];
	}
	return ret;
}
- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate
{
	NSMutableArray *ret = [NSMutableArray array];
	NSArray *directoriesToScan = directories;
	if(!scannedDirectory)
		directoriesToScan = [metaDirs allKeys];
	NSEnumerator *directoryEnum = [directoriesToScan objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		if(![[SapphireSettings sharedSettings] fastSwitching])
			[meta reloadDirectoryContents];

		if([meta hasPredicatedFiles:predicate] || [meta hasPredicatedDirectories:predicate])
			[ret addObject:directory];
	}
	return ret;
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
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *fileName = nil;
	importArray = [[NSMutableArray alloc] init];
	while((fileName = [fileEnum nextObject]) != nil)
	{
		NSDictionary *fileMeta = [metaFiles objectForKey:fileName];
		if(fileMeta == nil)
		{
			[self metaDataForFile:fileName];
			[importArray addObject:fileName];
		}
		else
		{
			NSString *filePath = [path stringByAppendingPathComponent:fileName];
			struct stat sb;
			memset(&sb, 0, sizeof(struct stat));
			stat([filePath fileSystemRepresentation], &sb);
			long modTime = sb.st_mtimespec.tv_sec;
			if([[fileMeta objectForKey:MODIFIED_KEY] intValue] != modTime || [[fileMeta objectForKey:META_VERSION_KEY] intValue] != META_VERSION)
				[importArray addObject:fileName];
		}
	}
	return NO;
}

- (void)processFiles:(NSTimer *)timer
{
	NSString *file = [importArray objectAtIndex:0];
	
	[[self metaDataForFile:file] updateMetaData];
	
	[self writeMetaData];
	[delegate updateCompleteForFile:file];
	
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
	[importTimer invalidate];
	if([importArray count])
		importTimer = [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(processFiles:) userInfo:nil repeats:NO];
	else
	{
		importTimer = nil;
		[importArray release];
		importArray = nil;
	}
}

- (void)resumeDelayedImport
{
	[importTimer invalidate];
	if([importArray count])
		importTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resumeImport) userInfo:nil repeats:NO];
	else
		importTimer = nil;
}

- (SapphireMetaData *)metaDataForSubPath:(NSString *)subPath
{
	NSArray *components = [subPath pathComponents];
	if(![components count])
		return self;
	NSString *file = [components objectAtIndex:0];
	
	if([self isDirectory:[path stringByAppendingPathComponent:file]])
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

- (NSArray *)subFileMetas
{
	NSMutableArray *ret = [[NSMutableArray alloc] init];
	[self reloadDirectoryContents];
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *dirMeta = [self metaDataForDirectory:dir];
		if(dirMeta != nil)
			[ret addObjectsFromArray:[dirMeta subFileMetas]];
	}
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *fileMeta = [self metaDataForFile:file];
		if(fileMeta != nil)
			[ret addObject:fileMeta];
	}
	return [ret autorelease];
}

- (void)scanForNewFiles
{
	[self reloadDirectoryContents];
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *dirMeta = [self metaDataForDirectory:dir];
		if(dirMeta != nil)
			[dirMeta scanForNewFiles];
	}
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		[self metaDataForFile:file];
}

- (void)setupFiles:(NSArray * *)filesToScan andDirectories:(NSArray * *)directoriesToScan arraysForPredicate:(SapphirePredicate *)predicate
{
	if(predicate)
	{
		*filesToScan = [self predicatedFiles:predicate];
		*directoriesToScan = [self predicatedDirectories:predicate];
	}
	else if(!scannedDirectory)
	{
		//Likely haven't scanned the directory yet, so use cached
		*filesToScan = [metaFiles allKeys];
		*directoriesToScan = [metaDirs allKeys];
	}
}

- (BOOL)checkResult:(BOOL)result recursivelyOnFiles:(NSInvocation *)fileInv forPredicate:(SapphirePredicate *)predicate
{
	NSArray *filesToScan = files;
	NSArray *directoriesToScan = directories;
	[self setupFiles:&filesToScan andDirectories:&directoriesToScan arraysForPredicate:predicate];
	NSEnumerator *fileEnum = [filesToScan objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		[fileInv invokeWithTarget:[self metaDataForFile:file]];
		BOOL result = NO;
		[fileInv getReturnValue:&result];
		if(result == result)
			return result;
	}

	NSEnumerator *dirEnum = [directoriesToScan objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		if([[self metaDataForDirectory:dir] checkResult:result recursivelyOnFiles:fileInv forPredicate:predicate] == result)
			return result;
	
	return !result;
}

- (void)invokeRecursivelyOnFiles:(NSInvocation *)fileInv withPredicate:(SapphirePredicate *)predicate
{
	[self reloadDirectoryContents];
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		[[self metaDataForDirectory:dir] invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
	
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *fileMeta = [self metaDataForFile:file];
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

- (void)setWatched:(BOOL)watched predicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setWatched:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&watched atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
}

- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(favorite);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	return [self checkResult:YES recursivelyOnFiles:fileInv forPredicate:predicate];	
}

- (void)setFavorite:(BOOL)favorite predicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setFavorite:);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[fileInv setArgument:&favorite atIndex:2];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
}

- (void)setToImportFromTVForPredicate:(SapphirePredicate *)predicate
{
	SEL select = @selector(setToImportFromTV);
	NSInvocation *fileInv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[fileInv setSelector:select];
	[self invokeRecursivelyOnFiles:fileInv withPredicate:predicate];
}

- (NSMutableDictionary *)getDisplayedMetaData
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[path lastPathComponent], META_TITLE_KEY,
		nil];
}

@end

@implementation SapphireFileMetaData : SapphireMetaData

static NSDictionary *metaDataSubstitutions = nil;
static NSSet *displayedMetaData = nil;

+ (void) initialize
{
	metaDataSubstitutions = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Video", VIDEO_DESC_KEY,
		@"Audio", AUDIO_DESC_KEY,
		nil];
	displayedMetaData = [[NSSet alloc] initWithObjects:
		VIDEO_DESC_KEY,
		AUDIO_DESC_KEY,
		META_RATING_KEY,
		META_SUMMARY_KEY,
		META_COPYRIGHT_KEY,
		META_TITLE_KEY,
		nil];
		
}

- (BOOL) updateMetaData
{
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
	BOOL updated =FALSE;
	
	if(props == nil)
		//No file
		return FALSE;
	
	if(modTime != [self modified] || [[metaData objectForKey:META_VERSION_KEY] intValue] != META_VERSION)
	{
		updated=TRUE ;
		NSMutableDictionary *fileMeta = [NSMutableDictionary dictionary];
		
		[fileMeta setObject:[NSNumber numberWithInt:modTime] forKey:MODIFIED_KEY];
		[fileMeta setObject:[props objectForKey:NSFileSize] forKey:SIZE_KEY];
		[fileMeta setObject:[NSNumber numberWithInt:META_VERSION] forKey:META_VERSION_KEY];
		
		NSError *error = nil;
		QTMovie *movie = [QTMovie movieWithFile:path error:&error];
		QTTime duration = [movie duration];
		[fileMeta setObject:[NSNumber numberWithFloat:(float)duration.timeValue/(float)duration.timeScale] forKey:DURATION_KEY];
		NSArray *audioTracks = [movie tracksOfMediaType:@"soun"];
		NSNumber *audioSampleRate = nil;
		if([audioTracks count])
		{
			QTTrack *track = [audioTracks objectAtIndex:0];
			QTMedia *media = [track media];
			audioSampleRate = [media attributeForKey:QTMediaTimeScaleAttribute];
			if(media != nil)
			{
				Media qtMedia = [media quickTimeMedia];
				Handle sampleDesc = NewHandle(1);
				GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc);
				CFStringRef userText = nil;
				ByteCount	propSize = 0;
				QTSoundDescriptionGetProperty((SoundDescriptionHandle)sampleDesc, kQTPropertyClass_SoundDescription, kQTSoundDescriptionPropertyID_UserReadableText, sizeof(userText), &userText, &propSize);
				DisposeHandle(sampleDesc);
				
				if(userText != nil)
				{
					[fileMeta setObject:(NSString *)userText forKey:AUDIO_DESC_KEY];
					CFRelease(userText);
				}
			}
		}
		if(audioSampleRate != nil)
			[fileMeta setObject:audioSampleRate forKey:SAMPLE_RATE_KEY];
		NSArray *videoTracks = [movie tracksOfMediaType:@"vide"];
		if([videoTracks count])
		{
			QTTrack *track = [videoTracks objectAtIndex:0];
			QTMedia *media = [track media];
			if(media != nil)
			{
				Media qtMedia = [media quickTimeMedia];
				Handle sampleDesc = NewHandle(1);
				GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc);
				CFStringRef userText = nil;
				ByteCount	propSize = 0;
				ICMImageDescriptionGetProperty((ImageDescriptionHandle)sampleDesc, kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_SummaryString, sizeof(userText), &userText, &propSize);
				DisposeHandle(sampleDesc);
				
				if(userText != nil)
				{
					[fileMeta setObject:(NSString *)userText forKey:VIDEO_DESC_KEY];
					CFRelease(userText);
				}
			}
		}
		[metaData addEntriesFromDictionary:fileMeta];
	}
	return updated ;
}

- (void)importInfo:(NSDictionary *)newMeta
{
	[metaData addEntriesFromDictionary:newMeta];
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

- (BOOL)importedFromTV
{
	return [[metaData objectForKey:TVRAGE_IMPORT_KEY] boolValue];
}

- (void)setToImportFromTV
{
	[metaData removeObjectForKey:TVRAGE_IMPORT_KEY];
}

- (unsigned int)resumeTime
{
	return [[metaData objectForKey:RESUME_KEY] unsignedIntValue];
}

- (void)setResumeTime:(unsigned int)resumeTime
{
	[metaData setObject:[NSNumber numberWithUnsignedInt:resumeTime] forKey:RESUME_KEY];
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

- (int)episodeNumber
{
	return [[metaData objectForKey:EPISODE_NUMBER_KEY] intValue] ;
}

- (int)seasonNumber
{
	return [[metaData objectForKey:SEASON_NUMBER_KEY] intValue];
}

- (NSString *)episodeTitle
{
	NSString * title = [metaData objectForKey:EPISODE_TITLE_KEY] ;
	if(title!=nil)return title ;
	else
	return nil ;
}

- (NSString *)sizeString
{
	float size = [self size];
	if(size == 0)
		return @"-";
	char letter = ' ';
	if(size >= 1024000)
	{
		if(size >= 1024*1024000)
		{
			size /= 1024 * 1024 * 1024;
			letter = 'G';
		}
		else
		{
			size /= 1024 * 1024;
			letter = 'M';
		}
	}
	else if (size >= 1000)
	{
		size /= 1024;
		letter = 'K';
	}
	return [NSString stringWithFormat:@"%.1f%cB", size, letter];	
}

- (NSMutableDictionary *)getDisplayedMetaData
{
	NSString *name = [path lastPathComponent];
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
	NSMutableDictionary *ret = [metaData mutableCopy];
	//Pretty this up now
	NSMutableSet *currentKeys = [NSMutableSet setWithArray:[ret allKeys]];
	[currentKeys minusSet:displayedMetaData];
	[ret removeObjectsForKeys:[currentKeys allObjects]];
	
	NSEnumerator *subEnum = [metaDataSubstitutions keyEnumerator];
	NSString *key = nil;
	while((key = [subEnum nextObject]) != nil)
	{
		NSString *value = [ret objectForKey:key];
		if(value != nil)
		{
			[ret setObject:value forKey:[metaDataSubstitutions objectForKey:key]];
			[ret removeObjectForKey:key];
		}
	}
	if([self duration])
		[ret setObject:durationStr forKey:DURATION_KEY];
	if([ret objectForKey:META_TITLE_KEY] == nil)
		[ret setObject:name forKey:META_TITLE_KEY];\
	if([self size])
		[ret setObject:[self sizeString] forKey:SIZE_KEY];
	return ret;
}

// Custom TV Episode handler 
- (NSComparisonResult) episodeCompare:(SapphireFileMetaData *)other
{
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
	return [[path lastPathComponent] compare:[[other path] lastPathComponent] options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end