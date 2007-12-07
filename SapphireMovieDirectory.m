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
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection
{
	self = [super initWithParent:nil path:VIRTUAL_DIR_ROOT_KEY];
	if(self == nil)
		return nil;
	
	collection = myCollection;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileAdded:) name:META_DATA_FILE_ADDED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileRemoved:) name:META_DATA_FILE_REMOVED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileInfoHasChanged:) name:META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileInfoWillChanged:) name:META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION object:nil];	
	
	SapphireMovieCategoryDirectory	*allMovies;
	SapphireMovieCastDirectory		*cast;
	SapphireMovieDirectorDirectory	*directors;
	SapphireMovieGenreDirectory		*genres;
	SapphireMovieOscarDirectory		*oscars;
	SapphireMovieTop250Directory	*imdbtop250;

	allMovies	= [[SapphireMovieCategoryDirectory alloc]	initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_ALL_KEY]];
	cast		= [[SapphireMovieCastDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_CAST_KEY]];
	directors	= [[SapphireMovieDirectorDirectory alloc]	initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_DIRECTOR_KEY]];
	genres		= [[SapphireMovieGenreDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_GENRE_KEY]];
	imdbtop250	= [[SapphireMovieTop250Directory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_TOP250_KEY]];
	oscars		= [[SapphireMovieOscarDirectory alloc]		initWithParent:self path:[[self path] stringByAppendingPathComponent:VIRTUAL_DIR_OSCAR_KEY]];
	
	[directory setObject:allMovies forKey:VIRTUAL_DIR_ALL_KEY];
	[directory setObject:cast forKey:@"By Cast"];
	[directory setObject:directors forKey:@"By Director"];
	[directory setObject:genres forKey:@"By Genre"];
	[directory setObject:imdbtop250	forKey:@"IMDB Top 250"];
	[directory setObject:oscars forKey:@"Academy Award Winning"];
	
	keyOrder = [[NSArray alloc] initWithObjects:
				VIRTUAL_DIR_ALL_KEY,
				VIRTUAL_DIR_GENRE_KEY,
				VIRTUAL_DIR_CAST_KEY,
				VIRTUAL_DIR_DIRECTOR_KEY,
				VIRTUAL_DIR_TOP250_KEY,
				VIRTUAL_DIR_OSCAR_KEY,
				nil];
	
	return self;
}

- (void) dealloc
{
	[keyOrder release];
	[super dealloc];
}

- (void)writeMetaData
{
	[collection writeMetaData];
}

- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	[directories setArray:keyOrder];
}

- (void)fileAdded:(NSNotification *)notification
{
	SapphireFileMetaData *file = [notification object];
	if([file fileClass] == FILE_CLASS_MOVIE)
		[self processFile:file];
}

- (void)fileRemoved:(NSNotification *)notification
{
	SapphireFileMetaData *file = [notification object];
	if([file fileClass] == FILE_CLASS_MOVIE)
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
	[[directory allValues] makeObjectsPerformSelector:@selector(processFile:) withObject:file];
}

- (void)removeFile:(SapphireFileMetaData *)file
{
	[[directory allValues] makeObjectsPerformSelector:@selector(removeFile:) withObject:file];
}

@end

@implementation SapphireMovieCastDirectory

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
}

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

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
}

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

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
}

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

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
}

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
			NSString * title=[file movieTitle];
			if(title != nil)
				[mutDict setObject:file forKey:title];
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

static NSComparisonResult imdbTop250Compare(NSString *first, NSString *second, void *context)
{
	NSDictionary *metaFiles = (NSDictionary *)context;
	int rank1 = [[metaFiles objectForKey:first] imdbTop250];
	int rank2 = [[metaFiles objectForKey:second] imdbTop250];
	if(rank1 > rank2)
		return NSOrderedDescending;
	else if (rank1 < rank2)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	
	[files sortUsingFunction:imdbTop250Compare context:metaFiles];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	if([file imdbTop250]>0)
		[super processFile:file];
	
}
@end

@implementation SapphireMovieOscarDirectory
- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"AMPAS_Oscar_H" ofType:@"png"];
}

static NSComparisonResult oscarsWonCompare(NSString *first, NSString *second, void *context)
{
	NSDictionary *metaFiles = (NSDictionary *)context;
	int rank1 = [[metaFiles objectForKey:first] oscarsWon];
	int rank2 = [[metaFiles objectForKey:second] oscarsWon];
	if(rank1 < rank2)
		return NSOrderedDescending;
	else if (rank1 > rank2)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (void)reloadDirectoryContents
{
	[super reloadDirectoryContents];
	
	[files sortUsingFunction:oscarsWonCompare context:metaFiles];
}

- (void)processFile:(SapphireFileMetaData *)file
{
	if([file oscarsWon]>0)
		[super processFile:file];
	
}
@end

