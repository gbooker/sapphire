#import "_SapphireCollectionDirectory.h"

#define SapphireCollectionDirectoryName @"CollectionDirectory"

@interface SapphireCollectionDirectory : _SapphireCollectionDirectory {
	BOOL		toDelete;
}
+ (SapphireCollectionDirectory *)collectionAtPath:(NSString *)path mount:(BOOL)isMount skip:(BOOL)skip hidden:(BOOL)hidden manual:(BOOL)manual inContext:(NSManagedObjectContext *)moc;
+ (SapphireCollectionDirectory *)collectionAtPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireCollectionDirectory *)upgradeCollectionDirectoryVersion:(int)version from:(NSManagedObject *)oldCol toContext:(NSManagedObjectContext *)newMoc;
+ (NSString *)resolveSymLinksInCollectionPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (NSArray *)availableCollectionDirectoriesInContext:(NSManagedObjectContext *)moc includeHiddenOverSkipped:(BOOL)hidden;
+ (NSArray *)skippedCollectionDirectoriesInContext:(NSManagedObjectContext *)moc;
+ (NSArray *)allCollectionsInContext:(NSManagedObjectContext *)moc;

- (BOOL)deleteValue;
- (void)setDeleteValue:(BOOL)del;

- (NSDictionary *)mountInformation;
- (void)setMountInformation:(NSDictionary *)info;
@end
