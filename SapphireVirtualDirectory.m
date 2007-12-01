//
//  SapphireVirtualDirectory.m
//  Sapphire
//
//  Created by Graham Booker on 11/18/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"


@interface SapphireDirectoryMetaData (privateFunctions)
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath;
@end

@implementation SapphireVirtualDirectory
- (id)initWithParent:(SapphireVirtualDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:nil parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	directory = [[NSMutableDictionary alloc] init];
	virtualCoverArt=[[NSMutableDictionary alloc] init];
	reloadTimer = nil;
	scannedDirectory = YES;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(startedLoading:) name:META_DATA_FILE_INFO_STARTED_LOADING object:nil];
	[nc addObserver:self selector:@selector(finishedLoading:) name:META_DATA_FILE_INFO_FINISHED_LOADING object:nil];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[directory release];
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
	if(!loading)
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reloadDirectoryContents) userInfo:nil repeats:NO];
	else
		reloadTimer = nil;
}

- (void)processFile:(SapphireFileMetaData *)file
{
}

- (void)removeFile:(SapphireFileMetaData *)file
{
}

- (NSString *)coverArtPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"PH" ofType:@"png"];
}

- (void)childDisplayChanged
{
	/*The way the timings work out, if the timer exists already, it is more efficient to leave it set rather than set a new one*/
	if(reloadTimer == nil)
		[self setReloadTimer];
}

- (NSMutableDictionary *)directoryEntries
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	NSEnumerator *pathEnum = [directory keyEnumerator];
	NSString *subPath = nil;
	while((subPath = [pathEnum nextObject]) != nil)
	{
		SapphireMetaData *data = [directory objectForKey:subPath];
		if([data isKindOfClass:[SapphireVirtualDirectory class]])
			[ret setObject:[(SapphireVirtualDirectory *)data directoryEntries] forKey:subPath];
		else
			[ret setObject:[data path] forKey:subPath];
	}
	return ret;
}

- (void)writeToFile:(NSString *)filePath
{
	NSMutableDictionary *fileData = [self directoryEntries];
	[fileData writeToFile:filePath	atomically:YES];
}

- (BOOL)isDisplayEmpty
{
	return [files count] == 0 && [directories count] == 0;
}

- (BOOL)isEmpty
{
	return [directory count] == 0;
}

- (BOOL)isLoaded
{
	return !loading && reloadTimer == nil;
}

- (void)startedLoading:(NSNotification *)note
{
	loading = YES;
}

- (void)finishedLoading:(NSNotification *)note
{
	if(loading == NO)
		//Already handled
		return;
	loading = NO;
	[self setReloadTimer];
}

@end

@implementation SapphireVirtualDirectoryOfDirectories
- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireVirtualDirectory *dir = [directory objectForKey:key];
		if(![dir isDisplayEmpty])
			[mutDict setObject:dir forKey:key];
	}
	[directories addObjectsFromArray:[mutDict allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaDirs addEntriesFromDictionary:mutDict];
	[metaDirs addEntriesFromDictionary:mutDict];
	[mutDict release];
	[(SapphireVirtualDirectory *)parent childDisplayChanged];
	reloadTimer = nil;
}

- (void)finishedLoading:(NSNotification *)note
{
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireVirtualDirectory *dir = [directory objectForKey:key];
		[dir finishedLoading:note];
	}
	[super finishedLoading:note];
}

- (BOOL)addFile:(SapphireFileMetaData *)file toKey:(NSString *)key withChildClass:(Class)childClass
{
	BOOL added = NO;
	SapphireVirtualDirectory *child = [directory objectForKey:key];
	if(child == nil)
	{
		child = [[childClass alloc] initWithParent:self path:[[self path] stringByAppendingPathComponent:key]];
		[directory setObject:child forKey:key];
		[child release];
		added = YES;
	}
	[child processFile:file];
	if(added == YES)
	{
		if([child isEmpty])
			[directory removeObjectForKey:key];
		else
			[self setReloadTimer];
	}
	return added;
}

- (BOOL)removeFile:(SapphireFileMetaData *)file fromKey:(NSString *)key
{
	SapphireVirtualDirectory *child = [directory objectForKey:key];
	BOOL ret = NO;
	if(child != nil)
	{
		[child removeFile:file];
		if([child isEmpty])
		{
			[directory removeObjectForKey:key];
			[self setReloadTimer];
			ret = YES;
		}
	}
	return ret;
}
@end