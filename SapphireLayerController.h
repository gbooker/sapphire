//
//  SapphireLayerController.h
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//


/*!
 * @brief A compatibility class for frontrow
 *
 * Frontrow's classes do not have initWithScene since the render scene is completely different.  To work around this, Sapphire has a collection of classes which intercept initWithScene, and call the appropriate real function.  The scene method is also intercepted as well.
 */
@interface SapphireLayerController : BRLayerController {
	int		padding[16];	/*!< @brief The classes are of different sizes.  This padding prevents a class compiled with one size to overlap when used with a class of a different size*/
}

@end
