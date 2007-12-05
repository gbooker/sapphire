//
//  SapphireVirtualDirectoryLoading.h
//  Sapphire
//
//  Created by Graham Booker on 11/27/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTextWithSpinnerController.h"

@class SapphireVirtualDirectory, SapphireBrowser;

/*!
 * @brief A subclass of SapphireTextWithSpinnerController for displaying a wait screen on virtual directories
 *
 * This class provides a wait screen to present to the user until the virtual directory is loaded.  A timer continues to check to see if the directory is loaded, and when it is, switch to it.
 */
@interface SapphireVirtualDirectoryLoading : SapphireTextWithSpinnerController {
	NSTimer						*checkTimer;	/*!< @brief A timer to use to check if the directory is loaded yet (not retained)*/
	SapphireBrowser				*browser;		/*!< @brief The browser to switch to when the load is complete*/
	SapphireVirtualDirectory	*directory;		/*!< @brief The directory which is loading*/
}

/*!
 * @brief Sets the directory we are waiting on
 *
 * Since the wait screen switches after the directory loads, it needs a directory to continually check.
 *
 * @param dir The directory to wait on
 */
- (void)setDirectory:(SapphireVirtualDirectory *)dir;

/*!
 * @brief Sets the browser to switch to when done
 *
 * Since the wait screen switches automatically when complete, it needs the browser to use upon completion
 *
 * @param browse The browser to switch to
 */
- (void)setBrowser:(SapphireBrowser *)browse;

@end
