/*
 * CoreDataSupportFunctions.h
 * Sapphire
 *
 * Created by Graham Booker on May 3, 2008.
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

/*!
 * @brief Do a coredata object fetch
 *
 * @param entityName The name of the entity to fetch
 * @param context The context from which to fetch objects
 * @param predicate The predict to filter returned objects
 *
 * @return The entities with the name entityName, in the context, and filtered by predicate
 */
NSArray *doFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate);

/*!
 * @brief Do a coredata object fetch for a single object
 *
 * @param entityName The name of the entity to fetch
 * @param context The context from which to fetch object
 * @param predicate The predict to filter returned object
 *
 * @return A single entity with the name entityName, in the context, and filtered by predicate
 */
NSManagedObject *doSingleFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate);

/*!
 * @brief Do a coredata object fetch and sort output
 *
 * @param entityName The name of the entity to fetch
 * @param context The context from which to fetch objects
 * @param predicate The predict to filter returned objects
 * @param sort The sort descriptor to sort returned objects
 *
 * @return The entities with the name entityName, in the context, filtered by predicate, and sorted by sort
 */
NSArray *doSortedFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate, NSSortDescriptor *sort);

/*!
 * @brief Determine in a particual entity exists
 *
 * @param entityName The name of the entity to fetch
 * @param context The context from which to fetch objects
 * @param predicate The predict to filter returned objects
 *
 * @return YES if an entity matching the name and predicate exists in the context, NO otherwise
 */
BOOL entityExists(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate);
