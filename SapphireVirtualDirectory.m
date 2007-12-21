/*
 * SapphireVirtualDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on Nov. 18, 2007.
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

#import "SapphireVirtualDirectory.h"

//Defined in MetaData.m but this is essentially private
NSString *searchCoverArtExtForPath(NSString *path);

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
	reloadTimer = nil;
	scannedDirectory = YES;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(startedLoading) name:META_DATA_FILE_INFO_STARTED_LOADING object:nil];
	[nc addObserver:self selector:@selector(finishedLoading) name:META_DATA_FILE_INFO_FINISHED_LOADING object:nil];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[directory allValues] makeObjectsPerformSelector:@selector(parentDealloced)];
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
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(completeReloadOfDirectoryContents) userInfo:nil repeats:NO];
}

- (void)completeReloadOfDirectoryContents
{
	reloadTimer = nil;
	[delegate directoryContentsChanged];
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

- (NSString *)classDefaultCoverPath
{
	return nil;
}

- (NSString *)coverArtPathUpToParents:(int)parents
{
	NSString *coverPath = searchCoverArtExtForPath([[[SapphireMetaData collectionArtPath] stringByAppendingPathComponent:[self path]] stringByAppendingPathComponent:@"cover"]);
	if([[NSFileManager defaultManager] fileExistsAtPath:coverPath])
		return coverPath;
	if(parents != 0 && [parent isKindOfClass:[SapphireDirectoryMetaData class]])
		return [(SapphireVirtualDirectory *)parent coverArtPathUpToParents:parents-1];
	return nil;
}

- (NSString *)coverArtPath
{
	NSString *ret = [self coverArtPathUpToParents:2];
	if(ret != nil)
		return ret;
	return [self classDefaultCoverPath];
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

- (void)startedLoading
{
	loading = YES;
}

- (void)finishedLoading
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
}

- (void)finishedLoading
{
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireVirtualDirectory *dir = [directory objectForKey:key];
		[dir finishedLoading];
	}
	[super finishedLoading];
}

- (BOOL)addFile:(SapphireFileMetaData *)file toKey:(NSString *)key withChildClass:(Class)childClass
{
	BOOL added = NO;
	SapphireVirtualDirectory *child = [directory objectForKey:key];
	if(child == nil)
	{
		child = [[childClass alloc] initWithParent:self path:[[self path] stringByAppendingPathComponent:key]];
		if(loading)
			[child startedLoading];
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