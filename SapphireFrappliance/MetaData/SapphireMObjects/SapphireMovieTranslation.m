#import "SapphireMovieTranslation.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireMoviePoster.h"

@implementation SapphireMovieTranslation

+ (SapphireMovieTranslation *)movieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	return (SapphireMovieTranslation *)doSingleFetchRequest(SapphireMovieTranslationName, moc, predicate);
}

+ (SapphireMovieTranslation *)createMovieTranslationWithName:(NSString *)name inContext:(NSManagedObjectContext *)moc
{
	SapphireMovieTranslation *ret = [SapphireMovieTranslation movieTranslationWithName:name inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieTranslationName inManagedObjectContext:moc];
	ret.name = name;
	
	return ret;
}

+ (SapphireMovieTranslation *)upgradeV1MovieTranslation:(NSManagedObject *)oldTran toMovie:(SapphireMovie *)movie
{
	NSManagedObjectContext *newMoc = [movie managedObjectContext];
	
	SapphireMovieTranslation *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieTranslationName inManagedObjectContext:newMoc];
	ret.IMDBLink = [oldTran valueForKey:@"IMDBLink"];
	ret.IMPLink = [oldTran valueForKey:@"IMPLink"];
	ret.name = [oldTran valueForKey:@"name"];
	ret.selectedPosterIndex = [oldTran valueForKey:@"selectedPosterIndex"];
	ret.movie = movie;
	
	NSEnumerator *posterEnum = [[oldTran valueForKey:@"posters"] objectEnumerator];
	NSManagedObject *oldPoster;
	while((oldPoster = [posterEnum nextObject]) != nil)
	{
		[SapphireMoviePoster upgradeV1MoviePoster:oldPoster toTranslation:ret];
	}
	return ret;
}

- (SapphireMoviePoster *)selectedPoster
{
	NSNumber *index = self.selectedPosterIndex;
	if(index == nil)
		return nil;
	
	NSArray *allPosters = [self.postersSet allObjects];
	NSPredicate *indexSearch = [NSPredicate predicateWithFormat:@"index = %d", [index intValue]];
	allPosters = [allPosters filteredArrayUsingPredicate:indexSearch];
	if(![allPosters count])
		return nil;
	return [allPosters objectAtIndex:0];
}

- (NSArray *)orderedPosters
{
	NSArray *allPosters = [self.postersSet allObjects];
	return [allPosters sortedArrayUsingSelector:@selector(compare:)];
}

- (SapphireMoviePoster *)posterAtIndex:(int)index
{
	NSArray *allPosters = [self.postersSet allObjects];
	NSPredicate *indexSearch = [NSPredicate predicateWithFormat:@"index = %d", index];
	allPosters = [allPosters filteredArrayUsingPredicate:indexSearch];
	if(![allPosters count])
		return nil;
	return [allPosters objectAtIndex:0];
}

@end
