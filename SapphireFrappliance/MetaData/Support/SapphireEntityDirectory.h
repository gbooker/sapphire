/*
 * SapphireEntityDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on May 26, 2008.
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

#import "SapphireDirectory.h"
#import "SapphireBasicDirectoryFunctionsDefines.h"

typedef NSArray* (*EntityFetchFunction)(NSManagedObjectContext *context, NSPredicate *filterPredicate);

/*!
 * @brief A directory containing all of a particular managed object class
 *
 * This class is useful for fetching all of a particular class.  For example, fetching all Cast objects.
 */
@interface SapphireEntityDirectory : NSObject <SapphireDirectory> {
	NSManagedObjectContext			*moc;				/*!< @brief The context*/
	EntityFetchFunction				fetchFunction;		/*!< @brief The function to fetch entities*/
	NSDictionary					*entities;			/*!< @brief The cached entity list*/
	NSString						*nameKey;			/*!< @brief The key to fetch the name of an entity*/
	NSPredicate						*fetchPredicate;	/*!< @brief The metafile fetch predicate*/
	NSString						*path;				/*!< @brief The path of this directory*/
	NSString						*coverArtPath;		/*!< @brief The path to the cover art*/
	NSString						*notificationName;	/*!< @brief Name of notification to monitor*/
	NSPredicate						*fetchFilter;		/*!< @brief Filter to fetch objects on */
	Basic_Directory_Function_Instance_Variables
}

/*!
 * @brief Creates a new entity directory
 *
 * @param fetch The function to fetch entities
 * @param context The context to use
 * @return The entity directory
 */
- (id)initWithEntityFetch:(EntityFetchFunction)fetch inContext:(NSManagedObjectContext *)context;

/*!
 * @brief Sets the key to fetch a sub-entity's name, "name" otherwise
 *
 * @param key The key to use for an entity's name
 */
- (void)setNameKey:(NSString *)key;

/*!
 * @brief Sets the predicate to fetch all files within this directory
 *
 * @param predicate The fetch predicate
 */
- (void)setMetaFileFetchPredicate:(NSPredicate *)predicate;

/*!
 * @brief Sets the directory's path
 *
 * @param path The path to use for this directory
 */
- (void)setPath:(NSString *)newPath;

/*!
 * @brief Sets the directory's cover art path
 *
 * @param path The cover art path to use for this directory
 */
- (void)setCoverArtPath:(NSString *)newPath;

/*!
 * @brief Sets the notification to monitor
 *
 * @param notification The notification name
 */
- (void)setNotificationName:(NSString *)notification;

@end
