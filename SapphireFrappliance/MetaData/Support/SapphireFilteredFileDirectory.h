/*
 * SapphireFilteredFileDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 2, 2008.
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

/*!
 * @brief A directory containing a filtered set of files
 *
 * This class is useful for fetching a certain set of files.  For example, fetching all files that are movies
 */
@interface SapphireFilteredFileDirectory : NSObject <SapphireSortableDirectory> {
	NSManagedObjectContext			*moc;				/*!< @brief The context*/
	NSPredicate						*fetchPredicate;	/*!< @brief The predicate filter*/
	NSMutableArray					*entities;			/*!< @brief The cached entity list*/
	NSMutableDictionary				*entityLookup;		/*!< @brief The cached entity lookup from name*/
	NSArray							*sorters;			/*!< @brief The sorters to use*/
	int								sortMethod;			/*!< @brief The sort to select*/
	NSString						*path;				/*!< @brief The path of this directory*/
	NSString						*coverArtPath;		/*!< @brief The path to the cover art*/
	NSString						*notificationName;	/*!< @brief Name of notification to monitor*/
	Basic_Directory_Function_Instance_Variables
}

/*!
 * @brief Creates a new filtered file directory
 *
 * @param context The context to use
 * @param pred The predicate to filter files
 * @return The entity directory
 */
- (id)initWithPredicate:(NSPredicate *)pred Context:(NSManagedObjectContext *)context;

/*!
 * @brief Sets the sort mechanisms
 *
 * @param sorts The sorting mechanisms, default first
 */
- (void)setFileSorters:(NSArray *)sorts;

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
