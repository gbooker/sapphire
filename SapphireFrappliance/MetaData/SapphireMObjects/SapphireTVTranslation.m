#import "SapphireTVTranslation.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireURLLoader.h"
#import "SapphireApplianceController.h"
#import "SapphireMetaDataSupport.h"

@interface SapphireTVTranslation ()
- (void)setUpgradeFromID:(int)showID;
@end


@implementation SapphireTVTranslation

+ (SapphireTVTranslation *)tvTranslationForName:(NSString *)name inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	return (SapphireTVTranslation *)doSingleFetchRequest(SapphireTVTranslationName, moc, predicate);
}

+ (SapphireTVTranslation *)createTVTranslationForName:(NSString *)name withURL:(NSString *)url itemID:(NSString *)itemID importer:(NSString *)importerID inContext:(NSManagedObjectContext *)moc
{
	SapphireTVTranslation *ret = [SapphireTVTranslation tvTranslationForName:name inContext:moc];
	if(ret == nil)
	{
		ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVTranslationName inManagedObjectContext:moc];
		ret.name = name;
	}
	
	ret.itemID = itemID;
	ret.url = url;
	ret.importerID = importerID;
	return ret;
}

+ (SapphireTVTranslation *)upgradeTVTranslationVersion:(int)version from:(NSManagedObject *)oldTran toContext:(NSManagedObjectContext *)newMoc
{
	SapphireTVTranslation *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireTVTranslationName inManagedObjectContext:newMoc];
	ret.name = [oldTran valueForKey:@"name"];
	NSString *showPath = [oldTran valueForKey:@"showPath"];
	ret.url = [@"http://www.tvrage.com" stringByAppendingString:showPath];
	ret.importerID = @"TV Rage";
	return ret;
}

+ (SapphireTVTranslation *)upgradeTVTranslationVersion:(int)version from:(NSManagedObject *)oldTran toShow:(SapphireTVShow *)show
{
	NSManagedObjectContext *newMoc = [show managedObjectContext];
	
	SapphireTVTranslation *ret = [SapphireTVTranslation upgradeTVTranslationVersion:version from:oldTran toContext:newMoc];
	ret.tvShow = show;
	return ret;
}

+ (void)upgradeShowLessTVTranslationsVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldTranslations = doFetchRequest(SapphireTVTranslationName, oldMoc, [NSPredicate predicateWithFormat:@"tvShow == nil"]);
	NSEnumerator *tranEnum = [oldTranslations objectEnumerator];
	NSManagedObject *oldTran;
	while((oldTran = [tranEnum nextObject]) != nil)
		[SapphireTVTranslation upgradeTVTranslationVersion:version from:oldTran toContext:newMoc];
	[pool drain];
}

+ (BOOL)needsFetchShowIDsInContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemID == nil"];
	return doSingleFetchRequest(SapphireTVTranslationName, moc, predicate) != nil;
}

NSArray *translationsNeedingShowID(NSManagedObjectContext *moc)
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemID == nil"];
	return doFetchRequest(SapphireTVTranslationName, moc, predicate);
}

+ (void)fetchShowIDsInContext:(NSManagedObjectContext *)moc
{
	NSArray *translations = translationsNeedingShowID(moc);
	SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
	
	NSEnumerator *tranEnum = [translations objectEnumerator];
	SapphireTVTranslation *tran;
	while((tran = [tranEnum nextObject]) != nil)
	{
		NSString *showURL = tran.url;
		NSLog(@"Checking %@", showURL);
		NSString *showPath = [showURL substringFromIndex:22];
		if([showPath hasPrefix:@"shows/id-"])
		{
			int showID = [[showPath substringFromIndex:9] intValue];
			[tran setUpgradeFromID:showID];
		}
		else
			[loader loadStringURL:tran.url withTarget:tran selector:@selector(loadedShowInfo:) object:nil];
	}
}

+ (void)cancelShowIDFetchInContext:(NSManagedObjectContext *)moc
{
	NSArray *translations = translationsNeedingShowID(moc);
	SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
	
	NSEnumerator *tranEnum = [translations objectEnumerator];
	SapphireTVTranslation *tran;
	while((tran = [tranEnum nextObject]) != nil)
	{
		[loader cancelLoadOfURL:tran.url forTarget:tran];
	}
}

- (void)setUpgradeFromID:(int)showID
{
	if(showID == 0)
		return;
	self.itemID = [NSString stringWithFormat:@"%d", showID];
	self.episodeListURL = [NSString stringWithFormat:@"http://services.tvrage.com/feeds/episode_list.php?sid=%d", showID];
}

- (void)loadedShowInfo:(NSString *)showInfo
{
	NSRange range = [showInfo rangeOfString:@"/edit/shows/"];
	NSLog(@"Found range %d %d for %@", range.location, range.length, self.url);
	if(range.location != NSNotFound)
	{
		int showID = [[showInfo substringFromIndex:range.location + range.length] intValue];
		NSLog(@"Got showID %d", showID);
		[self setUpgradeFromID:showID];
	}
	[SapphireMetaDataSupport save:[self managedObjectContext]];
}
@end
