/*
 * SapphireTVDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 16, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireEntityDirectory.h"

@interface SapphireTVDirectory : SapphireEntityDirectory {
	NSMutableArray	*customDirectories;			/*!< @brief The custom directories*/
	NSMutableArray	*customDirectoryNames;		/*!< @brief The custom directory names*/
	NSArray			*virtualDirs;				/*!< @brief The virtual directories last imported*/
}

- (id)initWithContext:(NSManagedObjectContext *)context;

@end
