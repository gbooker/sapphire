/*
 * SapphireRadioSetting.h
 * Sapphire
 *
 * Created by Graham Booker on Mar. 27, 2008.
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

/*!
 * @brief Radio button control for a setting
 *
 * This class brings up a media menu controller which allows the user to select a setting from a list of choices.  This is useful for a setting which has 3 or more possible choices.
 */

@interface SapphireRadioSetting : SapphireMediaMenuController {
	NSArray				*choices;				/*!< @brief The choicess the user has to select from*/
	NSInvocation		*settingInvocation;		/*!< @brief The invocation to set the choice*/
	NSInvocation		*gettingInvocation;		/*!< @brief The invocation to get the choice*/
	NSObject			*target;				/*!< @brief The target to set and get the choice*/
	int					selected;				/*!< @brief The current selected choice*/
	NSArray				*choiceDesc;			/*!< @brief A description of choices*/
}

/*!
 * @brief Create a radio selection
 *
 * @param scene The scene
 * @param selectionChoices An array of NSStrings which contains all the possible selections
 * @param aTarget The target for the getting and setting selectors
 * @return The radio selection
 */
- (id)initWithScene:(BRRenderScene *)scene choices:(NSArray *)selectionChoices target:(NSObject *)aTarget;

/*!
 * @brief Set the setting selector
 *
 * @param setter The setting selector
 */
- (void)setSettingSelector:(SEL)setter;

/*!
 * @brief Set the getting selector
 *
 * @param getter The getting selector
 */
- (void)setGettingSelector:(SEL)getter;

/*!
 * @brief Set the choice descriptions
 *
 * @param choiceDescriptions The choice descriptions
 */
- (void)setChoiceDescriptions:(NSArray *)choiceDescriptions;

@end
