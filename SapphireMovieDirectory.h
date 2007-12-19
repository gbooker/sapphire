/*
 * SapphireMovieDirectory.h
 * Sapphire
 *
 * Created by Patrick Merrill on Oct. 22, 2007.
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
 * @brief The base movies virtual directory
 *
 * This class stores the main movies directory.  There are several virtual directories within this directory.
 */
@interface SapphireMovieDirectory : SapphireVirtualDirectoryOfDirectories {
	NSArray *keyOrder;	/*!< @brief The order in which to display the subdirectories*/
}
/*!
 * @brief create the top virtual directory
 *
 * @param myCollection The main collection so that a write works
 */
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

/*!
 * @brief The virtual directory of cast directories
 *
 * This class stores virtual directory which has subdirectories of class SapphireMovieCategoryDirectory.  Movies are sorted by the first 10 cast members.
 */
@interface SapphireMovieCastDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

/*!
 * @brief The virtual directory of director directories
 *
 * This class stores virtual directory which has subdirectories of class SapphireMovieCategoryDirectory.  Movies are sorted by the director.
 */
@interface SapphireMovieDirectorDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

/*!
 * @brief The virtual directory of genre directories
 *
 * This class stores virtual directory which has subdirectories of class SapphireMovieCategoryDirectory.  Movies are sorted by the first 10 genres.
 */
@interface SapphireMovieGenreDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

/*!
 * @brief The virtual directory of movies
 *
 * This class stores a list of movies.  It will add every movie it is told to add without any filters.
 */
@interface SapphireMovieCategoryDirectory : SapphireVirtualDirectory {
}
@end

/*!
 * @brief A subclass of SapphireMovieCategoryDirectory specific for oscars.
 *
 * This class overrides key functions of SapphireMovieCategoryDirectory to provide special sorting by number of oscars won.
 */
@interface SapphireMovieOscarDirectory : SapphireMovieCategoryDirectory{
}
@end

/*!
 * @brief A subclass of SapphireMovieCategoryDirectory specific for imdb rating.
 *
 * This class overrides key functions of SapphireMovieCategoryDirectory to provide special sorting by the movie's IMDB rating.
 */
@interface SapphireMovieTop250Directory : SapphireMovieCategoryDirectory{
}
@end
