#import "SapphireEpisode.h"
#import "SapphireSeason.h"
#import "SapphireSubEpisode.h"
#import "SapphireMediaPreview.h"
#import "SapphireFileMetaData.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireXMLData.h"
#import "SapphireApplianceController.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireEpisode

+ (SapphireEpisode *)episodeFrom:(int)ep to:(int)lastEp inSeason:(int)season forShow:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc
{
	SapphireSeason *tvseason = [SapphireSeason season:season forShow:show withPath:showPath inContext:moc];
	NSEnumerator *epEnum = [tvseason.episodesSet objectEnumerator];
	SapphireEpisode *tvep;
	NSRange range = NSMakeRange(ep, lastEp);
	while((tvep = [epEnum nextObject]) != nil)
	{
		if(NSEqualRanges([SapphireSubEpisode subEpisodeRangeInEpisode:tvep], range))
			return tvep;
	}
	
	SapphireEpisode *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireEpisodeName inManagedObjectContext:moc];
	ret.season = tvseason;
	ret.tvShow = tvseason.tvShow;
	[ret addSubEpisodesObject:[SapphireSubEpisode createSubEpisode:ep inEpisode:ret]];
	return ret;
}

+ (SapphireEpisode *)episodeTitle:(NSString *)title inSeason:(int)season forShow:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc
{
	SapphireSeason *tvseason = [SapphireSeason season:season forShow:show withPath:showPath inContext:moc];
	NSEnumerator *epEnum = [tvseason.episodesSet objectEnumerator];
	SapphireEpisode *tvep;
	while((tvep = [epEnum nextObject]) != nil)
	{
		if([SapphireSubEpisode subEpisodeTitle:title inEpisode:tvep] != nil)
			return tvep;
	}
	
	SapphireEpisode *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireEpisodeName inManagedObjectContext:moc];
	ret.season = tvseason;
	ret.tvShow = tvseason.tvShow;
	[ret addSubEpisodesObject:[SapphireSubEpisode createSubEpisodeTitle:title inEpisode:ret]];
	return ret;
}

+ (void)upgradeV1EpisodesFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup
{
	NSArray *eps = doFetchRequest(SapphireEpisodeName, oldMoc, nil);
	NSEnumerator *epEnum = [eps objectEnumerator];
	NSManagedObject *oldEp;
	while((oldEp = [epEnum nextObject]) != nil)
	{
		NSArray *oldFilePaths = [oldEp valueForKeyPath:@"files.path"];
		NSEnumerator *pathEnum = [oldFilePaths objectEnumerator];
		NSString *path;
		NSMutableSet *newFiles = [NSMutableSet set];
		while((path = [pathEnum nextObject]) != nil)
		{
			SapphireFileMetaData *newFile = [fileLookup objectForKey:path];
			if(newFile != nil)
				[newFiles addObject:newFile];
		}
		if([newFiles count] == 0)
			continue;
		
		NSNumber *seasonNum = [oldEp valueForKeyPath:@"season.seasonNumber"];
		NSString *showName = [oldEp valueForKeyPath:@"tvShow.name"];
		NSString *showPath = [oldEp valueForKeyPath:@"tvShow.showPath"];
		
		SapphireSeason *season = [SapphireSeason season:[seasonNum intValue] forShow:showName withPath:showPath inContext:newMoc];
		if(season == nil)
			continue;
		
		SapphireEpisode *newEp = [NSEntityDescription insertNewObjectForEntityForName:SapphireEpisodeName inManagedObjectContext:newMoc];
		newEp.season = season;
		newEp.tvShow = season.tvShow;
		[newEp.filesSet setSet:newFiles];
		
		NSEnumerator *subEpEnum = [[oldEp valueForKey:@"subEpisodes"] objectEnumerator];
		NSManagedObject *subEp;
		while((subEp = [subEpEnum nextObject]) != nil)
			[SapphireSubEpisode upgradeV1SubEpisode:subEp toContext:newMoc inEpisode:newEp];
	}
}

- (void) dealloc
{
	[sortedSubEpisodes release];
	[super dealloc];
}

- (void)createSortedEpisodes
{
	if(sortedSubEpisodes != nil)
		return;
	
	NSArray *unsorted = [self.subEpisodesSet allObjects];
	sortedSubEpisodes = [[unsorted sortedArrayUsingSelector:@selector(compare:)] retain];
}

- (void)insertDictionary:(NSDictionary *)dict
{
	SapphireSubEpisode *sub = [self.subEpisodesSet anyObject];
	int secondEp = [[dict objectForKey:META_EPISODE_2_NUMBER_KEY] intValue];
	int setIndex = -1;
	if(secondEp != 0)
		setIndex = 0;
	[sub insertDictionary:dict epIndex:setIndex];
	if(secondEp != 0)
	{
		SapphireSubEpisode *sub = [SapphireSubEpisode createSubEpisode:secondEp inEpisode:self];
		[sub insertDictionary:dict epIndex:1];
		[self addSubEpisodesObject:sub];
	}
	else
		[self.subEpisodesSet setSet:[NSSet setWithObject:sub]];
}

