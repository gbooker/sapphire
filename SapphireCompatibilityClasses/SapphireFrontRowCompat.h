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
 * @brief Are we on ATV Take Two?
 *
 * @return YES if on take two, NO otherwise
 */
+ (BOOL)usingTakeTwo;

/*!
 * @brief Are we on ATV 2.2?
 *
 * @return YES if on 2.2, NO otherwise
 */
+ (BOOL)usingTakeTwoDotTwo;

/*!
 * @brief Are we on ATV 2.3?
 *
 * @return YES if on 2.3, NO otherwise
 */
+ (BOOL)usingTakeTwoDotThree;

/*!
 * @brief Load an image at a path
 *
 * This returns a CGImageRef or a BRImage, depending on platform.
 *
 * @return The BRImage on Front Row or CGImageRef on ATV at a path
 */
+ (id)imageAtPath:(NSString *)path;

/*!
 * @brief Load an image texture at a path
 *
 * This is like imageAtPath:, only it will return a BRBitmapTexture
 * on the ATV for setting as a menu item icon.
 *
 * @return BRImage or BRBitmapTexture at a path
 */
+ (id)imageAtPath:(NSString *)path scene:(BRRenderScene *)scene;

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
 * @brief Set a menu item's title with attributes
 *
 * Menu items work differently in fronrow
 *
 * @param title The new title
 * @param attributes The new attributes
 * @param menu The menu item to set
 */
+ (void)setTitle:(NSString *)title withAttributes:(NSDictionary *)attributes forMenu:(BRAdornedMenuItemLayer *)menu;

/*!
 * @brief Get a menu item's title
 *
 * Menu items work differently in frontrow
 *
 * @param menu The menu item
 */
+ (NSString *)titleForMenu:(BRAdornedMenuItemLayer *)menu;

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
 * @brief Get the blue unplayed dot image
 *
 * @param scene The scene, if it exists
 * @return The blue unplayed dot image
 */
+ (id)unplayedPodcastImageForScene:(BRRenderScene *)scene;

/*!
 * @brief Get the return to arrow image
 *
 * @param scene The scene, if it exists
 * @return The return to arrow image
 */  
+ (id)returnToImageForScene:(BRRenderScene *)scene;

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
 * @brief Insert a sublayer at a position in a control
 * 
 * Controllers and layers are different in frontrow
 *
 * @param sub The sublayer to add
 * @param controller The controller to add to
 * @param index The index to add the sublayer at
 */
+ (void)insertSublayer:(id)sub toControl:(id)controller atIndex:(long)index;

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
 * @brief Get the text control's rendered size within constraints
 *
 * @param text The text control
 * @param maxSize The contrained maximum size
 * @return The rendered size
 */
+ (NSSize)textControl:(BRTextControl *)text renderedSizeWithMaxSize:(NSSize)maxSize;

/*!
 * @brief Create a new text entry control
 *
 * Controllers are alloced differently in frontrow
 *
 * @param scene The scene, if exists.
 */
+ (BRTextEntryControl *)newTextEntryControlWithScene:(BRRenderScene *)scene;

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
 * @brief Create a new image layer
 *
 * Layers are different in frontrow
 *
 * @param scene The scene, if it exists.
 */
+ (BRImageLayer *)newImageLayerWithScene:(BRRenderScene *)scene;

/*!
 * @brief Set the image on a BRImageLayer
 *
 * FR uses BRImage instead of BRTexture
 *
 * @param image The image (BRImage on FR/BRTexture on ATV)
 */
+ (void)setImage:(id)image forLayer:(BRImageLayer *)layer;

/*!
 * @brief Create a new image layer with an image
 *
 * Just a shortcut around the previous two
 *
 * @param image The image (BRImage on FR/BRTexture on ATV)
 * @param scene The scene, if it exists.
 */
+ (BRImageLayer *)newImageLayerWithImage:(id)image scene:(BRRenderScene *)scene;

/*!
 * @brief Render scene on the ATV
 *
 * Only does something on the ATV; frontrow has no need for this
 *
 * @param scene The scene to render, if exists.
 */
+ (void)renderScene:(BRRenderScene *)scene;

/*!
 * @brief Create a new BRAlertController
 *
 * Scene doesn't exist on frontrow
 *
 * @param type The type of the alert
 * @param titled The title of the alert
 * @param primaryText the primary text of the alert
 * @param secondaryText the secondary text of the alert
 * @param scene the scene
 */
