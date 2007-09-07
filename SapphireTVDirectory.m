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
@end

@implementation SapphireTVDirectory
- (id)initWithParent:(SapphireTVBaseDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithParent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileAdded:) name:META_DATA_FILE_ADDED_NOTIFICATION object:nil];
	
	return self;
}

- (void)fileAdded:(NSNotification *)notification
{
	SapphireFileMetaData *file = [notification object];
	[self processFile:file];
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
@end

@implementation SapphireSeasonDirectory
- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] initWithDictionary:directory];
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireFileMetaData *file = [directory objectForKey:key];
		if(![fm fileExistsAtPath:[file path]])
			[mutDict removeObjectForKey:key];
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
	NSString *ep = [NSString stringWithFormat:BRLocalizedString(@"Episode %d", @"Episode name"), epNum];
	[directory setObject:file forKey:ep];
	[self setReloadTimer];
}
@end