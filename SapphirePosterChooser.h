//
//  SapphirePosterChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireCenteredMenuController.h"

#define POSTER_CHOOSE_CANCEL		-1
#define POSTER_CHOOSE_REFRESH		0

@class BRRenderScene, BRRenderLayer, BRMarchingIconLayer;

/*!
 * @brief A subclass of SapphireCenteredMenuController to provide a means to select between posters
 *
 * This class provides a menu and maching icons to display posters for the user to choose.
 */
@interface SapphirePosterChooser : SapphireCenteredMenuController <BRIconSourceProtocol, BRMenuListItemProvider> {
	NSArray					*posters;		/*!< @brief The array of poster paths*/
	NSMutableArray			*posterLayers;	/*!< @brief The image layers of posters*/
	NSString				*fileName;		/*!< @brief The movie filename*/
	NSString				*movieTitle;	/*!< @brief The title of the movie*/
	long					selectedPoster;	/*!< @brief The user's selection*/
	BRTextControl			*fileInfoText;	/*!< @brief The text control to display filename and movie title*/
	BRMarchingIconLayer		*posterMarch;	/*!< @brief The icon march to display the posters*/
	BRBlurryImageLayer		*defaultImage;	/*!< @brief The image to use when the poster isn't loaded yet*/
}

/*!
 * @brief check ATV version & poster chooser opt out
 *
 * @return The YES if we can display 
 */
- (BOOL)okayToDisplay;

/*!
 * @brief The list of movies to choose from
 *
 * @return The list of movies to choose from
 */
- (NSArray *)posters;

/*!
 * @brief Sets the posters to choose from
 *
 * @param posterList The list of movies to choose from
 */
- (void)setPosters:(NSArray *)posterList;

/*!
 * @brief Loads the posters from disk
 */
- (void)loadPosters;

/*!
 * @brief Reloads a poster from disk
 *
 * @param index The index of the poster to reload
 */
- (void)reloadPoster:(int)index;

/*!
 * @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString *)choosingForFileName;

/*!
 * @brief Sets the string we searched for
 *
 * @param search The string we searched for
 */
- (void)setMovieTitle:(NSString *)theMovieTitle;

/*!
 * @brief The string we searched for
 *
 * @return The string we searched for
 */
- (NSString *)movieTitle;

/*!
 * @brief The filename we searched for
 *
 * @return The file name we searched for
 */
- (NSString *)fileName;

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (long)selectedPoster;

@end