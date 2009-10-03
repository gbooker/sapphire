/*
 * SapphireErrorDisplayController.h
 * Sapphire
 *
 * Created by pnmerrill on Jan. 5, 2009.
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

#import <SapphireCompatClasses/SapphireCenteredMenuController.h>
#import <SapphireCompatClasses/SapphireLayoutManager.h>

@interface SapphireErrorDisplayController : SapphireCenteredMenuController <SapphireLayoutDelegate> {
	NSString		*errorString;		/*!< @brief The title of the error*/
	BRTextControl	*text;				/*!< @brief The text describing the error*/
}

/*!
 * @brief Creates a new error display
 *
 * @param scene The Scene
 * @param error The title of the error
 * @param longError The longer description of the error
 * @return The Menu
 */
- (id)initWithScene:(BRRenderScene *)scene error:(NSString *)error longError:(NSString *)longError;

@end
