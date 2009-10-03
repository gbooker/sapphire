/*
 * SapphireMovieCategoryDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Apr. 9, 2008.
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
 * @brief A class to provide a virtual directory from an object
 *
 * This class provides a virtual directory given a managed object and a key for fetching subobjects
 */
@interface SapphireObjectDirectory : NSObject <SapphireDirectory>{
	NSManagedObject					*containingDirectory;		/*!< @brief The object which contains the sub-dirs*/
	NSString						*value;						/*!< @brief The key to use to fetch subdirs from the object*/
	NSArray							*cachedDirs;				/*!< @brief A cached list of all directory names*/
	Basic_Directory_Function_Instance_Variables
}

/*!
 * @brief Creates a new Object Directory
 *
 * @param directory The managed object containing the sub-dirs
 * @param key key to use to fetch subdirs from the object
 */
- (id)initWithDirectory:(NSManagedObject *)directory andSubDirKey:(NSString *)key;

@end
