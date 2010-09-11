/*
 * SapphireSettings.h
 * Sapphire
 *
 * Created by pnmerrill on Jun. 23, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <SapphireCompatClasses/SapphireMediaMenuController.h>

/*!
 * @brief The Settings
 *
 * This class contains all the settings for the frapp.  It is also a subclass of SapphireMediaMenuController so it has the ability to provide a UI for them as well.
 */
@interface SapphireSettings : SapphireMediaMenuController
{
	NSArray						*settings;				/*!< @brief Settings for the UI*/
	NSMutableDictionary			*options;				/*!< @brief The settings, in order*/
	NSString					*path;					/*!< @brief The persistent store path*/
	NSDictionary				*defaults;				/*!< @brief The default settings, in order*/
	NSManagedObjectContext		*moc;					/*!< @brief The context*/
	int							lastCommand;			/*!< @brief The last command issued*/
	NSDate						*displayOnlyPlot;		/*!< @brief Disploy only the plot in the preview until time has passed*/
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
 * @param context The managed object context
 * @return The settings object
 */
- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath context:(NSManagedObjectContext *)context;

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
 * @brief Returns whether to display poster chooser
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayPosterChooser;

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
 * @brief Returns whether to use directory based lookup
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)dirLookup;

/*!
 * @brief Returns whether auto-selection for movies/shows is in use
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)autoSelection;

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

/*!
 * @brief Sets hiding of all info besides plot
 *
 * @param plotOnlyTime Time when to continue displaying plot
 */
- (void)setDisplayOnlyPlotUntil:(NSDate *)plotOnlyTime;

/*!
 * @brief Gets hiding of all info besides plot for next preview controller
 */
- (BOOL)displayOnlyPlot;

/*!
 * @brief Gets the log level for general logging
 */
- (SapphireLogLevel)generalLogLevel;

/*!
 * @brief Gets the log level for import logging
 */
- (SapphireLogLevel)importLogLevel;

/*!
 * @brief Gets the log level for file logging
 */
- (SapphireLogLevel)fileLogLevel;

/*!
 * @brief Gets the log level for playback logging
 */
- (SapphireLogLevel)playbackLogLevel;

/*!
 * @brief Gets the log level for metadata logging
 */
- (SapphireLogLevel)metadataLogLevel;
@end