+ (BRAlertController *)alertOfType:(int)type titled:(NSString *)title primaryText:(NSString *)primaryText secondaryText:(NSString *)secondaryText withScene:(BRRenderScene *)scene;

/*!
 * @brief Create a new BROptionDialog
 *
 * Scene doesn't exist in frontrow
 *
 * @param scene the scene
 */
+ (BROptionDialog *)optionDialogWithScene:(BRRenderScene *)scene;

/*!
 * @brief Set the primary info text on a BROptionDialog
 *
 * Text/attributes are different on frontrow
 *
 * @param primaryInfoText the primary info text
 * @param attributes the attributes
 * @param dialog the BROptionDialog
 */
+ (void)setOptionDialogPrimaryInfoText:(NSString *)primaryInfoText withAttributes:(NSDictionary *)attributes optionDialog:(BROptionDialog *)dialog;

/*!
 * @brief Create a new BRTextWithSpinnerController
 *
 * Method is different on frontrow
 *
 * @param title the title
 * @param text the text
 * @param networkDependent unknown
 * @param scene the scene
 */
+ (BRTextWithSpinnerController *)textWithSpinnerControllerTitled:(NSString *)title text:(NSString *)text isNetworkDependent:(BOOL)networkDependent scene:(BRRenderScene *)scene;

/*!
 * @brief Sets whether a BRWaitSpinnerControl should spin or not
 *
 * @param spinner The spinner
 * @param spin YES if the spinner should spin, NO otherwise
 */
+ (void)setSpinner:(BRWaitSpinnerControl *)spinner toSpin:(BOOL)spin;

/*!
 * @brief Get the call stack addresses for an exception
 *
 * This function exists mostly because this method is different on Tiger and Leopard.  This is not a significant differece between the ATV and Frontrow
 *
 * @param exception The exception to examine
 * @return An array of call addresses if successful, nil otherwise
 */
+ (NSArray *)callStackReturnAddressesForException:(NSException *)exception;

/*!
 * @brief Get the sharedFrontRowPreferences object.
 *
 * On Apple TV < 2.1, the RUIPreferences class is used for this.  On 2.1, the class is renamed to BRPreferences.
 *
 * @return the preferences object
 */
+ (RUIPreferences *)sharedFrontRowPreferences;
@end

static inline void SapphireLoadFramework(NSString *frameworkPath)
{
	if(NSClassFromString(@"SapphireFrontRowCompat") == nil)
	{
		NSString *compatPath = [frameworkPath stringByAppendingPathComponent:@"SapphireCompatClasses.framework"];
		NSBundle *compat = [NSBundle bundleWithPath:compatPath];
		if( ![compat load]){ 
			@throw [NSException exceptionWithName:@"FileNotFoundException" reason:[NSString stringWithFormat:@"SapphireCompatClasses could not be loaded from path %@", compatPath] userInfo:nil];
		}
		if([SapphireFrontRowCompat usingFrontRow])
		{
			compatPath = [frameworkPath stringByAppendingPathComponent:@"SapphireLeopardCompatClasses.framework"];
			compat = [NSBundle bundleWithPath:compatPath];
			if( ![compat load]){ 
				@throw [NSException exceptionWithName:@"FileNotFoundException" reason:[NSString stringWithFormat:@"SapphireLeopardCompatClasses could not be loaded from path %@", compatPath] userInfo:nil];
			}
		}
		// ATV2
		if(NSClassFromString(@"BRMetadataPreviewController") == nil)
		{
			compatPath = [frameworkPath stringByAppendingPathComponent:@"SapphireTakeTwoCompatClasses.framework"];
			compat = [NSBundle bundleWithPath:compatPath];
			if( ![compat load]){ 
				@throw [NSException exceptionWithName:@"FileNotFoundException" reason:[NSString stringWithFormat:@"SapphireTakeTwoCompatClasses could not be loaded from path %@", compatPath] userInfo:nil];
			}
		}
		//ATV2.2
		if(NSClassFromString(@"BRVideoPlayerController") == nil)
		{
			compatPath = [frameworkPath stringByAppendingPathComponent:@"SapphireTakeTwoPointTwoCompatClasses.framework"];
			compat = [NSBundle bundleWithPath:compatPath];
			if( ![compat load]){ 
				@throw [NSException exceptionWithName:@"FileNotFoundException" reason:[NSString stringWithFormat:@"SapphireTakeTwoPointTwoCompatClasses could not be loaded from path %@", compatPath] userInfo:nil];
			}
		}
	}	
}

