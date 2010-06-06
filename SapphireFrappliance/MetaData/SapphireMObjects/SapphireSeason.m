#import "SapphireSeason.h"
#import "SapphireTVShow.h"
#import "SapphireFileSorter.h"
#import "SapphireMetaDataSupport.h"

@implementation SapphireSeason

static NSArray *allowedSorts = nil;

+ (void)load
{
	allowedSorts = [[NSArray alloc] initWithObjects:[SapphireTVEpisodeSorter sharedInstance], [SapphireDateSorter sharedInstance], nil];
}

+ (SapphireSeason *)season:(int)season forShow:(NSString *)show inContext:(NSManagedObjectContext *)moc
{
	SapphireTVShow *tvshow = [SapphireTVShow show:show inContext:moc];
	NSPredicate *seasonPred = [NSPredicate predicateWithFormat:@"seasonNumber = %d", season];
	NSArray *results = [[tvshow.seasonsSet allObjects] filteredArrayUsingPredicate:seasonPred];
	if([results count])
		return [results objectAtIndex:0];
	
	SapphireSeason *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireSeasonName inManagedObjectContext:moc];
	ret.tvShow = tvshow;
	ret.seasonNumber = [NSNumber numberWithInt:season];
	return ret;
}

+ (SapphireSeason *)upgradeSeasonVersion:(int)version from:(NSManagedObject *)oldSeason toShow:(SapphireTVShow *)show
{
	NSManagedObjectContext *newMoc = [show managedObjectContext];
	
	SapphireSeason *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireSeasonName inManagedObjectContext:newMoc];
	ret.seasonDescription = [oldSeason valueForKey:@"seasonDescription"];
	ret.seasonNumber = [oldSeason valueForKey:@"seasonNumber"];
	ret.tvShow = show;
	return ret;
}

- (NSComparisonResult)compare:(SapphireSeason *)other
{
	NSComparisonResult result = [self.tvShow compare:other.tvShow];
	if(result != NSOrderedSame)
		return result;
	
	int myNum = self.seasonNumberValue;
	int theirNum = other.seasonNumberValue;
	if(myNum == 0)
		myNum = INT_MAX;
	if(theirNum == 0)
		theirNum = INT_MAX;
	if(myNum > theirNum)
		return NSOrderedDescending;
	if(theirNum > myNum)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (NSString *)seasonName
{
	return [NSString stringWithFormat:@"Season %d", self.seasonNumberValue];
}

- (NSString *)autoSortPath
{
	NSString *showPath = [self.tvShow autoSortPath];
	if(showPath == nil)
		return nil;
	
	return [showPath stringByAppendingPathComponent:[self seasonName]];
}

- (NSPredicate *)metaFileFetchPredicate
{
	return [NSPredicate predicateWithFormat:@"tvEpisode.season == %@", self];
}

- (id <SapphireDirectory>)parentDirectory
{
	return self.tvShow;
}

- (NSArray *)fileSorters
{
	return allowedSorts;
}

- (NSString *)path
{
	NSString *myName = [NSString stringWithFormat:@"Season %d", self.seasonNumberValue];
	return [self.tvShow.path stringByAppendingPathComponent:myName];
}

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"TV" ofType:@"png"];
}

- (BOOL)shouldDelete
{
	return [self.episodesSet count] == 0;
}

-(void)removeEpisodes:(NSSet*)removedEpisodes
{
	[super removeEpisodes:removedEpisodes];
	if([self.episodesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

- (void)removeEpisodesObject:(SapphireEpisode*)removedEpisode
{
	[super removeEpisodesObject:removedEpisode];
	if([self.episodesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

@end
