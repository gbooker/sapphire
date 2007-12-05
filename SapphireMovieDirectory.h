//
//  SapphireMovieDirectory.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
