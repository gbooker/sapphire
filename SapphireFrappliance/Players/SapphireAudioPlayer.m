/*
 * SapphireAudioPlayer.m
 * Sapphire
 *
 * Created by Graham Booker on Jul. 28, 2007.
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

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireAudioPlayer.h"
#import "SapphireAudioMedia.h"
#import "SapphireFileMetaData.h"
#import "SapphireVideoPlayerController.h"
#import <QTKit/QTKit.h>

#define SKIP_INTERVAL 0.5
#define SKIP_ACCELL 0.5 * SKIP_INTERVAL

@interface BRMusicPlayer (compat)
-(BOOL)setMedia:(id)media inTrackList:(id)trackList error:(NSError **)error;
-(BOOL)setMediaAtIndex:(long)index inTrackList:(id)trackList error:(NSError **)error;
@end

//Stolen from ATVFiles
typedef enum {
	BRMusicPlayerStateStopped = 0,
	BRMusicPlayerStatePaused = 1,
	BRMusicPlayerStatePlaying = 3,
	BRMusicPlayerStateSeekingForward = 4,
	BRMusicPlayerStateSeekingBack = 7
} BRMusicPlayerState;

@interface SapphireAudioPlayer (private)
- (void)setState:(int)newState;
- (void)stopUITimer;
- (void)setSkipTimer;
- (void)doSkip:(NSTimer *)timer;
- (void)stopSkip;
- (void)updateUI:(NSTimer *)Timer;
- (void)setPlayerState:(BRMusicPlayerState)newState;
@end

@implementation SapphireAudioPlayer

- (id) init {
	self = [super init];
	if (self == nil)
		return nil;

	state = 0;

	return self;
}

- (void) dealloc
{
	[movie release];
	[self stopUITimer];
	[self stopSkip];
	[myMedia release];
	[myTrackList release];
	[super dealloc];
}

- (int)playerState
{
	return state;
}

- (void)setMedia:(SapphireAudioMedia *)media inTracklist:(NSArray *)tracklist error:(NSError * *)error
{
	SapphireFrontRowCompatATVVersion version = [SapphireFrontRowCompat atvVersion];
	if(version >= SapphireFrontRowCompatATVVersion2Dot3)
		[super setMediaAtIndex:[tracklist indexOfObject:media] inTrackList:tracklist error:error];
	else if (version >= SapphireFrontRowCompatATVVersion2Dot2)
		[super setMedia:media inTrackList:tracklist error:error];
	else
		[super setMedia:media inTracklist:tracklist error:error];
	
	[myMedia release];
	[myTrackList release];
	myMedia = [media retain];
	myTrackList = [tracklist retain];
	
	if(error != NULL && *error == nil)
	{
		soundState = enablePassthrough([media fileMetaData]);
		movie = [[QTMovie alloc] initWithURL:[NSURL URLWithString:[media mediaURL]] error:error];
		[media setMovie:movie];
		[self setElapsedPlaybackTime:[media bookmarkTimeInSeconds]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kBRMediaPlayerCurrentAssetChanged object:media];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPCurrentAssetChanged" object:media];
}

- (SapphireAudioMedia *)media
{
	return myMedia;
}

- (NSArray *)tracklist
{
	return myTrackList;
}

- (float)elapsedPlaybackTime
{
	QTTime current = [movie currentTime];
	double ret = 0.0;
	QTGetTimeInterval(current, &ret);
	return (float)ret;
}

- (double)elapsedTime
{
	return [self elapsedPlaybackTime];
}

- (void)setElapsedPlaybackTime:(float)time
{
	QTTime newTime = QTMakeTimeWithTimeInterval((double)time);
	[movie setCurrentTime:newTime];
	[self updateUI:nil];
}

- (double)trackDuration
{
	QTTime duration = [movie duration];
	double ret = 0.0;
	QTGetTimeInterval(duration, &ret);
	return (float)ret;
}

- (NSString *)currentChapterTitle
{
	return [movie attributeForKey:QTMovieDisplayNameAttribute];
}

- (BOOL)initiatePlayback:(NSError * *)error
{
	[movie stop];
	[movie gotoBeginning];
	return YES;
}

-(void)setState:(int)newState error:(NSError **)error
{
	[self setPlayerState:newState];
}

- (void)setState:(int)newState
{
	[self setPlayerState:newState];
}

- (void)setPlayerState:(BRMusicPlayerState)newState
{
	state = newState;
	switch (state) {
		case BRMusicPlayerStatePlaying:
		{
			id media = [self media];
			[[NSNotificationCenter defaultCenter] postNotificationName:kBRMediaPlayerCurrentAssetChanged object:media];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPCurrentAssetChanged" object:media];
			[self stopSkip];
			updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];
			[movie play];
			break;
		}
		case BRMusicPlayerStatePaused:
			[self stopSkip];
			[self stopUITimer];
			[movie stop];
			break;
		case BRMusicPlayerStateStopped:
			[self stopSkip];
			[self stopUITimer];
			[movie stop];
			SapphireFileMetaData *file = [(SapphireAudioMedia *)[self media] fileMetaData];
			float elapsed = [self elapsedPlaybackTime];
			float duration = [self trackDuration];
			if(elapsed >= duration)
				[file setWatchedValue:YES];
			else
				[file setResumeTimeValue:elapsed];
			teardownPassthrough(soundState);
			break;
		case BRMusicPlayerStateSeekingBack:
			[self setSkipTimer];
			skipSpeed = -1;
			break;
		case BRMusicPlayerStateSeekingForward:
			[self setSkipTimer];
			skipSpeed = 1;
			break;
		default:
			NSLog(@"I was told to go into state %d", newState);
			break;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPStateChanged" object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:kBRMediaPlayerStateChanged object:self];
}

- (void)play
{
	[self setPlayerState:BRMusicPlayerStatePlaying];
}

- (void)pause
{
	[self setPlayerState:BRMusicPlayerStatePaused];
}

- (void)stop
{
	[self setPlayerState:BRMusicPlayerStateStopped];
}

- (void)stopUITimer
{
	[updateTimer invalidate];
	updateTimer = nil;
}

- (void)pressAndHoldLeftArrow
{
	[self setPlayerState:BRMusicPlayerStateSeekingBack];
}

- (void)pressAndHoldRightArrow
{
	[self setPlayerState:BRMusicPlayerStateSeekingForward];
}

- (void)setSkipTimer
{
	[self stopSkip];
	skipTimer = [NSTimer scheduledTimerWithTimeInterval:SKIP_INTERVAL target:self selector:@selector(doSkip:) userInfo:nil repeats:YES];
	[self doSkip:nil];
}

- (void)doSkip:(NSTimer *)timer
{
	float time = [self elapsedPlaybackTime];
	if(skipSpeed < 0)
	{
		time += skipSpeed * SKIP_INTERVAL * 3;
		skipSpeed = MAX(skipSpeed - SKIP_ACCELL, -16);
	}
	else
	{
		time += skipSpeed * SKIP_INTERVAL * 2;
		skipSpeed = MIN(skipSpeed + SKIP_ACCELL, 16);
	}
	double duration = [self trackDuration];
	if(time < 0)
	{
		time = 0;
		[self stopSkip];
	}
	else if(time > duration)
	{
		time = duration;
	}
	[self setElapsedPlaybackTime:time];
	[self updateUI:timer];
}

- (void)stopSkip
{
	skipSpeed = 0;
	[skipTimer invalidate];
	skipTimer = nil;
}

- (void)resume
{
	[self play];
}

- (void)leftArrowClick
{
	[movie gotoBeginning];
	[self updateUI:nil];
}

- (void)rightArrowClick
{
	[movie gotoEnd];
	[self updateUI:nil];
}

- (void)updateUI:(NSTimer *)Timer
{
	if([self elapsedPlaybackTime] >= [self trackDuration])
		[self stop];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPPlaybackProgressChanged" object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:kBRMediaPlayerPlaybackProgressChanged object:self];
}

@end
