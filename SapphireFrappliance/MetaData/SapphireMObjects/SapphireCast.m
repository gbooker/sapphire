#import "SapphireCast.h"
#import "SapphireMovie.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireFileSorter.h"
#import "SapphireMetaDataSupport.h"

@implementation SapphireCast

static NSArray *allowedSorts = nil;

+ (void)load
{
	allowedSorts = [[NSArray alloc] initWithObjects:[SapphireMovieTitleSorter sharedInstance], [SapphireDateSorter sharedInstance], [SapphireMovieIMDBRatingSorter sharedInstance], nil];
}

+ (SapphireCast *)cast:(NSString *)cast inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", cast];
	return (SapphireCast *)doSingleFetchRequest(SapphireCastName, moc, predicate);
}

+ (SapphireCast *)createCast:(NSString *)cast inContext:(NSManagedObjectContext *)moc
{
	SapphireCast *ret = [SapphireCast cast:cast inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireCastName inManagedObjectContext:moc];
	ret.name = cast;
	return ret;
}

+ (NSDictionary *)upgradeCastVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldCast = doFetchRequest(SapphireCastName, oldMoc, nil);
	NSEnumerator *castEnum = [oldCast objectEnumerator];
	NSManagedObject *oldCastMember;
	while((oldCastMember = [castEnum nextObject]) != nil)
	{
		SapphireCast *newCastMember = [NSEntityDescription insertNewObjectForEntityForName:SapphireCastName inManagedObjectContext:newMoc];
		NSString *name = [oldCastMember valueForKey:@"name"];
		newCastMember.name = name;
		newCastMember.sortMethod = [oldCastMember valueForKey:@"sortMethod"];
		newCastMember.hasMajorRole = [oldCastMember valueForKey:@"hasMajorRole"];
		[lookup setObject:newCastMember forKey:name];
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

- (void)checkMajorRole
{
	BOOL currentMajorRole = self.hasMajorRoleValue;
	BOOL majorRole = NO;
	NSEnumerator *movieEnum = [self.moviesSet objectEnumerator];
	SapphireMovie *movie;
	while((movie = [movieEnum nextObject]) != nil)
	{
		if([movie castMemberHasMajorRoleStatus:self])
		{
			majorRole = YES;
			break;
		}
	}
	if(majorRole != currentMajorRole)
		self.hasMajorRoleValue = majorRole;
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
	else
		[self checkMajorRole];
}

- (void)removeMoviesObject:(SapphireMovie *)removedMovie
{
	[super removeMoviesObject:removedMovie];
	if([self.moviesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
	else
		[self checkMajorRole];
}

@end
