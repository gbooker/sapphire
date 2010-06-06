/*
 * SapphireCollectionSettings.h
 * Sapphire
 *
 * Created by Graham Booker on Sep. 3, 2007.
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

#import <Cocoa/Cocoa.h>
#import <SapphireCompatClasses/SapphireMediaMenuController.h>

@class SapphireMetaDataCollection;

/*!
 * @brief The Settings specific to collections
 *
 * This is a bit abstract in its opperation.  It is a SapphireMediaMenuController subclass that displays a list of collections, with or without a checkbox next to them, and a title.  Finally, it has an invocation for settings a value and getting a value.
 */
@interface SapphireCollectionSettings : SapphireMediaMenuController {
	NSArray							*collections;		/*!< @brief The collections, in order*/
	NSManagedObjectContext			*moc;				/*!< @brief The context*/
	NSInvocation					*setInv;			/*!< @brief The set value invocation*/
	NSInvocation					*getInv;			/*!< @brief The get value invocation*/
}

/*!
 * @brief creates a new collection settings menu
 *
 * @param scene The scene
 * @param context The context
 * @return The collection settings menu
 */
- (id) initWithScene: (BRRenderScene *) scene context:(NSManagedObjectContext *)context;

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
