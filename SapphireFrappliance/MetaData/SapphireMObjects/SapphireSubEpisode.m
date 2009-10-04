#import "SapphireSubEpisode.h"
#import "SapphireEpisode.h"
#import "SapphireSeason.h"
#import "SapphireFileMetaData.h"

@implementation SapphireSubEpisode

+ (NSRange)subEpisodeRangeInEpisode:(SapphireEpisode *)ep
{
	NSEnumerator *subEpEnum = [ep.subEpisodesSet objectEnumerator];
	SapphireSubEpisode *subep;
	int max = 0;
	int min = INT_MAX;
	while((subep = [subEpEnum nextObject]) != nil)
	{
		int epNumber = [subep.episodeNumber intValue];
		if(epNumber > max)
			max = epNumber;
		if(epNumber < min)
			min = epNumber;
	}
	
	return NSMakeRange(min, max);
}

+ (SapphireSubEpisode *)subEpisode:(int)subNum inEpisode:(SapphireEpisode *)ep
{
	NSEnumerator *subEpEnum = [ep.subEpisodesSet objectEnumerator];
	SapphireSubEpisode *subep;
	while((subep = [subEpEnum nextObject]) != nil)
	{
		if([subep.episodeNumber intValue] == subNum)
			return subep;
	}
	
	return nil;
}

+ (SapphireSubEpisode *)subEpisodeTitle:(NSString *)title inEpisode:(SapphireEpisode *)ep
{
	NSEnumerator *subEpEnum = [ep.subEpisodesSet objectEnumerator];
	SapphireSubEpisode *subep;
	while((subep = [subEpEnum nextObject]) != nil)
	{
		if([subep.episodeTitle isEqualToString:title])
			return subep;
	}
	
	return nil;
}

+ (SapphireSubEpisode *)createSubEpisode:(int)subNum inEpisode:(SapphireEpisode *)ep
{
	SapphireSubEpisode *ret = [SapphireSubEpisode subEpisode:subNum inEpisode:ep];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireSubEpisodeName inManagedObjectContext:[ep managedObjectContext]];
	ret.episode = ep;
	ret.episodeNumber = [NSNumber numberWithInt:subNum];
	return ret;		
}

+ (SapphireSubEpisode *)createSubEpisodeTitle:(NSString *)title inEpisode:(SapphireEpisode *)ep
{
	SapphireSubEpisode *ret = [SapphireSubEpisode subEpisodeTitle:title inEpisode:ep];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireSubEpisodeName inManagedObjectContext:[ep managedObjectContext]];
	ret.episode = ep;
	ret.episodeNumberValue = 0;
	ret.episodeTitle = title;
	return ret;		
}

+ (void)upgradeV1SubEpisode:(NSManagedObject *)oldEp toContext:(NSManagedObjectContext *)newMoc inEpisode:(SapphireEpisode *)ep
{
	SapphireSubEpisode *newEp = [NSEntityDescription insertNewObjectForEntityForName:SapphireSubEpisodeName inManagedObjectContext:newMoc];
	newEp.absoluteEpisodeNumber = [oldEp valueForKey:@"absoluteEpisodeNumber"];
	newEp.airDate = [oldEp valueForKey:@"airDate"];
	newEp.episodeDescription = [oldEp valueForKey:@"episodeDescription"];
	newEp.episodeNumber = [oldEp valueForKey:@"episodeNumber"];
	newEp.episodeTitle = [oldEp valueForKey:@"episodeTitle"];
	newEp.episode = ep;
}

- (void)insertDictionary:(NSDictionary *)dict epIndex:(int)index
{
	NSString *desc = [dict objectForKey:META_DESCRIPTION_KEY];
	int descSplitIndex = [desc rangeOfString:@" / "].location;
	if(descSplitIndex == NSNotFound)
		descSplitIndex = [desc length];
	
	NSString *title = [dict objectForKey:META_TITLE_KEY];
	int titleSplitIndex = [title rangeOfString:@" / "].location;
	if(titleSplitIndex == NSNotFound)
		titleSplitIndex = [title length];
	
	if(index == -1)
	{
		self.absoluteEpisodeNumber = [dict objectForKey:META_ABSOLUTE_EP_NUMBER_KEY];
		self.episodeDescription = desc;
		self.episodeTitle = title;
	}
	else if(index == 0)
	{
		self.absoluteEpisodeNumber = [dict objectForKey:META_ABSOLUTE_EP_NUMBER_KEY];
		self.episodeDescription = [desc substringToIndex:descSplitIndex];
		self.episodeTitle = [title substringToIndex:titleSplitIndex];
	}
	else
	{
		self.absoluteEpisodeNumber = [dict objectForKey:META_ABSOLUTE_EP_2_NUMBER_KEY];
		self.episodeDescription = [desc substringFromIndex:descSplitIndex];
		self.episodeTitle = [title substringFromIndex:titleSplitIndex];
	}
	self.airDate = [dict objectForKey:META_SHOW_AIR_DATE];
}

- (NSComparisonResult)compare:(SapphireSubEpisode *)other
{
	NSComparisonResult result = [self.episode.season compare:other.episode.season];
	if(result != NSOrderedSame)
		return result;
	
	int myNum = self.episodeNumberValue;
	int theirNum = other.episodeNumberValue;
	if(myNum == 0 || theirNum == 0)
	{
		NSDate *myDate = self.airDate;
		NSDate *theirDate = other.airDate;
		return [myDate compare:theirDate];
	}
	if(myNum > theirNum)
		return NSOrderedDescending;
	if(theirNum > myNum)
		return NSOrderedAscending;
	
	return NSOrderedSame;
}

- (NSString *)path
{
	NSString *myName = self.episodeTitle;
	if(self.episodeNumberValue != 0)
		myName = [NSString stringWithFormat:@"Episode %d", self.episodeNumberValue];
	return [self.episode.season.path stringByAppendingPathComponent:myName];
}

@end
