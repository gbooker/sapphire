//
//  SapphireShowChooser.h
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireCenteredMenuController.h"

#define SHOW_CHOOSE_CANCEL -2
#define SHOW_CHOOSE_NOT_SHOW -1

/*!
 * @brief A subclass of SapphireCenteredMenuController to choose a show title
 *
 * This class presents the user with a list of possible shows to match a file and asks the user to choose its name.
 */
@interface SapphireShowChooser : SapphireCenteredMenuController {
	NSArray			*shows;		/*!< @brief The list of possible shows*/
	NSString		*searchStr;	/*!< @brief The string we searched for*/
	int				selection;	/*!< @brief The user's selection*/
	BRTextControl	*fileName;	/*!< @brief The filename control*/
}

/*!
 * @brief Sets the shows to choose from
 *
 * @param showList The list of shows to choose from
 */
- (void)setShows:(NSArray *)showList;

/*!
 * @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString *)choosingForFileName;

/*!
 * @brief The list of shows to choose from
 *
 * @return The list of shows to choose from
 */
- (NSArray *)shows;

/*!
 * @brief Sets the string we searched for
 *
 * @param search The string we searched for
 */
- (void)setSearchStr:(NSString *)search;

/*!
 * @brief The string we searched for
 *
 * @return The string we searched for
 */
- (NSString *)searchStr;

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (int)selection;

@end
