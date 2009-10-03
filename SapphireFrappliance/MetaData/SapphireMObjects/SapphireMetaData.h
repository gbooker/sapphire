#import "_SapphireMetaData.h"

#define SapphireMetaDataName		@"MetaData"

/*!
 * @brief The base metadata protocol
 *
 * This protocol is designed for use with distributed objects.
 */
@protocol SapphireMetaDataProtocol <NSObject>
/*!
 * @brief Returns the path of the current metadata
 *
 * All metadata has a path associated with it; this function returns the path for this one.
 *
 * @return The path
 */
- (NSString *)path;

@end

@interface SapphireMetaData : _SapphireMetaData <SapphireMetaDataProtocol> {}
+ (SapphireMetaData *)metaDataWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
- (NSString *)name;

/*!
 * @brief Get the metadata for display
 *
 * The metadata preview needs information about what data to display.  This function gets all the information for this metadata.
 *
 * @param order A pointer to an NSArray * in which to store the order in which the metadata is to be displayed
 * @return The display metadata with the titles as keys
 */
- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;

@end
