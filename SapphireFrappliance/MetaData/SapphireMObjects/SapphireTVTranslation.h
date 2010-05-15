#import "_SapphireTVTranslation.h"

#define SapphireTVTranslationName	@"TVTranslation"

@interface SapphireTVTranslation : _SapphireTVTranslation {}
+ (SapphireTVTranslation *)tvTranslationForName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireTVTranslation *)createTVTranslationForName:(NSString *)name withURL:(NSString *)url itemID:(NSString *)itemID importer:(NSString *)importerID inContext:(NSManagedObjectContext *)moc;
+ (SapphireTVTranslation *)upgradeTVTranslationVersion:(int)version from:(NSManagedObject *)oldTran toShow:(SapphireTVShow *)show;
+ (void)upgradeShowLessTVTranslationsVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
+ (BOOL)needsFetchShowIDsInContext:(NSManagedObjectContext *)moc;
+ (void)fetchShowIDsInContext:(NSManagedObjectContext *)moc;
+ (void)cancelShowIDFetchInContext:(NSManagedObjectContext *)moc;
@end
