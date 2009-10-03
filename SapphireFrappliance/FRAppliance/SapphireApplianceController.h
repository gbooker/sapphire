/*
 * SapphireApplianceController.h
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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

#define DISTRIBUTED_MESSAGES_PORT 15473

@class SapphireSettings, SapphireTheme, SapphireLeopardOnly, SapphireImporterDataMenu, SapphireBrowser, SapphireDistributedMessagesReceiver;

extern NSString *SAPPHIRE_MANAGED_OBJECT_CONTEXT_CLOSING;

typedef enum {
	PREDICATE_TYPE_NONE = NSNotFound,
	PREDICATE_TYPE_UNWATCHED = 0,
	PREDICATE_TYPE_FAVORITE = 1,
} PredicateType;

/*!
 * @brief Gets the application support directory, creates it if it doesn't already exist
 */
NSString *applicationSupportDir(void);

@protocol SapphireDistributedMessagesProtocol
- (oneway void)rescanDirectory:(NSString *)dirPath;
@end


/*!
 * @brief The Main Controller
 *
 * This class Is the main controller.  It uses SapphireMediaMenuController to create its main menu.
 */
@interface SapphireApplianceController : SapphireMediaMenuController <SapphireDistributedMessagesProtocol>
{
	NSManagedObjectContext		*moc;					/*!< @brief The context of metadata*/
	NSMutableArray				*names;					/*!< @brief The menu names, in order*/
	NSMutableArray				*controllers;			/*!< @brief The controllers to launch from menu, in order*/
	NSArray						*masterNames;			/*!< @brief The list of all names, including hidden*/
	NSArray						*masterControllers;		/*!< @brief The list of all controllers, including hidden*/
	SapphireSettings			*settings;				/*!< @brief The settings*/
	SapphireLeopardOnly			*leoOnly;				/*!< @brief Leopard only stuff*/
	BOOL						mountsOnly;				/*!< @brief YES if only display mounts*/
	SapphireDistributedMessagesReceiver	*distributed;	/*!< @brief The receiver for distributed messages*/
}

/*!
 * @brief Get the current predicate used
 *
 * @return The current predicate
 */
+ (NSPredicate *)predicate;

/*!
 * @brief Change to the next predicate
 *
 * @return The next predicate
 */
+ (NSPredicate *)nextPredicate;

/*!
 * @brief Get the current predicate type
 *
 * @return The current predicate type
 */
+ (PredicateType)predicateType;

/*!
 * @brief Set the current predicate type
 *
 * @param type The current predicate type to use
 */
+ (void)setPredicateType:(PredicateType)type;

/*!
 * @brief Get the unfiltered predicate
 *
 * @return The unfiltered predicate
 */
+ (NSPredicate *)unfilteredPredicate;

/*!
 * @brief Get the unwatched predicate
 *
 * @return The unwatched predicate
 */
+ (NSPredicate *)unwatchedPredicate;

/*!
 * @brief Get the favorite predicate
 *
 * @return The favorite predicate
 */
+ (NSPredicate *)favoritePredicate;

/*!
 * @brief Get the left icon for a given predicate
 *
 * @return The left icon
 */
+ (BRTexture *)gemForPredicate:(NSPredicate *)predicate;

/*!
 * @brief Get a key for these pair of predicates for cache lookup
 *
 * @param filter The filter predicate
 * @param check The check predicate
 * @return The lookup key to use
 */
+ (NSString *)keyForFilterPredicate:(NSPredicate *)filter andCheckPredicate:(NSPredicate *)check;

/*!
 * @brief Sets the current music controller, stopping the old one if it exists.
 *
 * @param controller The new music controller
 */
+ (void)setMusicNowPlayingController:(BRMusicNowPlayingController *)controller;

/*!
 * @brief Gets the current music controller
 *
 * @return The current music controller
 */
+ (BRMusicNowPlayingController *)musicNowPlayingController;

/*!
 * @brief Log an exception to the console
 *
 * This function attempts to log an exception to the console.  If the exception has a nice backtrace, it logs that along with the location of the Sapphire bundle in memory.  If it does not, it logs the entire backtrace is hex addresses along with the location of all memory objects in the trace.  The idea being that with this information, in either format, the developer can use atos to get exact line numbers.
 *
 * @param e The exception to log
 */
+ (void)logException:(NSException *)e;

/*!
 * @brief Gets whether an upgrade is needed
 *
 * @return YES if upgrade neeeded, NO otherwise
 */
+ (BOOL)upgradeNeeded;

/*!
 * @brief Creates a NSManagedObjectContext for a store file
 *
 * @param storeFile The file path of the store (must be SQLite), nil for default path
 * @param storeOptions A dictionary of store options
 * @return The managed object context, nil if failure
 */
+ (NSManagedObjectContext *)newManagedObjectContextForFile:(NSString *)storeFile withOptions:(NSDictionary *)storeOptions;

/*!
 * @brief Sets to display mounts only
 *
 * Sets this object to only display current mounts instead of the full menu
 */
- (void)setToMountsOnly;

/*!
 * @brief Get the tv browser
 *
 * Gets the browser for TV Shows
 *
 * @return The browser
 */
- (SapphireBrowser *)tvBrowser;

/*!
 * @brief Get the movie browser
 *
 * Gets the browser for movies
 *
 * @return The browser
 */
- (SapphireBrowser *)movieBrowser;

/*!
 * @brief Get the importer
 *
 * Gets the importer of all data
 *
 * @return The importer
 */
- (SapphireImporterDataMenu *)allImporter;

/*!
 * @brief Get the settings
 *
 * Gets the settings controller
 *
 * @return The settings controller
 */
- (SapphireSettings *)settings;
@end
