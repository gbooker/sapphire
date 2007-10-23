//
//  SapphireMovieDirectory.m
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMovieDirectory.h"
#import "SapphireMetaData.h"

@interface SapphireDirectoryMetaData (privateFunctions)
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath;
@end

@implementation SapphireMovieBaseDirectory
- (id)initWithParent:(SapphireMovieBaseDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:nil parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	directory = [[NSMutableDictionary alloc] init];
	reloadTimer = nil;
	scannedDirectory = YES;
	
	return self;
}

- (void) dealloc
{
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
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reloadDirectoryContents) userInfo:nil repeats:NO];
}

- (void)processFile:(SapphireFileMetaData *)file
{
}

- (void)removeFile:(SapphireFileMetaData *)file
{
}

- (void)childDisplayChanged
{
	[self setReloadTimer];
}

- (BOOL)isDisplayEmpty
{
	return [files count] == [directories count];
}

- (BOOL)isEmpty
{
	return [directory count] == 0;
}

@end

@implementation SapphireMovieDirectory
- (id)initWithParent:(SapphireMovieBaseDirectory *)myParent path:(NSString *)myPath
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
	self = [self initWithParent:nil path:@"@MOVIES"];
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
	if(![[info objectForKey:META_DATA_FILE_INFO_KIND] isEqualToString:META_IMDB_IMPORT_KEY])
		return;
	SapphireFileMetaData *file = [notification object];
	[self processFile:file];
}

- (void)fileInfoWillChanged:(NSNotification *)notification
{
	NSDictionary *info = [notification userInfo];
	if(![[info objectForKey:META_DATA_FILE_INFO_KIND] isEqualToString:META_IMDB_IMPORT_KEY])
		return;
	SapphireFileMetaData *file = [notification object];
	[self removeFile:file];
}

- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireMovieGenreDirectory *dir = [directory objectForKey:key];
		if(![dir isDisplayEmpty])
			[mutDict setObject:dir forKey:key];
	}
	[directories addObjectsFromArray:[mutDict allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaDirs addEntriesFromDictionary:mutDict];
	[metaDirs addEntriesFromDictionary:mutDict];
	[mutDict release];
	[(SapphireMovieBaseDirectory *)parent childDisplayChanged];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	NSArray * genres=[file movieGenres];
	NSEnumerator *genresEnum = [genres objectEnumerator];
	NSString *genre = nil;
	while((genre = [genresEnum nextObject]) != nil)
	{
		BOOL added=NO ;
		SapphireMovieGenreDirectory *genreInfo=[directory objectForKey:genre];
		if(genreInfo==nil)
		{
			genreInfo=[[SapphireMovieGenreDirectory alloc] initWithParent:self path:[[self path] stringByAppendingString:genre]];
			[directory setObject:genreInfo forKey:genre];
			[genreInfo release];
			added=YES;
		}
		[genreInfo processFile:file];
		if(added==YES)
		{
			if([genreInfo isEmpty])
				[directory removeObjectForKey:genre];
		}
	}
	[self setReloadTimer];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSArray * genres=[file movieGenres];
	NSEnumerator *genresEnum = [genres objectEnumerator];
	NSString *genre = nil;
	while((genre = [genresEnum nextObject]) != nil)
	{
		SapphireMovieGenreDirectory *genreInfo = [directory objectForKey:genre];
		if(genreInfo != nil)
		{
			[genreInfo removeFile:file];
			if([genreInfo isEmpty])
				[directory removeObjectForKey:genre];
		}
	}
	[self setReloadTimer];
}
@end
/*
@implementation SapphireMovieGenreDirectory
- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
	NSEnumerator *keyEnum = [directory keyEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireSeasonDirectory *dir = [directory objectForKey:key];
		if(![dir isDisplayEmpty])
			[mutDict setObject:dir forKey:key];
	}
	[directories addObjectsFromArray:[mutDict allKeys]];
	[directories sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaDirs addEntriesFromDictionary:mutDict];
	[metaDirs addEntriesFromDictionary:mutDict];
	[mutDict release];
	[(SapphireTVBaseDirectory *)parent childDisplayChanged];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	int seasonNum = [file seasonNumber];
	if(seasonNum == 0)
		return;
	BOOL added = NO;
	NSString *season = [NSString stringWithFormat:BRLocalizedString(@"Season %d", @"Season name"), seasonNum];
	SapphireSeasonDirectory *seasonInfo = [directory objectForKey:season];
	if(seasonInfo == nil)
	{
		seasonInfo = [[SapphireSeasonDirectory alloc] initWithParent:self path:[[self path] stringByAppendingPathComponent:season]];
		[directory setObject:seasonInfo forKey:season];
		[seasonInfo release];
		added = YES;
	}
	[seasonInfo processFile:file];
	if(added == YES)
	{
		if([seasonInfo isEmpty])
			[directory removeObjectForKey:season];
		else
			[self setReloadTimer];
	}
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
		if([seasonInfo isEmpty])
		{
			[directory removeObjectForKey:season];
			[self setReloadTimer];
		}
	}
}
@end
*/

@implementation SapphireMovieGenreDirectory
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
			if([file fileClass]==FILE_CLASS_MOVIE)
			{
				NSString * title=[file movieTitle];
				[mutDict setObject:file forKey:title];
			}
			else
				continue;
		}
	}
	[files addObjectsFromArray:[mutDict allKeys]];
	[files sortUsingSelector:@selector(directoryNameCompare:)];
	[cachedMetaFiles addEntriesFromDictionary:mutDict];
	[metaFiles addEntriesFromDictionary:mutDict];
	[mutDict release];
	[(SapphireMovieBaseDirectory *)parent childDisplayChanged];
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