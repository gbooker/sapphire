//
//  SapphireTVDirectory.m
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTVDirectory.h"
#import "SapphireMetaData.h"

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
		{
			if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
				return candidate;
		}
			
	}
	/*Didn't find one*/
	return nil;
}

@implementation SapphireTVDirectory
+ (void)initialize
{
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
- (NSString *)coverArtPath
{
	if([virtualCoverArt objectForKey:[path lastPathComponent]]!=nil)
		return [virtualCoverArt objectForKey:[path lastPathComponent]];
	else
		return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/TV.png"];
	
}

- (void)processFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	if([virtualCoverArt objectForKey:[path lastPathComponent]]==nil)
	{
		NSString *candidateCoverArt=nil;
		candidateCoverArt=searchExtForPath([[[file path]stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"]);
		if(candidateCoverArt!=nil)
			[virtualCoverArt setObject:candidateCoverArt forKey:[path lastPathComponent]];
		else
		{
			candidateCoverArt=searchExtForPath([[[[file path]stringByDeletingLastPathComponent]stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"]);
			if(candidateCoverArt!=nil)
			[virtualCoverArt setObject:candidateCoverArt forKey:[path lastPathComponent]];
		}
	}
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

- (NSString *)coverArtPath
{
	if([virtualCoverArt objectForKey:[path lastPathComponent]]!=nil)
		return [virtualCoverArt objectForKey:[path lastPathComponent]];
	else
		return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/TV.png"];
	
}

- (void)processFile:(SapphireFileMetaData *)file
{
	if([virtualCoverArt objectForKey:[path lastPathComponent]]==nil)
	{
		NSString *candidateCoverArt=nil;
		candidateCoverArt=searchExtForPath([[[file path]stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"]);
		if(candidateCoverArt!=nil)
			[virtualCoverArt setObject:candidateCoverArt forKey:[path lastPathComponent]];
		else
		{
			candidateCoverArt=searchExtForPath([[[[file path]stringByDeletingLastPathComponent]stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"]);
			if(candidateCoverArt!=nil)
			[virtualCoverArt setObject:candidateCoverArt forKey:[path lastPathComponent]];
		}
	}
	[directory setObject:file forKey:[file path]];
	[self setReloadTimer];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	[directory removeObjectForKey:[file path]];
	[self setReloadTimer];
}
@end