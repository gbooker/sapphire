#import "SapphireMoviePoster.h"

@implementation SapphireMoviePoster

+ (SapphireMoviePoster *)createPosterWithLink:(NSString *)link index:(int)index translation:(SapphireMovieTranslation *)translation inContext:(NSManagedObjectContext *)moc
{
	SapphireMoviePoster *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMoviePosterName inManagedObjectContext:moc];
	ret.link = link;
	ret.indexValue = index;
	ret.movieTranslation = translation;
	
	return ret;
}

+ (SapphireMoviePoster *)upgradeMoviePosterVersion:(int)version from:(NSManagedObject *)oldTran toTranslation:(SapphireMovieTranslation *)translation
{
	NSManagedObjectContext *newMoc = [translation managedObjectContext];
	SapphireMoviePoster *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMoviePosterName inManagedObjectContext:newMoc];
	NSString *link = [oldTran valueForKey:@"link"];
	if(![link hasPrefix:@"http://"])
		link = [@"http://www.IMPAwards.com" stringByAppendingString:link];
	ret.link = link;
	ret.index = [oldTran valueForKey:@"index"];
	ret.movieTranslation = translation;
	return ret;
}

- (NSComparisonResult)compare:(SapphireMoviePoster *)other
{
	return [self.index compare:other.index];
}

@end
