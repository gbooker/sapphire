/*
 * SapphireCenteredMenuController.h
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

/*!
 * @brief A layout mechanism for the list
 *
 * Frontrow has a completely different way of doing layouts.  The two methods for doing a layout of a list both call this method asking how to lay it out.  This allows a single location for the list layout to be done and work in both cases.
 */
@protocol SapphireListLayoutDelegate <NSObject>
/*!
 * @brief Get the rect of the list
 *
 * @param listFrame The current rect of the list
 * @param master The rect of the master layer
 * @return The new rect of the list
 */
- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master;
@end

/*!
 * @brief A compatibility class for frontrow
 *
 * Frontrow's classes do not have initWithScene since the render scene is completely different.  To work around this, Sapphire has a collection of classes which intercept initWithScene, and call the appropriate real function.  The scene method is also intercepted as well.
 *
 * This class also intercepts the layout of the list and calls itself to find the real layout of the list.  See SapphireListLayoutDelegate.
 */
@interface SapphireCenteredMenuController : BRCenteredMenuController <SapphireListLayoutDelegate>{
	int		padding[16];	/*!< @brief The classes are of different sizes.  This padding prevents a class compiled with one size to overlap when used with a class of a different size*/
}

/*!
 * @brief Begin of the push
 *
 * On the ATV < 2.3, this takes the place of willBePushed.  On ATV ≥ 2.3, this is the first part of wasPushed
 */
- (void)doInitialPush;

/*!
 * @brief Begin of the pop
 *
 * On the ATV < 2.3, this takes the place of willBePopped.  On ATV ≥ 2.3, this is the first part of wasPopped
 */
- (void)doInitialPop;

/*!
 * @brief Begin of the bury
 *
 * On the ATV < 2.3, this takes the place of willBeBuried.  On ATV ≥ 2.3, this is the first part of wasBuried
 */
- (void)doInitialBury;
- (void)wasBuried;

/*!
 * @brief Begin of the exhume
 *
 * On the ATV < 2.3, this takes the place of willBeExhumed.  On ATV ≥ 2.3, this is the first part of wasExhumed
 */
- (void)doInitialExhume;
- (void)wasExhumed;
@end
