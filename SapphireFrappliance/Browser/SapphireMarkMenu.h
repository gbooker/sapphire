/*
 * SapphireMarkMenu.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
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
@class SapphireMetaData;

/*!
 * @brief A subclass of SapphireMediaMenuController for marking files
 *
 * This class is designed to provide the user an interface for changing metadata about a file.  It presents the user with a menu to choose from.
 */
@interface SapphireMarkMenu : SapphireMediaMenuController {
	BOOL				isDir;				/*!< @brief YES if the current metadata is a directory*/
	NSMutableArray		*marks;				/*!< @brief The mark menu items*/
	SapphireMetaData	*metaData;			/*!< @brief The metadata currently being marked*/
}

/*!
 * @brief Create a mark menu for a directory or file
 *
 * Creates a new mark menu with metadata.  The resulting menu can be pushed on the controller stack.
 *
 * @param scene The scene
 * @param meta The metadata
 * @return A new mark menu
 */
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireMetaData *)meta;

@end
