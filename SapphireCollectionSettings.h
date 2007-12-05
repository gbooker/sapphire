//
//  SapphireCollectionSettings.h
//  Sapphire
//
//  Created by Graham Booker on 9/3/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SapphireMediaMenuController.h"

@class SapphireMetaDataCollection;

/*!
 * @brief The Settings specific to collections
 *
 * This is a bit abstract in its opperation.  It is a SapphireMediaMenuController subclass that displays a list of collections, with or without a checkbox next to them, and a title.  Finally, it has an invokation for settings a value and getting a value.
 */
@interface SapphireCollectionSettings : SapphireMediaMenuController {
	NSArray							*names;				/*!< @brief The collection names, in order*/
	SapphireMetaDataCollection		*metaCollection;	/*!< @brief The collections, in order*/
	NSInvocation					*setInv;			/*!< @brief The set value invokation*/
	NSInvocation					*getInv;			/*!< @brief The get value invokation*/
}

/*!
 * @brief creates a new collection settings menu
 *
 * @param scene The scene
 * @param collection The collection
 * @return The collection settings menu
 */
- (id) initWithScene: (BRRenderScene *) scene collection:(SapphireMetaDataCollection *)collection;

/*!
 * @brief The set value selector
 *
 * This class can change any boolean setting on collections that have a setter and a getter.  This method sets the setter.
 *
 * @param selector The selector to set a value (must take a single BOOL)
 */
- (void)setSettingSelector:(SEL)selector;

/*!
 * @brief The set value selector
 *
 * This class can change any boolean setting on collections that have a setter and a getter.  This method sets the getter.
 *
 * @param selector The selector to set a value (must return a BOOL)
 */
- (void)setGettingSelector:(SEL)selector;

@end
