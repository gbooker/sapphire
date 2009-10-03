/*
 * SapphireDisplayMenu.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 17, 2008.
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

#import <SapphireCompatClasses/SapphireMediaMenuController.h>

@protocol SapphireDirectory;

/*!
 * @brief A subclass of SapphireMediaMenuController for changing the directory's display
 *
 * This class presents the user with a menu to change the way this directory is displayed.
 * It allows for changing predicates as well as sorting mechanism.
 */
@interface SapphireDisplayMenu : SapphireMediaMenuController {
	NSMutableArray				*names;				/*!< @brief The menu names for the display menu*/
	NSMutableArray				*dispDescriptions;	/*!< @brief The descriptions for the display menu items*/
	NSMutableArray				*commands;			/*!< @brief The commands for the display menu*/
	id <SapphireDirectory>		dir;				/*!< @brief The metadata currently being changed*/
}

/*!
 * @brief Create a display menu for a directory
 *
 * Creates a new display menu with directory metadata.  The resulting menu can be pushed on the controller stack.
 *
 * @param scene The scene
 * @param directory The directory metadata
 * @return A new display menu
 */
- (id) initWithScene:(BRRenderScene *)scene directory:(id <SapphireDirectory>)directory;

@end
