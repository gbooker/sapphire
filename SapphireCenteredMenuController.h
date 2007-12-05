//
//  SapphireCenteredMenuController.h
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

/*!
 * @brief A layout mechanism for the list
 *
 * Frontrow has a completely different way of doing layouts.  The two methods for doing a layout of a list both call this method asking how to lay it out.  This allows a single location for the list layout to be done and work in both cases.
 */
@protocol SapphireLayoutDelegate <NSObject>
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
 * This class also intercepts the layout of the list and calls itself to find the real layout of the list.  See SapphireLayoutDelegate.
 */
@interface SapphireCenteredMenuController : BRCenteredMenuController <SapphireLayoutDelegate>{
	int		padding[16];	/*!< @brief The classes are of different sizes.  This padding prevents a class compiled with one size to overlap when used with a class of a different size*/
}

@end
