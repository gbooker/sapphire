/*
 * BRLayerController.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 7, 2007.
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
