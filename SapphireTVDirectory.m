//
//  SapphireTVDirectory.m
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTVDirectory.h"
#import "SapphireMetaData.h"

@interface SapphireDirectoryMetaData (privateFunctions)
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath;
@end

@implementation SapphireTVBaseDirectory
- (id)initWithParent:(SapphireTVBaseDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:nil parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	directory = [[NSMutableDictionary alloc] init];
	reloadTimer = nil;
	scannedDirectory = YES;
	
	return self;
}

- (id)init
{
	return [self initWithParent:nil path:@"@TV"];
}

- (void) dealloc
{
	[directory dealloc];
	[reloadTimer invalidate];
	[super dealloc];
}

- (void)reloadDirectoryContents
{
	[files removeAllObjects];
	[directories removeAllObjects];
	[metaFiles removeAllObjects];
	[metaDirs removeAllObjects];
	[cachedMetaFiles removeAllObjects];
	[cachedMetaDirs removeAllObjects];
	[reloadTimer invalidate];
	reloadTimer = nil;
}

- (void)setReloadTimer
{
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reloadDirectoryContents) userInfo:nil repeats:NO];
}

- (void)processFile:(SapphireFileMetaData *)file
{
}

- (void)removeFile:(SapphireFileMetaData *)file
{
}
@end

@implementation SapphireTVDirectory
- (id)initWithParent:(SapphireTVBaseDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithParent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileAdded:) name:META_DATA_FILE_ADDED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileRemoved:) name:META_DATA_FILE_REMOVED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileInfoHasChanged:) name:META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileInfoWillChanged:) name:META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION object:nil];
	
	return self;
}

- (void)fileAdded:(NSNotification *)notification
{
	SapphireFileMetaData *file = [notification object];
	[self processFile:file];
}

- (void)fileRemoved:(NSNotification *)notification
{
	SapphireFileMetaData *file = [notification object];
	[self removeFile:file];
}

- (void)fileInfoHasChanged:(NSNotification *)notification
{
	NSDictionary *info = [notification userInfo];
	if(![[info objectForKey:META_DATA_FILE_INFO_KIND] isEqualToString:META_TVRAGE_IMPORT_KEY])
		return;
	SapphireFileMetaData *file = [notification object];
	[self processFile:file];
}

- (void)fileInfoWillChanged:(NSNotification *)notification
{
	NSDictionary *info = [notification userInfo];
	if(![[info objectForKey:META_DATA_FILE_INFO_KIND] isEqualToString:META_TVRAGE_IMPORT_KEY])
		return;
	SapphireFileMetaData *file = [notification object];
	[self removeFile:file];
}

- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	[directories addObjectsFromArray:[directory allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaDirs addEntriesFromDictionary:directory];
	[metaDirs addEntriesFromDictionary:directory];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	NSString *show = [file showName];
	if(show == nil)
		return;
	SapphireShowDirectory *showInfo = [directory objectForKey:show];
	if(showInfo == nil)
	{
		showInfo = [[SapphireShowDirectory alloc] initWithParent:self path:[[self path] stringByAppendingPathComponent:show]];
		[directory setObject:showInfo forKey:show];
		[showInfo release];
		[self setReloadTimer];
	}
	[showInfo processFile:file];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSString *show = [file showName];
	if(show == nil)
		return;
	SapphireShowDirectory *showInfo = [directory objectForKey:show];
	if(showInfo != nil)
	{
		[showInfo removeFile:file];
		if([[showInfo directories] count] == 0)
		{
			[directory removeObjectForKey:show];
			[self setReloadTimer];
		}
	}
}
@end

@implementation SapphireShowDirectory
- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	[directories addObjectsFromArray:[directory allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaDirs addEntriesFromDictionary:directory];
	[metaDirs addEntriesFromDictionary:directory];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	NSString *season = [NSString stringWithFormat:BRLocalizedString(@"Season %d", @"Season name"), seasonNum];
	SapphireSeasonDirectory *seasonInfo = [directory objectForKey:season];
	if(seasonInfo == nil)
	{
		seasonInfo = [[SapphireSeasonDirectory alloc] initWithParent:self path:[[self path] stringByAppendingPathComponent:season]];
		[directory setObject:seasonInfo forKey:season];
		[seasonInfo release];
		[self setReloadTimer];
	}
	[seasonInfo processFile:file];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	NSString *season = [NSString stringWithFormat:BRLocalizedString(@"Season %d", @"Season name"), seasonNum];
	SapphireSeasonDirectory *seasonInfo = [directory objectForKey:season];
	if(seasonInfo == nil)
	{
		[seasonInfo removeFile:file];
		if([[seasonInfo directories] count] == 0)
		{
			[directory removeObjectForKey:season];
			[self setReloadTimer];
		}
	}
}
@end

@implementation SapphireSeasonDirectory
- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireFileMetaData *file = [directory objectForKey:key];
		if([fm fileExistsAtPath:[file path]])
		{
			NSString *ep = [NSString stringWithFormat:BRLocalizedString(@"Episode %d", @"Episode name"), [file episodeNumber]];
			[mutDict setObject:file forKey:ep];
		}
	}
	[files addObjectsFromArray:[mutDict allKeys]];
	[files sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaFiles addEntriesFromDictionary:mutDict];
	[metaFiles addEntriesFromDictionary:mutDict];
	[mutDict release];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	int epNum = [file episodeNumber];
	if(epNum == 0)
		return;
	[directory setObject:file forKey:[file path]];
	[self setReloadTimer];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	int epNum = [file episodeNumber];
	if(epNum == 0)
		return;
	[directory removeObjectForKey:[file path]];
	[self setReloadTimer];
}
@end