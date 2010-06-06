/*
 * CMPMPPlayer.h
 * CommonMediaPlayer
 *
 * Created by Kevin Bradley on June. 5 2010
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


@class CMPMPPlayerController;

@interface CMPMPPlayer : NSObject <CMPPlayer>{
	BRBaseMediaAsset			*asset;
	CMPMPPlayerController		*controller;
	UInt32						resumeTime;
	NSTimer						*stopTimer;
	BOOL						useStopTimer;
	NSTask						*mpTask;
	BOOL						isShuffled;
	BOOL						repeatFile;
	BOOL						isPlaylist;
	BOOL						usePassthrough;
}

- (BOOL)usePassthrough;
- (void)setUsePassthrough:(BOOL)value;

- (BOOL)isShuffled;
- (void)setIsShuffled:(BOOL)value;

- (BOOL)repeatFile;
- (void)setRepeatFile:(BOOL)value;

- (BOOL)isPlaylist;
- (void)setIsPlaylist:(BOOL)value;

- (void)sendCommand:(NSString *)theString;

- (BOOL)useStopTimer;
- (void)setUseStopTimer:(BOOL)value;

- (void)setController:(CMPMPPlayerController *)controller;
- (void)restart;
- (BOOL)playing;
- (void)volumeUp;
- (void)volumeDown;
- (void)seekTenForward;
- (void)seekTenBack;
- (void)initiatePlaybackWithResume:(BOOL *)resume;
- (void)stopPlayback;
- (void)setResumeTime:(UInt32)resumeTime;
- (void)play;
- (void)pause;
- (void)restart;
- (void)nextAudioStream;
- (void)nextSubStream;
- (double)elapsedPlaybackTime;
- (double)trackDuration;
@end
