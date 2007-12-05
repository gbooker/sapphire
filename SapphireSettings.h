//
//  SapphireSettings.h
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"

@class SapphireDirectoryMetaData;

/*!
 * @brief The Settings
 *
 * This class contains all the settings for the frapp.  It is also a subclass of SapphireMediaMenuController so it has the ability to provide a UI for them as well.
 */
@interface SapphireSettings : SapphireMediaMenuController
{
	NSArray						*names;				/*!< @brief The menu names in order*/
	NSArray						*keys;				/*!< @brief The setting keys, in order*/
	NSArray						*gems;				/*!< @brief The left icons, in order*/
	NSMutableDictionary			*options;			/*!< @brief The settings, in order*/
	NSString					*path;				/*!< @brief The persistent store path*/
	NSDictionary				*defaults;			/*!< @brief The default settings, in order*/
	SapphireMetaDataCollection	*metaCollection;	/*!< @brief The collection*/
}

/*!
 * @brief Get the shared settings object
 *
 * This will not create the shared instance.
 *
 * @return The settings object
 */
+ (SapphireSettings *)sharedSettings;

/*!
 * @brief Allow the shared settings object to be freed
 */
+ (void)relinquishSettings;


/*!
 * @brief Create a settings object
 *
 * @param scene The scene
 * @param dictionaryPath The path of the saved setting
 * @param meta The top level meta data
 * @return The settings object
 */
- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaDataCollection:(SapphireMetaDataCollection *)collection;

/*!
 * @brief Returns whether to display unwatched
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayUnwatched;

/*!
 * @brief Returns whether to display favorites
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayFavorites;

/*!
 * @brief Returns whether to display top shows
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayTopShows;

/*!
 * @brief Returns whether to display spoilers
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displaySpoilers;

/*!
 * @brief Returns whether to display audio info
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayAudio;

/*!
 * @brief Returns whether to display video info
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayVideo;

/*!
 * @brief Returns whether to disable UI quit
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)disableUIQuit;

/*!
 * @brief Returns whether to disable anonymous reporting
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)disableAnonymousReporting;

/*!
 * @brief Returns whether to use AC3 passthrough
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)useAC3Passthrough;

/*!
 * @brief Returns whether to use fast directory switching
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)fastSwitching;

/*!
 * @brief Returns the index of the last predicate used
 *
 * @return The index of the last predicate used
 */
- (int)indexOfLastPredicate;

/*!
 * @brief Sets the index of the last predicate
 *
 * @param index The index of the last predicate used
 */
- (void)setIndexOfLastPredicate:(int)index;
@end
