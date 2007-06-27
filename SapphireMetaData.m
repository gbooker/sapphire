//
//  SapphireMetaData.m
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMetaData.h"
#import <QTKit/QTKit.h>

//Structure Specific Keys
#define FILES_KEY					@"Files"
#define DIRS_KEY					@"Dirs"
#define META_VERSION_KEY			@"Version"
#define META_VERSION				1

//File Specific Keys
#define MODIFIED_KEY			@"Modified"
#define WATCHED_KEY				@"Watched"
#define FAVORITE_KEY			@"Favorite"
#define RESUME_KEY				@"Resume Time"
#define SIZE_KEY				@"Size"
#define DURATION_KEY			@"Duration"
#define AUDIO_DESC_KEY			@"Audio Description"
#define SAMPLE_RATE_KEY			@"Sample Rate"
#define VIDEO_DESC_KEY			@"Video Description"

//TV Show Specific Keys
#define EPISODE_NUMBER_KEY		@"Episode Number"
#define EPISODE_TITLE_KEY		@"Episode Title"
#define SEASON_NUMBER_KEY		@"Season"
#define SHOW_NAME_KEY			@"Show Name"
#define SHOW_DESCRIPTION_KEY	@"Show Description"
#define SHOW_AIR_DATE			@"Air Date"


@implementation NSString (episodeSorting)

// Custom TV Episode handler 
- (NSComparisonResult) episodeCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@implementation SapphireMetaData

// Static set of file extensions to filter
static NSArray *extensions = nil;

+(void)load
{
	extensions = [[NSArray alloc] initWithObjects:@"avi", @"mov", @"mpg", @"wmv",@"mkv", nil];
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
	[mainMetaDictionary setObject:[NSNumber numberWithInt:META_VERSION] forKey:META_VERSION_KEY];
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
	[directories sortUsingSelector:@selector(episodeCompare:)];
	[files sortUsingSelector:@selector(episodeCompare:)];
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
	NSEnumerator *fileEnum = [files objectEnumerator];
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

- (BOOL)hasPredicatedDirectories:(SapphirePredicate *)predicate
{
	NSEnumerator *directoryEnum = [directories objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		[meta cancelImport];
		
		if([meta hasPredicatedFiles:predicate] || [meta hasPredicatedDirectories:predicate])
			return YES;
	}
	return NO;
}

- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate
{
	NSMutableArray *ret = [NSMutableArray array];
	NSEnumerator *fileEnum = [files objectEnumerator];
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
	NSEnumerator *directoryEnum = [directories objectEnumerator];
	NSString *directory = nil;
	while((directory = [directoryEnum nextObject]) != nil)
	{
		SapphireDirectoryMetaData *meta = [self metaDataForDirectory:directory];
		[meta cancelImport];

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
			if([[fileMeta objectForKey:MODIFIED_KEY] intValue] != [modDate timeIntervalSince1970] || [[fileMeta objectForKey:META_VERSION_KEY] intValue] != META_VERSION)
				[importArray addObject:fileName];
		}
	}
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
	[importTimer invalidate];
	if([importArray count])
		importTimer = [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(processFiles:) userInfo:nil repeats:NO];
	else
	{
		[importTimer invalidate];
		importTimer = nil;
		[importArray release];
		importArray = nil;
	}
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

- (void)processAllFiles
{
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		[[self metaDataForFile:file] updateMetaData];
}

- (void)scanDirectory
{
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *directory = nil;
	while((directory = [dirEnum nextObject]) != nil)
		[[self metaDataForDirectory:directory] scanDirectory];
}

- (NSArray *)subFileMetas
{
	NSMutableArray *ret = [[NSMutableArray alloc] init];
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
	return ret;
}

- (void)preloadMetaData
{
	[self scanDirectory];
	[self processAllFiles];
}

- (BOOL)watched
{
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		if(![[self metaDataForFile:file] watched])
			return NO;

	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		if(![[self metaDataForDirectory:dir] watched])
			return NO;

	return YES;
}

- (void)setWatched:(BOOL)watched
{
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		[[self metaDataForDirectory:dir] setWatched:watched];
	
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		[[self metaDataForFile:file] setWatched:watched];
}

- (BOOL)favorite
{
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		if([[self metaDataForFile:file] favorite])
			return YES;

	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		if([[self metaDataForDirectory:dir] favorite])
			return YES;
	
	return NO;
}

- (void)setFavorite:(BOOL)favorite
{
	NSEnumerator *dirEnum = [directories objectEnumerator];
	NSString *dir = nil;
	while((dir = [dirEnum nextObject]) != nil)
		[[self metaDataForDirectory:dir] setFavorite:favorite];
	
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
		[[self metaDataForFile:file] setFavorite:favorite];
}

@end

@implementation SapphireFileMetaData : SapphireMetaData

- (void) updateMetaData
{
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
	
	if(props == nil)
		//No file
		return;
	
	if(modTime != [self modified] || [[metaData objectForKey:META_VERSION_KEY] intValue] != META_VERSION)
	{
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

- (NSString *)metaDataDescription
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
	NSMutableString *ret = [NSMutableString stringWithFormat:
												   @"Name: \t%@\n"
													"Duration: \t%@\n"
													"Size: \t%@", name, durationStr, [self sizeString]];
	NSString *videoDesc = [metaData objectForKey:VIDEO_DESC_KEY];
	if(videoDesc != nil)
		[ret appendFormat:@"\nVideo: \t%@", videoDesc];
	NSString *audioDesc = [metaData objectForKey:AUDIO_DESC_KEY];
	if(audioDesc != nil)
		[ret appendFormat:@"\nAudio: \t%@", audioDesc];
	return ret;
}

@end