//
//  SapphireMarkMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"
@class SapphireMetaData, SapphirePredicate;

/*!
 * @brief A subclass of SapphireMediaMenuController for marking files
 *
 * This class is designed to provide the user an interface for changing metadata about a file.  It presents the user with a menu to choose from.
 */
@interface SapphireMarkMenu : SapphireMediaMenuController {
	BOOL				isDir;			/*!< @brief YES if the current metadata is a directory*/
	NSMutableArray		*names;			/*!< @brief The menu names for the mark menu*/
	NSMutableArray		*commands;		/*!< @brief The commands for the mark menu*/
	SapphireMetaData	*metaData;		/*!< @brief The metadata currently being marked*/
	SapphirePredicate	*predicate;		/*!< @brief The current predicate*/
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

/*!
 * @brief Sets the predicate
 *
 * Sets the predicate for the menu.  This is used directory metadata so commands only apply to those files which match the current predicate
 *
 * @param newPredicate The predicate to use
 */
- (void)setPredicate:(SapphirePredicate *)newPredicate;
@end
