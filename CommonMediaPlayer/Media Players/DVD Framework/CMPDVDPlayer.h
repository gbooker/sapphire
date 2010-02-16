/*
 * CMPDVDPlayer.h
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 2 2010
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

#import "CMPPlayer.h"

typedef enum {
	CMPDVDPlayerNavigationUp = 1,
	CMPDVDPlayerNavigationDown,
	CMPDVDPlayerNavigationLeft,
	CMPDVDPlayerNavigationRight,
	CMPDVDPlayerNavigationEnter,
}CMPDVDPlayerNavigation;

typedef enum {
	CMPDVDStateUnknown,
	CMPDVDStatePlaying,		// playing 1x or less (slow mo)
	CMPDVDStatePlayingStill,
	CMPDVDStatePaused,		// pause and step frame
	CMPDVDStateStopped,		// the DVDEvent for stopping has a 2nd parameter to indicate that the stop was initiated by the DVD disc
	// 0: user, 1: disc initiated
	CMPDVDStateScanningForward,		// playing greater than 1x
	CMPDVDStateScanningBackward,
	CMPDVDStateIdle,
	CMPDVDStatePlayingSlowForward,	// playing less than 1x	
	CMPDVDStatePlayingSlowBackward,	// playing less than 1x	
} CMPDVDState;

@class CMPDVDPlayerController, CMPDVDFrameworkLoadAction;

@interface CMPDVDPlayer : NSObject <CMPPlayer>{
	BRBaseMediaAsset			*asset;
	CMPDVDPlayerController		*controller;
	CMPDVDFrameworkLoadAction	*frameworkLoad;
	int							titleNumber;
	UInt16						titleCount;
	UInt32						resumeTime;
	UInt32						titleDuration;
	UInt32						currentElapsedTime;
}

- (void)setController:(CMPDVDPlayerController *)controller;

- (BOOL)playing;
- (BOOL)hasMenu;
- (BOOL)inMenu;
- (CMPDVDState)state;
- (int)playSpeed;  //If scanning, number will be speed, if playing slow, number will be 1/speed
- (int)chapters;
- (int)currentChapter;
- (NSString *)currentAudioFormat;
- (NSString *)currentSubFormat;
- (int)titleElapsedTime;
- (int)titleDurationTime;

- (void)initiatePlaybackWithResume:(BOOL *)resume;
- (void)stopPlayback;
- (void)doUserNavigation:(CMPDVDPlayerNavigation)navigation;

- (void)setResumeTime:(UInt32)resumeTime;
- (void)goToMenu;
- (void)play;
- (void)pause;
- (void)restart;
- (void)incrementScanRate;
- (void)decrementScanRate;
- (void)nextChapter;
- (void)previousChapter;
- (void)nextFrame;
- (void)previousFrame;

- (void)nextAudioStream;
- (void)nextSubStream;
+ (BOOL)isVolume:(NSString *)theVolume;
+ (BOOL)isImage:(NSString *)theVolume;
@end
