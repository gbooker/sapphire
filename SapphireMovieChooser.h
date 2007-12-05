//
//  SapphireMovieChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireCenteredMenuController.h"

#define MOVIE_CHOOSE_CANCEL		-2
#define MOVIE_CHOOSE_NOT_MOVIE	-1

/*!
 * @brief A subclass of SapphireCenteredMenuController to choose a movie title
 *
 * This class presents the user with a list of possible movies to match a file and asks the user to choose its name.
 */
@interface SapphireMovieChooser : SapphireCenteredMenuController {
	NSArray			*movies;		/*!< @brief The list of possible movies*/
	NSString		*fileName;		/*!< @brief The filename of the current file*/
	int				selection;		/*!< @brief The selection the user made*/
	BRTextControl	*fileNameText;	/*!< @brief The display of the filename on the screen*/
}

/*!
 * @brief Sets the movies to choose from
 *
 * @param movieList The list of movies to choose from
 */
- (void)setMovies:(NSArray *)movieList;

/*!
 * @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString *)choosingForFileName;

/*!
 * @brief The list of movies to choose from
 *
 * @return The list of movies to choose from
 */
- (NSArray *)movies;

/*!
 * @brief The file name we searched for
 *
 * @return The file name we searched for
 */
- (NSString *)fileName;

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (int)selection;

@end
