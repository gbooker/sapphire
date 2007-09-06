//
//  SapphireTVDirectory.m
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTVDirectory.h"
#import "SapphireMetaData.h"

@implementation SapphireTVBaseDirectory
- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	directory = [[NSMutableDictionary alloc] init];
	reloadTimer = nil;
	
	return self;
}

- (void) dealloc
{
	[directory dealloc];
	[reloadTimer invalidate];
	[super dealloc];
}

- (void)reloadDirectoryContents
{
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
- (id)init
{
	self = [super init];
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
	[files removeAllObjects];
	[directories removeAllObjects];
	[directories addObjectsFromArray:[directory allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[super reloadDirectoryContents];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	NSString *show = [file showName];
	SapphireShowDirectory *showInfo = [directory objectForKey:show];
	if(showInfo == nil)
	{
		showInfo = [[SapphireShowDirectory alloc] init];
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
	[files removeAllObjects];
	[directories removeAllObjects];
	[directories addObjectsFromArray:[directory allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[super reloadDirectoryContents];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	NSNumber *season = [NSNumber numberWithInt:[file seasonNumber]];
	SapphireSeasonDirectory *seasonInfo = [directory objectForKey:season];
	if(seasonInfo == nil)
	{
		seasonInfo = [[SapphireShowDirectory alloc] init];
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
	[files removeAllObjects];
	[directories removeAllObjects];

	NSMutableArray *fileMetas = [NSMutableArray array];
	[fileMetas addObjectsFromArray:[directory allValues]];
	[fileMetas sortUsingSelector:@selector(episodeCompare:)];

	NSEnumerator *fileEnum = [fileMetas objectEnumerator];
	SapphireFileMetaData *fileMeta = nil;
	while((fileMeta = [fileEnum nextObject]) != nil)
		[files addObject:[[fileMeta path] lastPathComponent]];
	[super reloadDirectoryContents];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	NSNumber *ep = [NSNumber numberWithInt:[file episodeNumber]];
	[directory setObject:file forKey:ep];
	[self setReloadTimer];
}
@end