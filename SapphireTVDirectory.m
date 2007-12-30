/*
 * SapphireTVDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on Sep. 5, 2007.
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

#import "SapphireTVDirectory.h"
#import "SapphireMetaData.h"

@implementation SapphireTVDirectory

- (id)initWithParent:(SapphireVirtualDirectory *)myParent path:(NSString *)myPath
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
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection
{
	self = [self initWithParent:nil path:@"@TV"];
	if(self == nil)
		return nil;
	
	collection = myCollection;
	
	return self;
}

- (void)writeMetaData
{
	[collection writeMetaData];
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

- (void)processFile:(SapphireFileMetaData *)file
{
	NSString *show = [file showName];
	if(show == nil)
		return;
	if(![[NSFileManager defaultManager] fileExistsAtPath:[file path]])
		return;
	[self addFile:file toKey:show withChildClass:[SapphireShowDirectory class]];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSString *show = [file showName];
	if(show == nil)
		return;
	[self removeFile:file fromKey:show];
}
@end

@implementation SapphireShowDirectory
- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"TV" ofType:@"png"];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	NSString *season = [NSString stringWithFormat:BRLocalizedString(@"Season %d", @"Season name"), seasonNum];
	[self addFile:file toKey:season withChildClass:[SapphireSeasonDirectory class]];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	NSString *season = [NSString stringWithFormat:BRLocalizedString(@"Season %d", @"Season name"), seasonNum];
	[self removeFile:file fromKey:season];
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
			int epNum = [file episodeNumber];
			NSString *ep = nil;
			if(epNum != 0)
				ep = [NSString stringWithFormat:BRLocalizedString(@"Episode %d", @"Episode name"), epNum];
			else
				ep = [NSString stringWithFormat:BRLocalizedString(@"Episode: %@", @"Episode name"), [file episodeTitle]];
			[mutDict setObject:file forKey:ep];
		}
	}
	[files addObjectsFromArray:[mutDict allKeys]];
	[files sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaFiles addEntriesFromDictionary:mutDict];
	[metaFiles addEntriesFromDictionary:mutDict];
	[mutDict release];
	[(SapphireVirtualDirectory *)parent childDisplayChanged];
}

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"TV" ofType:@"png"];
	
}

- (void)processFile:(SapphireFileMetaData *)file
{
	[directory setObject:file forKey:[file path]];
	[self setReloadTimer];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	[directory removeObjectForKey:[file path]];
	[self setReloadTimer];
}
@end