+ (SapphireEpisode *)episodeWithDictionaries:(NSArray *)dictionaries inContext:(NSManagedObjectContext *)moc
{
	NSDictionary *firstEpDict = [dictionaries objectAtIndex:0];
	NSString *show = [firstEpDict objectForKey:META_SHOW_NAME_KEY];
	int season = [[firstEpDict objectForKey:META_SEASON_NUMBER_KEY] intValue];
	int ep = [[firstEpDict objectForKey:META_EPISODE_NUMBER_KEY] intValue];
	
	if(show == nil || season == 0)
		return nil;
	
	NSDictionary *lastEpDict = [dictionaries lastObject];
	int lastEp = [[firstEpDict objectForKey:META_EPISODE_2_NUMBER_KEY] intValue];
	if([dictionaries count] > 1)
		lastEp = [[lastEpDict objectForKey:META_EPISODE_NUMBER_KEY] intValue];
	if(lastEp == 0)
		lastEp = ep;
	
	NSString *showPath = [firstEpDict objectForKey:META_SHOW_IDENTIFIER_KEY];
	SapphireEpisode *ret;
	if(ep == 0)
	{
		NSString *title = [firstEpDict objectForKey:META_TITLE_KEY];
		ret = [SapphireEpisode episodeTitle:title inSeason:season forShow:show withPath:showPath inContext:moc];
	}
	else
		ret = [SapphireEpisode episodeFrom:ep to:lastEp inSeason:season forShow:show withPath:showPath inContext:moc];
	[ret insertDictionary:firstEpDict];
	if([dictionaries count] > 1)
	{
		NSEnumerator *otherEps = [dictionaries objectEnumerator];
		NSDictionary *epDict = [otherEps nextObject]; //Skip first
		while((epDict = [otherEps nextObject]) != nil)
			[ret insertAdditionalEpisode:epDict];
	}
	return ret;
}

- (NSNumber *)episodeNumber
{
	overrideWithXMLForKey(NSNumber, episodeNumber);
	[self createSortedEpisodes];
	return ((SapphireSubEpisode *)[sortedSubEpisodes objectAtIndex:0]).episodeNumber;
}

- (int)episodeNumberValue
{
	return [[self episodeNumber] intValue];
}

- (NSNumber *)lastEpisodeNumber
{
	overrideWithXMLForKey(NSNumber, lastEpisodeNumber);
	if([self.subEpisodesSet count] == 1)
		//Special case, only one episode here and XML didn't override last ep number
		return [self episodeNumber];
	[self createSortedEpisodes];
	return ((SapphireSubEpisode *)[sortedSubEpisodes objectAtIndex:sortedSubEpisodes.count - 1]).episodeNumber;
}

- (int)lastEpisodeNumberValue
{
	return [[self lastEpisodeNumber] intValue];
}

- (NSNumber *)absoluteEpisodeNumber
{
	overrideWithXMLForKey(NSNumber, absoluteEpisodeNumber);
	[self createSortedEpisodes];
	return ((SapphireSubEpisode *)[sortedSubEpisodes objectAtIndex:0]).absoluteEpisodeNumber;
}

- (int)absoluteEpisodeNumberValue
{
	return [[self absoluteEpisodeNumber] intValue];
}

- (NSString *)episodeTitle
{
	overrideWithXMLForKey(NSString, title);
	[self createSortedEpisodes];
	NSMutableArray *subs = [[sortedSubEpisodes valueForKey:@"episodeTitle"] mutableCopy];
	[subs removeObject:[NSNull null]];
	NSString *ret = [subs componentsJoinedByString:@" / "];
	[subs release];
	return ret;
}

- (NSString *)episodeDescription
{
	overrideWithXMLForKey(NSString, contentDescription);
	[self createSortedEpisodes];
	NSMutableArray *subs = [[sortedSubEpisodes valueForKey:@"episodeDescription"] mutableCopy];
	[subs removeObject:[NSNull null]];
	NSString *ret = [subs componentsJoinedByString:@" / "];
	[subs release];
	return ret;
}

- (NSComparisonResult)compare:(SapphireEpisode *)other
{
	NSComparisonResult result = [self.season compare:other.season];
	if(result != NSOrderedSame)
		return result;
	
	NSNumber *myNumber = [self episodeNumber];
	NSNumber *theirNumber = [other episodeNumber];
	if([myNumber intValue] == 0 || [theirNumber intValue] == 0)
		return [self airDateCompare:other];

	return [myNumber compare:theirNumber];
}

- (NSDate *)airDate
{
	[self createSortedEpisodes];
	return ((SapphireSubEpisode *)[sortedSubEpisodes objectAtIndex:0]).airDate;
}

