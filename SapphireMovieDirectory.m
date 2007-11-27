//
//  SapphireMovieDirectory.m
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMovieDirectory.h"
#import "SapphireMetaData.h"

@implementation SapphireMovieDirectory
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
	self = [self initWithParent:nil path:@"@MOVIES"];
	if(self == nil)
		return nil;
	
	collection = myCollection;
	
	SapphireMovieCategoryDirectory	*allMovies;
	SapphireMovieCastDirectory		*cast;
	SapphireMovieDirectorDirectory	*directors;
	SapphireMovieGenreDirectory		*genres;
	SapphireMovieOscarDirectory		*oscars;
	SapphireMovieTop250Directory	*imdbtop250;

	allMovies	= [[SapphireMovieCategoryDirectory alloc]	initWithParent:self path:[[self path] stringByAppendingPathComponent:@"All Movies"]];
	cast		= [[SapphireMovieCastDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:@"By Cast"]];
	directors	= [[SapphireMovieDirectorDirectory alloc]	initWithParent:self path:[[self path] stringByAppendingPathComponent:@"By Director"]];
	genres		= [[SapphireMovieGenreDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:@"By Genre"]];
	imdbtop250	= [[SapphireMovieTop250Directory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:@"IMDB Top 250"]];
	oscars		= [[SapphireMovieOscarDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:@"Academy Award Winning"]];

	
	[directory setObject:allMovies forKey:@"All Movies"];
	[directory setObject:cast forKey:@"By Cast"];
	[directory setObject:directors forKey:@"By Director"];
	[directory setObject:genres forKey:@"By Genre"];
	[directory setObject:imdbtop250	forKey:@"IMDB Top 250"];
	[directory setObject:oscars forKey:@"Academy Award Winning"];
	
	subDirs = [[NSArray alloc] initWithObjects:
			   allMovies,
			   cast,
			   directors,
			   genres,
			   imdbtop250,
			   oscars,
			   nil];
	
	return self;
}

- (void) dealloc
{
	[subDirs release];
	[super dealloc];
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

- (void)processFile:(SapphireFileMetaData *)file
{
	[subDirs makeObjectsPerformSelector:@selector(processFile:) withObject:file];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	[subDirs makeObjectsPerformSelector:@selector(removeFile:) withObject:file];
}

@end

@implementation SapphireMovieCastDirectory
- (void)processFile:(SapphireFileMetaData *)file
{
	NSArray * cast=[file movieCast];
	NSEnumerator *castEnum = [cast objectEnumerator];
	NSString *actor = nil;
	int i=0 ;
	while((actor = [castEnum nextObject]) != nil)
	{
		/* Limit the cast depth to 10 actors */
		if(i>10)break ;
		BOOL added=[self addFile:file toKey:actor withChildClass:[SapphireMovieCategoryDirectory class]];
		if(added==YES)
			i++;
	}
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSArray * cast=[file movieCast];
	NSEnumerator *castEnum = [cast objectEnumerator];
	NSString *actor = nil;
	while((actor = [castEnum nextObject]) != nil)
		[self removeFile:file fromKey:actor];
	
}
@end

@implementation SapphireMovieDirectorDirectory
- (void)processFile:(SapphireFileMetaData *)file
{
	NSArray * directors=[file movieDirectors];
	NSEnumerator *directorsEnum = [directors objectEnumerator];
	NSString *director = nil;
	
	while((director = [directorsEnum nextObject]) != nil)
		[self addFile:file toKey:director withChildClass:[SapphireMovieCategoryDirectory class]];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSArray * directors=[file movieDirectors];
	NSEnumerator *directorsEnum = [directors objectEnumerator];
	NSString *director = nil;
	while((director = [directorsEnum nextObject]) != nil)
		[self removeFile:file fromKey:director];
	
}
@end

@implementation SapphireMovieGenreDirectory

- (void)processFile:(SapphireFileMetaData *)file
{
	NSArray * genres=[file movieGenres];
	NSEnumerator *genresEnum = [genres objectEnumerator];
	NSString *genre = nil;

	while((genre = [genresEnum nextObject]) != nil)
		[self addFile:file toKey:genre withChildClass:[SapphireMovieCategoryDirectory class]];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	NSArray * genres=[file movieGenres];
	NSEnumerator *genresEnum = [genres objectEnumerator];
	NSString *genre = nil;
	while((genre = [genresEnum nextObject]) != nil)
		[self removeFile:file fromKey:genre];

}
@end

@implementation SapphireMovieCategoryDirectory
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
	[(SapphireVirtualDirectory *)parent childDisplayChanged];
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

@implementation SapphireMovieTop250Directory

- (void)processFile:(SapphireFileMetaData *)file
{
	if([file imdbTop250]>0)
		[directory setObject:file forKey:[file path]];
	[self setReloadTimer];
	
}
@end

@implementation SapphireMovieOscarDirectory

- (void)processFile:(SapphireFileMetaData *)file
{
//	if([file oscarsWon]>0)
		[directory setObject:file forKey:[file path]];
	[self setReloadTimer];
	
}
@end

