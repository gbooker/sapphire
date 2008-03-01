/*
 * SapphireMediaMenuController.h
 * Sapphire
 *
 * Created by Graham Booker on Oct. 29, 2007.
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

#import "SapphireCenteredMenuController.h"

/*!
 * @brief A compatibility class for frontrow
 *
 * Frontrow's classes do not have initWithScene since the render scene is completely different.  To work around this, Sapphire has a collection of classes which intercept initWithScene, and call the appropriate real function.  The scene method is also intercepted as well.
 */
@interface SapphireMediaMenuController : BRMediaMenuController <SapphireLayoutDelegate> {
	int		padding[16];	/*!< @brief The classes are of different sizes.  This padding prevents a class compiled with one size to overlap when used with a class of a different size*/
}

/*!
 * @brief Get the list selection
 *
 * ATV version 1.0 uses floating point values for selection, where as 1.1 and frontrow use integers.  This method returns the proper value in both cases
 *
 * @return The current list selection
 */
- (int)getSelection;

/*!
 * @brief Get the list selection
 *
 * ATV version 1.0 uses floating point values for selection, where as 1.1 and frontrow use integers.  This method sets the proper value in both cases
 *
 * @param sel The list selection
 */
- (void)setSelection:(int)sel;
@end
