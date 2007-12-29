/*
 * SapphireFrontRowCompat.h
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

#define SapphireLoadFramework()\
if(NSClassFromString(@"SapphireFrontRowCompat") == nil)\
{\
	NSString *myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];\
	NSString *compatPath = [myBundlePath stringByAppendingPathComponent:@"Contents/Frameworks/CompatClasses.framework"];\
	NSBundle *compat = [NSBundle bundleWithPath:compatPath];\
	[compat load];\
	if([SapphireFrontRowCompat usingFrontRow])\
	{\
		myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];\
		compatPath = [[myBundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Contents/Frameworks/LeopardCompatClasses.framework"];\
		compat = [NSBundle bundleWithPath:compatPath];\
		[compat load];\
	}\
}

/*!
 * @brief A compatibility category for frontrow
 *
 * This is just here to make the compiler shut up.  The sharedInstance does not exist on the ATV, but it does on frontrow.  It is only called on frontrow.
 */
@interface BRRenderScene (compat)
/*!
 * @brief Get the shared insntance
 *
 * @return The shared instance
 */
+ (BRRenderScene *)sharedInstance;
@end

/*!
 * @brief A compatibility class for frontrow
 *
 * This class provides many compatibility functions for frontrow.  This class is never instanciated since it contains no data.  All of these functions could be implemented with C functions, but that looses the clarity of the exact meaning of parameters in Obj-C calls.
 */
@interface SapphireFrontRowCompat : NSObject {
}
/*!
 * @brief Are we on frontrow?
 *
 * @return YES if on frotrow, NO otherwise
 */
+ (BOOL)usingFrontRow;

/*!
 * @brief Load an image at a path
 *
 * This only works on frontrow
 *
 * @return The BRImage at a path
 */
+ (id)imageAtPath:(NSString *)path;

/*!
 * @brief Get a menu text menu item
 *
 * Menu items are of different classes on the ATV and in frontrow.
 *
 * @param scene The scene, if exists
 * @param folder YES if this is a folder, NO otherwise
 * @return The new menu item
 */
+ (BRAdornedMenuItemLayer *)textMenuItemForScene:(BRRenderScene *)scene folder:(BOOL)folder;

/*!
 * @brief Set a menu item's title
 *
 * Menu items work differently in fronrow
 *
 * @param title The new title
 * @param menu The menu item to set
 */
+ (void)setTitle:(NSString *)title forMenu:(BRAdornedMenuItemLayer *)menu;

/*!
 * @brief Set a menu item's right justified text
 *
 * Menu items work differently in fronrow
 *
 * @param text The new text
 * @param menu The menu item to set
 */
+ (void)setRightJustifiedText:(NSString *)text forMenu:(BRAdornedMenuItemLayer *)menu;

/*!
 * @brief Set a menu item's left icon
 *
 * Menu items work differently in fronrow
 *
 * @param icon The new icon
 * @param menu The menu item to set
 */
+ (void)setLeftIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu;

/*!
 * @brief Set a menu item's right icon
 *
 * Menu items work differently in fronrow
 *
 * @param icon The new icon
 * @param menu The menu item to set
 */
+ (void)setRightIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu;

/*!
 * @brief Get the checkmark image
 *
 * @param scene The secen, if exists
 * @return The checkmark image
 */
+ (id)selectedSettingImageForScene:(BRRenderScene *)scene;

/*!
 * @brief Get a controller's frame
 *
 * Controllers work differently in fronrow
 *
 * @param controller The controller
 * @return The frame of the controller
 */
+ (NSRect)frameOfController:(id)controller;

/*!
 * @brief Set a controller's text
 *
 * Controllers work differently in fronrow
 *
 * @param text The new text
 * @param attributes The new text's attributes
 * @param control The control to set
 */
+ (void)setText:(NSString *)text withAtrributes:(NSDictionary *)attributes forControl:(BRTextControl *)control;

/*!
 * @brief Add a divider to a menu
 *
 * Lists work differently in fronrow
 *
 * @param index The index to add the divider
 * @param list The list to add to
 */
+ (void)addDividerAtIndex:(int)index toList:(BRListControl *)list;

/*!
 * @brief Add a sublayer to a control
 *
 * Controllers work differently in fronrow
 *
 * @param sub The sublayer toadd
 * @param controller The controller to add to
 */
+ (void)addSublayer:(id)sub toControl:(id)controller;


/*!
 * @brief Create a new header control
 *
 * Controllers are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 */
+ (BRHeaderControl *)newHeaderControlWithScene:(BRRenderScene *)scene;

/*!
 * @brief Create a new button control
 *
 * Controllers are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 * @param size The size of the button
 */
+ (BRButtonControl *)newButtonControlWithScene:(BRRenderScene *)scene masterLayerSize:(NSSize)size;

/*!
 * @brief Create a new text control
 *
 * Controllers are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 */
+ (BRTextControl *)newTextControlWithScene:(BRRenderScene *)scene;

/*!
 * @brief Create a new progress bar widget
 *
 * Widgets are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 */
+ (BRProgressBarWidget *)newProgressBarWidgetWithScene:(BRRenderScene *)scene;

/*!
 * @brief Create a new marching icon layer
 *
 * Layers are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 */
+ (BRMarchingIconLayer *)newMarchingIconLayerWithScene:(BRRenderScene *)scene;

/*!
 * @brief Render scene on the ATV
 *
 * Only does something on the ATV; frontrow has no need for this
 *
 * @param scene The scene to render, if exists.
 */
+ (void)renderScene:(BRRenderScene *)scene;

/*!
 * @brief Get the call stack addresses for an exception
 *
 * This function exists mostly because this method is different on Tiger and Leopard.  This is not a significant differece between the ATV and Frontrow
 *
 * @param exception The exception to examine
 * @return An array of call addresses if successful, nil otherwise
 */
+ (NSArray *)callStackReturnAddressesForException:(NSException *)exception;
@end
