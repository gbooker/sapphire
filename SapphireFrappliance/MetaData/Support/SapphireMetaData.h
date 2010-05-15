/*!
 * @brief The base metadata protocol
 *
 * This protocol is the basic metadata object for previews
 */
@protocol SapphireMetaData <NSObject>
/*!
 * @brief Returns the path of the current metadata
 *
 * All metadata has a path associated with it; this function returns the path for this one.
 *
 * @return The path
 */
- (NSString *)path;

/*!
 * @brief Get the metadata for display
 *
 * The metadata preview needs information about what data to display.  This function gets all the information for this metadata.
 *
 * @param order A pointer to an NSArray * in which to store the order in which the metadata is to be displayed
 * @return The display metadata with the titles as keys
 */
- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;

/*!
 * @brief Get the metadata's managed object context
 *
 * @return The managed object context
 */
- (NSManagedObjectContext *)managedObjectContext;

@end