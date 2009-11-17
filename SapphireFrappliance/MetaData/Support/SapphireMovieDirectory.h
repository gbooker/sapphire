/*
 * SapphireMovieDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on May 27, 2008.
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
 * @brief The base movies virtual directory
 *
 * This class stores the main movies directory.  There are several virtual directories within this directory.
 */
@interface SapphireMovieDirectory : NSObject <SapphireDirectory> {
	NSManagedObjectContext			*moc;				/*!< @brief The context*/
	NSArray							*originalSubDirs;	/*!< @brief The static sub-directory objects*/
	NSArray							*originalNames;		/*!< @brief The static sub-directory names*/
	NSMutableArray					*subDirs;			/*!< @brief The sub-directory objects*/
	NSMutableArray					*names;				/*!< @brief The sub-directory names*/
	NSArray							*virtualDirs;		/*!< @brief The virtual directories last imported*/
	NSArray							*defaultSorters;	/*!< @brief The list of default file sorters*/
	Basic_Directory_Function_Instance_Variables
}

/*!
 * @brief create the top movie virtual directory
 *
 * @param context The context which stores the movies
 * @return The movie directory
 */
- (id)initWithContext:(NSManagedObjectContext *)context;

@end
