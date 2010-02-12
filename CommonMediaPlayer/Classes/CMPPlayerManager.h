/*
 * CMPPlayerManager.h
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 1 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */

#import "CMPTypesDefines.h"

@protocol CMPPlayerController, CMPPlayer;

@interface CMPPlayerManager : NSObject {
	NSMutableSet			*knownPlayers;
	NSMutableSet			*knownControllers;
	NSMutableDictionary		*playersForTypes;	//Keys are types, values are dictionaries.  Resulting dictionaries are keyed by extension, default keyed by @"", values are NSArrays of classes which can handle this.
	NSMutableDictionary		*controllersForPlayerTypes;
}

+ (CMPPlayerManager *)sharedPlayerManager;

//types is a dictionary with the key being the type above, and value is an array of extensions (empty array means any extension)
- (void)registerPlayer:(Class)player forTypes:(NSDictionary *)types;
//preferences are same formate as playersForTypes listed above
- (id <CMPPlayer>)playerForPath:(NSString *)path type:(CMPPlayerManagerFileType)type preferences:(NSDictionary *)preferences;
- (id <CMPPlayerController>)playerControllerForPlayer:(id <CMPPlayer>)player scene:(BRRenderScene *)scene preferences:(NSDictionary *)preferences;

@end
