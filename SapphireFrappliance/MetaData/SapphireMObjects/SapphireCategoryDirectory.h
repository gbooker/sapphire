#import "_SapphireCategoryDirectory.h"
#import "SapphireBasicDirectoryFunctionsDefines.h"

@interface SapphireCategoryDirectory : _SapphireCategoryDirectory <SapphireSortableDirectory>{
	NSMutableDictionary				*cachedLookup;			/*!< @brief Cache to accellerate directory/file lookup*/
	NSMutableArray					*cachedFiles;			/*!< @brief Cached list of files*/
	NSMutableArray					*cachedDirs;			/*!< @brief Cached list of dirs*/
	NSMutableArray					*cachedMetaFiles;		/*!< @brief Cached list of meta files*/
	Basic_Directory_Function_Instance_Variables
}

- (NSString *)dirNameValue;
@end
