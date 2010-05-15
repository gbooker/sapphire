/*
 * SapphireMetaDataSupport.h
 * Sapphire
 *
 * Created by Graham Booker on Apr. 16, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

@class SapphireMetaDataUpgrading;

NSString *searchCoverArtExtForPath(NSString *path);

/*!
 * @brief The basic support class
 *
 * This class contains many of the support functions necessary for operation.
 */
@interface SapphireMetaDataSupport : NSObject {
	NSManagedObjectContext	*mainMoc;			/*!< @brief The main context*/
	NSTimer					*writeTimer;		/*!< @brief The timer to agregate writes*/
	NSTimeInterval			interval;			/*!< @brief The write interval*/
	BOOL					locked;				/*!< @brief Was the DB locked during the last save*/
}

/*!
 * @brief Prune unused parts of the metadata
 *
 * This function first prunes movies with no files, then any cast, genres, and directors with no movies.
 * Then, it does the same with Episodes, followed by Seasons and TV Shows
 *
 * @param moc The context to prune
 */
+ (void)pruneMetaData:(NSManagedObjectContext *)moc;

/*!
 * @brief Sets an object up for pending delete
 *
 * Any object added to this set will be first checked before delete.  The check is calling selector
 * shouldDelete and if returns YES, performs the delete, otherwise it is removed from set.
 *
 * @param objectToDelete The object to delete
 */
+ (void)setObjectForPendingDelete:(NSManagedObject *)objectToDelete;

/*!
 * @brief Save the context
 *
 * @param context The context to save
 * @return YES if the save succeeded, NO otherwise
 */
+ (BOOL)save:(NSManagedObjectContext *)context;

/*!
 * @brief Save changes in a context in the main context
 *
 * @param context The context with changes to save
 */
+ (void)applyChangesFromContext:(NSManagedObjectContext *)context;

/*!
 * @brief Sets the main context
 *
 * @param moc the main context
 */
+ (void)setMainContext:(NSManagedObjectContext *)moc;

/*!
 * @brief Gets the main context
 *
 * @return The main context
 */
+ (NSManagedObjectContext *)mainContext;

/*!
 * @brief Was the DB locked in last save?
 *
 * @return YES if it was locked, NO otherwise
 */
+ (BOOL)wasLocked;

/*!
 * @brief Import an old context into the context
 *
 * @param version The version of the context
 * @param oldContext The context to use for old objects
 * @param context The context to use for new objects
 * @param display The display for UI feedback
 */
+ (void)importVersion:(int)version store:(NSManagedObjectContext *)oldContext intoContext:(NSManagedObjectContext *)context withDisplay:(SapphireMetaDataUpgrading *)display;

/*!
 * @brief Import the old plist into the context
 *
 * @param configDir The directory containing old configuration files
 * @param context The context to use for new objects
 * @param display The display for UI feedback
 */
+ (void)importPlist:(NSString *)configDir intoContext:(NSManagedObjectContext *)context withDisplay:(SapphireMetaDataUpgrading *)display;

/*!
 * @brief Get the path for the collection art
 *
 * @return The base collection art path
 */
+ (NSString *)collectionArtPath;

/*!
 * @brief Get a dictionary describing all the changes in the context for sending to another location
 *
 * @param moc The context with changes
 * @return The dictionary with the changes
 */
+ (NSDictionary *)changesDictionaryForContext:(NSManagedObjectContext *)moc;

/*!
 * @brief Apply a dictionary containing changes to the context
 *
 * @param changes The dictionary with the changes
 * @param moc The to apply context with changes
 */
+ (void)applyChanges:(NSDictionary *)changes toContext:(NSManagedObjectContext *)moc;
@end
