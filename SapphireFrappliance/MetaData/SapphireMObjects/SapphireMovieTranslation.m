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

+ (SapphireMovieTranslation *)upgradeMovieTranslationVersion:(int)version from:(NSManagedObject *)oldTran toContext:(NSManagedObjectContext *)newMoc
{
	SapphireMovieTranslation *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieTranslationName inManagedObjectContext:newMoc];
	NSString *newURL = [oldTran valueForKey:@"IMDBLink"];
	if([newURL rangeOfString:@"://"].location == NSNotFound)
		newURL = [@"http://akas.imdb.com" stringByAppendingString:newURL];
	if([newURL characterAtIndex:[newURL length]-1] != '/')
		newURL = [newURL stringByAppendingString:@"/"];
	ret.url = newURL;
	ret.itemID = [newURL lastPathComponent];
	ret.importerID = @"IMDb.com";
	ret.name = [oldTran valueForKey:@"name"];
	ret.selectedPosterIndex = [oldTran valueForKey:@"selectedPosterIndex"];
	
	NSEnumerator *posterEnum = [[oldTran valueForKey:@"posters"] objectEnumerator];
	NSManagedObject *oldPoster;
	while((oldPoster = [posterEnum nextObject]) != nil)
	{
		[SapphireMoviePoster upgradeMoviePosterVersion:version from:oldPoster toTranslation:ret];
	}
	return ret;
}

+ (SapphireMovieTranslation *)upgradeMovieTranslationVersion:(int)version from:(NSManagedObject *)oldTran toMovie:(SapphireMovie *)movie
{
	NSManagedObjectContext *newMoc = [movie managedObjectContext];
	
	SapphireMovieTranslation *ret = [SapphireMovieTranslation upgradeMovieTranslationVersion:version from:oldTran toContext:newMoc];
	ret.movie = movie;
	return ret;
}

+ (void)upgradeMovieLessMovieTranslationVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldTranslations = doFetchRequest(SapphireMovieTranslationName, oldMoc, [NSPredicate predicateWithFormat:@"movie == nil"]);
	NSEnumerator *tranEnum = [oldTranslations objectEnumerator];
	NSManagedObject *oldTran;
	while((oldTran = [tranEnum nextObject]) != nil)
		[SapphireMovieTranslation upgradeMovieTranslationVersion:version from:oldTran toContext:newMoc];
	[pool drain];
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
