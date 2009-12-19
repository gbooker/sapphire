/*
 * SapphireChooser.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 16, 2009.
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

/*!
 * @brief The user's choice
 */
typedef enum {
	SapphireChooserChoiceCancel = -2,	/*!< @brief The user canceled the chooser*/
	SapphireChooserChoiceNotType = -1,	/*!< @brief The user said this is not a (movie/tv show)*/
	SapphireChooserChoiceFirstItem,		/*!< @brief The user selected the first item.  Values 0 and up are selections*/
} SapphireChooserChoice;

/*!
 * @brief The Chooser protocol
 *
 * @This protocol defines basic functions all choosers must implement.
 */
@protocol SapphireChooser <NSObject>

/*!
 * @brief Get the user's selection from the chooser
 *
 * @return The user's selection
 */
- (SapphireChooserChoice)selection;

@end
