/*
 * SapphireTextEntryController.h
 * Sapphire
 *
 * Created by Graham Booker on Jan. 6, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import <SapphireCompatClasses/SapphireLayerController.h>
#import <SapphireCompatClasses/SapphireLayoutManager.h>

@interface SapphireTextEntryController : SapphireLayerController <BRTextEntryDelegate> {
	BRTextControl		*title;				/*!< @brief The title control*/
	BRTextEntryControl	*textEntry;			/*!< @brief The text entry controller*/
	NSInvocation		*entryComplete;		/*!< @brief Invocation to make upon completion (argument will be resulting string)*/
}

/*!
 * @brief Creates a new text entry control
 *
 * @param scene The Scene
 * @param title The title for display
 * @param defaultText The default text for the text
 * @param completion The invocation to make upon text entry completion
 * @return The controller
 */
- (id)initWithScene:(BRRenderScene *)scene title:(NSString *)title defaultText:(NSString *)defaultText completionInvocation:(NSInvocation *)completetion;

@end
