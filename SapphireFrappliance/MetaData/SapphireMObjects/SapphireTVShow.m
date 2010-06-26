#import "SapphireTVShow.h"
#import "SapphireSeason.h"
#import "SapphireEpisode.h"
#import "SapphireSubEpisode.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireMetaDataSupport.h"
#import "NSString-Extensions.h"
#import "SapphireFileSorter.h"
#import "SapphireTVTranslation.h"
#import "SapphireFileMetaData.h"
#import "SapphireOtherInformation.h"

NSString *autoSortPathKey = @"autoSortPath";

@implementation SapphireTVShow

static NSArray *allowedSorts = nil;

+ (void)load
{
	allowedSorts = [[NSArray alloc] initWithObjects:[SapphireTVEpisodeSorter sharedInstance], [SapphireDurationSorter sharedInstance], [SapphireFileSizeSorter sharedInstance], [SapphireDateSorter sharedInstance], nil];
}

+ (SapphireTVShow *)show:(NSString *)show inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", show];
	SapphireTVShow *ret = (SapphireTVShow *)doSingleFetchRequest(SapphireTVShowName, moc, predicate);
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVShowName inManagedObjectContext:moc];
	ret.name = show;
	return ret;
}

+ (void)upgradeShowsVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldShows = doFetchRequest(SapphireTVShowName, oldMoc, nil);
	NSEnumerator *showEnum = [oldShows objectEnumerator];
	NSManagedObject *oldShow;
	while((oldShow = [showEnum nextObject]) != nil)
	{
		SapphireTVShow *newShow = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVShowName inManagedObjectContext:newMoc];
		newShow.name = [oldShow valueForKey:@"name"];
		newShow.showDescription = [oldShow valueForKey:@"showDescription"];
		
		NSEnumerator *translationEnum = [[oldShow valueForKey:@"translations"] objectEnumerator];
		NSManagedObject *translation;
		while((translation = [translationEnum nextObject]) != nil)
		{
			[SapphireTVTranslation upgradeTVTranslationVersion:version from:translation toShow:newShow];
		}
		
		NSEnumerator *seasonEnum = [[oldShow valueForKey:@"seasons"] objectEnumerator];
		NSManagedObject *season;
		while((season = [seasonEnum nextObject]) != nil)
		{
			[SapphireSeason upgradeSeasonVersion:version from:season toShow:newShow]; 
		}
	}
	[SapphireTVTranslation upgradeShowLessTVTranslationsVersion:version fromContext:oldMoc toContext:newMoc];
	[pool drain];
}

+ (NSArray *)sortMethods
{
	return allowedSorts;
}

- (NSComparisonResult)compare:(SapphireTVShow *)other
{
	return [self.name nameCompare:other.name];
}

- (NSString *)dirNameValue
{
	return @"seasonName";
}

- (NSPredicate *)metaFileFetchPredicate
{
	return [NSPredicate predicateWithFormat:@"tvEpisode.tvShow == %@", self];
}

- (NSArray *)fileSorters
{
	return allowedSorts;
}

- (void)defaultDirectorySort:(NSMutableArray *)dirs
{
	[dirs sortUsingSelector:@selector(compare:)];
}

- (NSString *)path
{
	return [NSString stringWithFormat:@"@TV/%@", self.name];
}

- (NSString *)classDefaultCoverPath
{
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"TV" ofType:@"png"];
}

static inline NSArray *getEpsFromFiles(NSManagedObjectContext *moc, NSArray *files)
{
	NSSet *epIds = [NSSet setWithArray:[files valueForKeyPath:@"tvEpisode.objectID"]];
	
	NSPredicate *epPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", epIds];
	return doFetchRequest(SapphireEpisodeName, moc, epPredicate);
}

- (NSMutableArray *)internalDirectoryFetchFromFiles:(NSArray *)files
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSArray *eps = getEpsFromFiles(moc, files);
	
	NSSet *seasonIds = [NSSet setWithArray:[eps valueForKeyPath:@"season.objectID"]];
	NSPredicate *seasonPred = [NSPredicate predicateWithFormat:@"SELF IN %@", seasonIds];
	NSMutableArray *ret = [doFetchRequest(SapphireSeasonName, moc, seasonPred) mutableCopy];
	return [ret autorelease];
}

- (void)prefetch:(NSArray *)files
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSArray *eps = getEpsFromFiles(moc, files);
	
	NSPredicate *subEpsPred = [NSPredicate predicateWithFormat:@"episode IN %@", eps];
	doFetchRequest(SapphireSubEpisodeName, moc, subEpsPred);
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

- (NSString *)calculateAutoSortPath
{
	NSArray *files = doFetchRequest(SapphireFileMetaDataName, [self managedObjectContext], [self metaFileFetchPredicate]);
	if([files count] == 0)
		return nil;
	
	NSString *sortPath = [[(SapphireFileMetaData *)[files objectAtIndex:0] path] stringByDeletingLastPathComponent];
	BOOL cropTwoDirs = NO;
	NSEnumerator *fileEnum = [files objectEnumerator];
	SapphireFileMetaData *file;
	while((file = [fileEnum nextObject]) != nil)
	{
		NSString *dirPath = [[file path] stringByDeletingLastPathComponent];
		if(cropTwoDirs)
			dirPath = [dirPath stringByDeletingLastPathComponent];
		
		if([dirPath isEqualToString:sortPath])
			continue;
		
		if(!cropTwoDirs)
		{
			sortPath = [sortPath stringByDeletingLastPathComponent];
			dirPath = [dirPath stringByDeletingLastPathComponent];
			cropTwoDirs = YES;
			if([dirPath isEqualToString:sortPath])
				continue;
		}
		
		return nil;
	}
	
	if(!cropTwoDirs)
	{
		NSString *lastPathComponent = [sortPath lastPathComponent];
		if([[lastPathComponent lowercaseString] hasPrefix:@"season"])
			sortPath = [sortPath stringByDeletingLastPathComponent];
	}
	
	return sortPath;
}

- (NSString *)autoSortPath
{
	return [self otherInformationForKey:autoSortPathKey];
}

- (void)setAutoSortPath:(NSString *)path
{
	[self setOtherObject:path forKey:autoSortPathKey];
}

@end
