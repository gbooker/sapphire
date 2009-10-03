#import "SapphireDirector.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireFileSorter.h"
#import "SapphireMetaDataSupport.h"

@implementation SapphireDirector

static NSArray *allowedSorts = nil;

+ (void)load
{
	allowedSorts = [[NSArray alloc] initWithObjects:[SapphireMovieTitleSorter sharedInstance], [SapphireDateSorter sharedInstance], [SapphireMovieIMDBRatingSorter sharedInstance], nil];
}

+ (SapphireDirector *)director:(NSString *)director inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", director];
	return (SapphireDirector *)doSingleFetchRequest(SapphireDirectorName, moc, predicate);
}

+ (SapphireDirector *)createDirector:(NSString *)director inContext:(NSManagedObjectContext *)moc
{
	SapphireDirector *ret = [SapphireDirector director:director inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectorName inManagedObjectContext:moc];
	ret.name = director;
	return ret;
}

+ (NSDictionary *)upgradeV1DirectorsFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSArray *oldDirectors = doFetchRequest(SapphireDirectorName, oldMoc, nil);
	NSEnumerator *directorEnum = [oldDirectors objectEnumerator];
	NSManagedObject *oldDirector;
	while((oldDirector = [directorEnum nextObject]) != nil)
	{
		SapphireDirector *newDirector = [NSEntityDescription insertNewObjectForEntityForName:SapphireDirectorName inManagedObjectContext:newMoc];
		NSString *name = [oldDirector valueForKey:@"name"];
		newDirector.name = name;
		newDirector.sortMethod = [oldDirector valueForKey:@"sortMethod"];
		[lookup setObject:newDirector forKey:name];
	}
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
