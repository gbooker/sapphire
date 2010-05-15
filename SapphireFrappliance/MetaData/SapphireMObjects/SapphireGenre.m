#import "SapphireGenre.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireFileSorter.h"
#import "SapphireMovie.h"
#import "SapphireMetaDataSupport.h"

@implementation SapphireGenre

static NSArray *allowedSorts = nil;

+ (void)load
{
	allowedSorts = [[NSArray alloc] initWithObjects:[SapphireMovieTitleSorter sharedInstance], [SapphireDateSorter sharedInstance], [SapphireMovieIMDBRatingSorter sharedInstance], nil];
}

+ (SapphireGenre *)genre:(NSString *)genre inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", genre];
	return (SapphireGenre *)doSingleFetchRequest(SapphireGenreName, moc, predicate);
}
	
+ (SapphireGenre *)createGenre:(NSString *)genre inContext:(NSManagedObjectContext *)moc
{
	SapphireGenre *ret = [SapphireGenre genre:genre inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireGenreName inManagedObjectContext:moc];
	ret.name = genre;
	return ret;
}

+ (NSDictionary *)upgradeGenresVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldGenres = doFetchRequest(SapphireGenreName, oldMoc, nil);
	NSEnumerator *genreEnum = [oldGenres objectEnumerator];
	NSManagedObject *oldGenre;
	while((oldGenre = [genreEnum nextObject]) != nil)
	{
		SapphireGenre *newGenre = [NSEntityDescription insertNewObjectForEntityForName:SapphireGenreName inManagedObjectContext:newMoc];
		NSString *name = [oldGenre valueForKey:@"name"];
		newGenre.name = name;
		newGenre.sortMethod = [oldGenre valueForKey:@"sortMethod"];
		[lookup setObject:newGenre forKey:name];
	}
	[pool drain];
	return lookup;
}

- (NSPredicate *)metaFileFetchPredicate
{
	NSArray *movieIds = [self.moviesSet valueForKey:@"objectID"];
	return [NSPredicate predicateWithFormat:@"movie IN %@", movieIds];
}

- (NSArray *)fileSorters
{
	return allowedSorts;
}

- (NSString *)path
{
	return [[super path] stringByAppendingPathComponent:self.name];
}

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
}

- (BOOL)shouldDelete
{
	return [self.moviesSet count] == 0;
}

-(void)removeMovies:(NSSet*)removedMovies
{
	[super removeMovies:removedMovies];
	if([self.moviesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

- (void)removeMoviesObject:(SapphireMovie *)removedMovie
{
	[super removeMoviesObject:removedMovie];
	if([self.moviesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

@end
