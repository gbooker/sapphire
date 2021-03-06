/*
 * SapphireShowChooser.h
 * Sapphire
 *
 * Created by Graham Booker on Jul. 1, 2007.
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

#import <SapphireCompatClasses/SapphireCenteredMenuController.h>
#import <SapphireCompatClasses/SapphireLayoutManager.h>
#import "SapphireChooser.h"

extern NSString *tvShowTranslationNameKey;
extern NSString *tvShowTranslationLinkKey;
extern NSString *tvShowTranslationItemIDKey;

/*!
 * @brief A subclass of SapphireCenteredMenuController to choose a show title
 *
 * This class presents the user with a list of possible shows to match a file and asks the user to choose its name.
 */
@interface SapphireShowChooser : SapphireCenteredMenuController <SapphireLayoutDelegate, SapphireChooser> {
	NSArray					*shows;		/*!< @brief The list of possible shows*/
	SapphireChooserChoice	selection;	/*!< @brief The user's selection*/
	BRTextControl			*fileName;	/*!< @brief The filename control*/
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
@end
