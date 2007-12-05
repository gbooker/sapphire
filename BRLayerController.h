//
//  BRLayerController.h
//  Sapphire
//
//  Created by Graham Booker on 11/7/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import <Backrow/BRControllerStack.h>
#import <Backrow/BRPanel.h>

/*!
 * @brief Not a really a class
 *
 * This class is only here to make the compiler shut up.  It is never used.  The only time the BRLayerController is ever loaded is on frontrow, which already has a BRController class (in which case, if this class were real, the load would fail).
 */
@interface BRController : BRPanel
{
    NSMutableDictionary *_labels;
    BRControllerStack *_stack;
}
@end

/*!
 * @brief Provide a BRLayerController for frontrow
 *
 * Frontrow doesn't have a BRLayerController but, it has a BRController.  Everywhere we use BRLayerController in Sapphire, we really desire a BRController in frontrow.  This class exists in a framework which is only loaded on frontrow, thus providing the magic of this substitution.
 */
@interface BRLayerController : BRController {
}

@end
