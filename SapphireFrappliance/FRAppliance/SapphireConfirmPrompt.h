/*
 * SapphireConfirmPrompt.h
 * Sapphire
 *
 * Created by Graham Booker on Feb. 11 2009.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import <SapphireCompatClasses/SapphireCenteredMenuController.h>
#import <SapphireCompatClasses/SapphireLayoutManager.h>

typedef enum {
	SapphireConfirmPromptResultAbort,
	SapphireConfirmPromptResultCancel,
	SapphireConfirmPromptResultOK,
} SapphireConfirmPromptResult;

@interface SapphireConfirmPrompt : SapphireCenteredMenuController <SapphireLayoutDelegate>{
	NSInvocation			*invoke;			/*!< @brief The invokation to make*/
	BRTextControl			*subtitle;			/*!< @brief The sub-title message*/
	NSString				*subText;			/*!< @brief The text of the sub-title message*/
}

/*!
 * @brief Create a new confirmation prompt display
 *
 * @param scene The scene
 * @param title The title for the display
 * @param sub The secondary title
 * @param invokation The invokation to make to start the process
 */
- (id)initWithScene:(BRRenderScene *)scene title:(NSString *)title subtitle:(NSString *)sub invokation:(NSInvocation *)invokation;

@end
