/*
 * SapphireVirtualDirectoryLoading.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 27, 2007.
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

#import <SapphireCompatClasses/SapphireTextWithSpinnerController.h>

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
