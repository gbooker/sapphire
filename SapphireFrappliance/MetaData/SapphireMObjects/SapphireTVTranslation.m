#import "SapphireTVTranslation.h"
#import "CoreDataSupportFunctions.h"

@implementation SapphireTVTranslation

+ (SapphireTVTranslation *)tvTranslationForName:(NSString *)name inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	return (SapphireTVTranslation *)doSingleFetchRequest(SapphireTVTranslationName, moc, predicate);
}

+ (SapphireTVTranslation *)createTVTranslationForName:(NSString *)name withPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	SapphireTVTranslation *ret = [SapphireTVTranslation tvTranslationForName:name inContext:moc];
	if(ret == nil)
	{
		ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVTranslationName inManagedObjectContext:moc];
		ret.name = name;
	}
	
	ret.showPath = path;
	return ret;
}

+ (SapphireTVTranslation *)upgradeV1TVTranslation:(NSManagedObject *)oldTran toShow:(SapphireTVShow *)show
{
	NSManagedObjectContext *newMoc = [show managedObjectContext];
	
	SapphireTVTranslation *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVTranslationName inManagedObjectContext:newMoc];
	ret.name = [oldTran valueForKey:@"name"];
	ret.showPath = [oldTran valueForKey:@"showPath"];
	ret.tvShow = show;
	return ret;
}

@end
