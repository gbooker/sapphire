/*
 * SapphireLayoutManager.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 24, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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
 * @brief A layout mechanism for the other elements
 *
 * Frontrow has a completely different way of doing layouts.  The two methods for doing a layout of a list both call this method asking how to lay it out.  This allows a single location for the element layout to be done and work in both cases.
 */
@protocol SapphireLayoutDelegate <NSObject>

/*!
 * @brief Do the layout
 */
- (void)doMyLayout;
@end

/*!
 * @brief A Layout manager for custom objects that calls a delegate to do the layout
 *
 * Frontrow has a layout manager, which is needed now in 2.3 to work correctly.  This calls the delegate to do the actual layout so it provides a flexible one-time class to do the right call at the right time.
 */
@interface SapphireLayoutManager : NSObject
{
	id							realLayout;		/*!< @brief The layout manager the super wants to use*/
	id <SapphireLayoutDelegate>	delegate;		/*!< @brief The delegate to do the rest of the layout (not retained)*/
}

/*!
 * @brief Setup the layout manager on the control
 *
 * @param control The control (and delegate) for the layout
 * @return The layout manager (autoreleased)
 */
+ (id)setCustomLayoutOnControl:(BRLayerController <SapphireLayoutDelegate> *)control;

/*!
 * @brief create a layout manager with the super's layout manager
 *
 * @param real The super's layout manager
 * @return The layout manager
 */
- (id)initWithReal:(id)real;

/*!
 * @brief Set the delegate for the layout
 *
 * @param theDelegate The new delegate (not retained)
 */
- (void)setDelegate:(id <SapphireLayoutDelegate>)theDelegate;
@end

