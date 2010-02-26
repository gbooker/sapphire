/*
 * CMPPlayerController.h
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

@protocol CMPInstaller;

@protocol CMPInstallerDelegate <NSObject>

- (void)installer:(id <CMPInstaller>)installer didEndWithSettings:(NSDictionary *)settings;


@end


@protocol CMPPlayer, CMPPlayerController;

/*!
 * This protocol defines the delegate for the player controller
 *
 * Rather than define a set of queries for information to be passed from the player controller to the application, the application defines a delegate by which the controller passes information back
 */
@protocol CMPPlayerControllerDelegate <NSObject>

- (void)controller:(id <CMPPlayerController>)controlle:(NSDictionary *)settings;
/*!
 * Information about the controller; currently no info is defined
 */
- (NSDictionary *)controllerInfo;
@end

/*!
 * This protocol defines the player controller
 *
 * Player controllers define the user inteface portion of the playback.  Their actual playback will be initiated with a push
 */
@protocol CMPPlayerController <NSObject>

+ (NSSet *)knownPlayers;

/*!
 * Init with a scene and player.  The scene is included for compatibility with older ATV versions
 */
- (id)initWithScene:(BRRenderScene *)scene player:(id <CMPPlayer>)player;

- (id <CMPPlayer>)player;
/*!
 * The settings for playback, such as resume time
 */
- (void)setPlaybackSettings:(NSDictionary *)settings;
- (void)setPlaybackDelegate:(id <CMPPlayerControllerDelegate>)delegate;
- (id <CMPPlayerControllerDelegate>)delegate;

@end




#define CMPPlayerAudioSampleRateKey @"sample rate"
#define CMPPlayerAudioFormatKey @"audio format"
#define CMPPlayerResumeTimeKey @"resume"
#define CMPPlayerDurationTimeKey @"duration"
#define CMPPlayerUsePassthroughDeviceKey @"usePassthroughDevice"