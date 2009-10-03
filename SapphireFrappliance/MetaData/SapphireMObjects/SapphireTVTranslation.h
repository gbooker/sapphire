#import "_SapphireTVTranslation.h"

#define SapphireTVTranslationName	@"TVTranslation"

@interface SapphireTVTranslation : _SapphireTVTranslation {}
+ (SapphireTVTranslation *)tvTranslationForName:(NSString *)name inContext:(NSManagedObjectContext *)moc;
+ (SapphireTVTranslation *)createTVTranslationForName:(NSString *)name withPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireTVTranslation *)upgradeV1TVTranslation:(NSManagedObject *)oldTran toShow:(SapphireTVShow *)show;
@end
