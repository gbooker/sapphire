#import "_SapphireDirectoryMetaData.h"
#import "SapphireDirectory.h"
#import "SapphireBasicDirectoryFunctionsDefines.h"

#define SapphireDirectoryMetaDataName		@"DirectoryMetaData"

@class SapphireMetaDataUpgrading;

@interface SapphireDirectoryMetaData : _SapphireDirectoryMetaData <SapphireDirectory, SapphireImporterBackgroundProtocol>
{
	int								importing;				/*!< @brief bit 0 is set if background importing of data, bit 1 if awaiting data*/\
	NSMutableArray					*importArray;			/*!< @brief Array of objects left to import*/
	NSMutableDictionary				*cachedLookup;			/*!< @brief Cache to accellerate directory/file lookup*/
	NSMutableArray					*cachedFiles;			/*!< @brief Cached list of files*/
	NSMutableArray					*cachedDirs;			/*!< @brief Cached list of dirs*/
	Basic_Directory_Function_Instance_Variables
}

+ (SapphireDirectoryMetaData *)directoryWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireDirectoryMetaData *)createDirectoryWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireDirectoryMetaData *)createDirectoryWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc;
+ (NSDictionary *)upgradeDirectoriesVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc;
- (void)insertDictionary:(NSDictionary *)dict withDefer:(NSMutableDictionary *)defer andDisplay:(SapphireMetaDataUpgrading *)display;
- (void)rescanDirWithExistingDirs:(NSMutableArray *)existingDirs files:(NSMutableArray *)existingFiles symDirs:(NSMutableArray *)existingSymDirs symFiles:(NSMutableArray *)existingSymFiles;

/*!
 * @brief Moves a file to a new directory and updates metadata
 *
 * @param dir The new directory for the file
 */
- (NSString *)moveToDir:(SapphireDirectoryMetaData *)dir;

/*!
 * @brief Gets the list of new files for import
 *
 * @return New file paths
 */
- (NSArray *)importFilePaths;

/*!
 * @brief Adds to the list of new files for import
 *
 * @param newPaths The paths to add
 */
- (void)addImportFilePaths:(NSArray *)newPaths;
@end
