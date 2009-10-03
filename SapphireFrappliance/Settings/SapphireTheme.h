/*
 * SapphireTheme.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 27, 2007.
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

extern NSString *RED_GEM_KEY;
extern NSString *BLUE_GEM_KEY;
extern NSString *GREEN_GEM_KEY;
extern NSString *YELLOW_GEM_KEY;
extern NSString *RED_BLUE_GEM_KEY;
extern NSString *GEAR_GEM_KEY;
extern NSString *CONE_GEM_KEY;
extern NSString *EYE_GEM_KEY;
extern NSString *IMDB_GEM_KEY;
extern NSString *OSCAR_GEM_KEY;
extern NSString *TVR_GEM_KEY;
extern NSString *AC3_GEM_KEY;
extern NSString *AUDIO_GEM_KEY;
extern NSString *VIDEO_GEM_KEY;
extern NSString *FILE_GEM_KEY;
extern NSString *REPORT_GEM_KEY;
extern NSString *IMPORT_GEM_KEY;
extern NSString *FRONTROW_GEM_KEY;
extern NSString *FAST_GEM_KEY;
extern NSString *NOTE_GEM_KEY;
extern NSString *TV_GEM_KEY;
extern NSString *MOV_GEM_KEY;
@class BRTexture, BRRenderScene;

/*!
 * @brief The Theme
 *
 * This class contains all the theme related materials for Sapphire.  It will dynamically create them upon demand and after the first request, return the same object to save CPU and memory.
 */
@interface SapphireTheme : NSObject {
	NSMutableDictionary		*gemDict;		/*!< @brief The left icons*/
	BRRenderScene			*scene;			/*!< @brief The render scene*/
	NSDictionary			*gemFiles;		/*!< @brief The left icon paths*/
}

/*!
 * @brief Get the shared theme
 *
 * @return The shared theme
 */
+ (id)sharedTheme;


/*!
 * @brief Sets the scene
 *
 * @param theScene The new scene
 */
- (void)setScene:(BRRenderScene *)scene;

/*!
 * @brief Load a gem for a type
 *
 * @param type The gem type
 * @return The gem's texture
 */
- (BRTexture *)gem:(NSString *)type;
@end