- (NSComparisonResult)airDateCompare:(SapphireEpisode *)other
{
	return [[self airDate] compare:[other airDate]];
}

- (void)insertDisplayMetaData:(NSMutableDictionary *)dict
{
	id value = [self episodeTitle];
	if(value != nil)
		[dict setObject:value forKey:META_TITLE_KEY];
	value = [self episodeDescription];
	if(value != nil)
		[dict setObject:value forKey:META_DESCRIPTION_KEY];
	value = [[sortedSubEpisodes objectAtIndex:0] airDate];
	if(value != nil)
		[dict setObject:value forKey:META_SHOW_AIR_DATE];
	int season = [[self season] seasonNumberValue];
	int ep = [self episodeNumberValue];
	if(season != 0)
		[dict setObject:[[self season] seasonNumber] forKey:BRLocalizedString(@"Season", @"Season in metadata display")];
	if(ep != 0)
		[dict setObject:[NSNumber numberWithInt:ep] forKey:BRLocalizedString(@"Episode", @"Episode in metadata display")];
	if(ep != 0 && season != 0)
	{
		int lastEp = [self lastEpisodeNumberValue];
		NSString *key = BRLocalizedString(@"S/E", @"Season / Episode in metadata display");
		if(lastEp != nil && lastEp != ep)
			[dict setObject:[NSString stringWithFormat:@"%@ - %d / %d-%d", [[self tvShow] name], season, ep, lastEp] forKey:key];
		else
			[dict setObject:[NSString stringWithFormat:@"%@ - %d / %d", [[self tvShow] name], season, lastEp] forKey:key];		
	}
}

- (void)insertAdditionalEpisode:(NSDictionary *)dict
{
	SapphireSubEpisode *sub = [SapphireSubEpisode createSubEpisode:[[dict objectForKey:META_EPISODE_NUMBER_KEY] intValue] inEpisode:self];
	[sub insertDictionary:dict epIndex:-1];
	[self addSubEpisodesObject:sub];
}

- (NSString *)path
{
	[self createSortedEpisodes];
	return [[sortedSubEpisodes objectAtIndex:0] path];
}

- (NSString *)coverArtPath
{
	NSString *ret = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:[self path]];
	NSString *file = searchCoverArtExtForPath(ret);
	if(file == nil)
		return [self.season coverArtPath];
	return ret;
}

- (NSNumber *)watched
{
	NSSet *files = self.filesSet;
	if([files count] < 2)
		return [[files anyObject] watched];
	
	NSArray *remain = [[files allObjects] filteredArrayUsingPredicate:[SapphireApplianceController unwatchedPredicate]];
	if([remain count])
		return [NSNumber numberWithBool:YES];
	return [NSNumber numberWithBool:NO];
}

- (NSNumber *)favorite
{
	NSSet *files = self.filesSet;
	if([files count] < 2)
		return [[files anyObject] favorite];
	
	NSArray *remain = [[files allObjects] filteredArrayUsingPredicate:[SapphireApplianceController favoritePredicate]];
	if([remain count])
		return [NSNumber numberWithBool:YES];
	return [NSNumber numberWithBool:NO];
}

/*Overrides*/
- (void)addSubEpisodes:(NSSet*)value_
{
	[sortedSubEpisodes release];
	sortedSubEpisodes = nil;
	[super addSubEpisodes:value_];
}

- (void)removeSubEpisodes:(NSSet*)value_
{
	[sortedSubEpisodes release];
	sortedSubEpisodes = nil;
	[super removeSubEpisodes:value_];
}

- (void)addSubEpisodesObject:(SapphireSubEpisode*)value_
{
	[sortedSubEpisodes release];
	sortedSubEpisodes = nil;
	[super addSubEpisodesObject:value_];
}

- (void)removeSubEpisodesObject:(SapphireSubEpisode*)value_
{
	[sortedSubEpisodes release];
	sortedSubEpisodes = nil;
	[super removeSubEpisodesObject:value_];	 
}

- (void)clearPredicateCache
{
	[self.season clearPredicateCache];
}

- (void)addFiles:(NSSet*)addedFiles
{
	[super addFiles:addedFiles];
	[self clearPredicateCache];
}

- (BOOL)shouldDelete
{
	return [self.filesSet count] == 0;
}

-(void)removeFiles:(NSSet*)removeFiles
{
	[super removeFiles:removeFiles];
	if([self.filesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
	else
		[self clearPredicateCache];
}

- (void)addFilesObject:(SapphireFileMetaData *)addedFile
{
	[super addFilesObject:addedFile];
	[self clearPredicateCache];
}

- (void)removeFilesObject:(SapphireFileMetaData *)removeFile
{
	[super removeFilesObject:removeFile];
	if([self.filesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
	else
		[self clearPredicateCache];
}

@end
