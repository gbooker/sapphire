/*
 * SapphireTVDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Sep. 5, 2007.
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

#import "SapphireVirtualDirectory.h"

/*!
 * @brief The base TV shows virtual directory
 *
 * This class stores the main TV shows directory.  There are several SapphireShowDirectory objects within this directory.
 */
@interface SapphireTVDirectory : SapphireVirtualDirectoryOfDirectories {
}
/*!
 * @brief create the top virtual directory
 *
 * @param myCollection The main collection so that a write works
 */
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

/*!
 * @brief The TV show virtual directory
 *
 * This class stores a TV show's directory.  There are several SapphireSeasonDirectory objects within this directory.
 */
@interface SapphireShowDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

/*!
 * @brief The virtual directory of episodes
 *
 * This class stores a list of episodes.  It will add every episode it is told to add without any filters.
 */
@interface SapphireSeasonDirectory : SapphireVirtualDirectory {
}
@end