//
//  SapphireAudioPlayer.m
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireAudioPlayer.h"
#import "SapphireAudioMedia.h"
#import <QTKit/QTKit.h>

#define SKIP_INTERVAL 0.5
#define SKIP_ACCELL 0.5 * SKIP_INTERVAL

@interface SapphireAudioPlayer (private)
- (void)setState:(int)newState;
- (void)stopUITimer;
- (void)setSkipTimer;
- (void)doSkip:(NSTimer *)timer;
- (void)stopSkip;
- (void)updateUI:(NSTimer *)Timer;
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
	[super dealloc];
}

- (int)playerState
{
	return state;
}

- (void)setMedia:(SapphireAudioMedia *)media inTracklist:(NSArray *)tracklist error:(NSError * *)error
{
	[super setMedia:media inTracklist:tracklist error:error];
	if(*error == nil)
	{
		movie = [[QTMovie alloc] initWithURL:[NSURL URLWithString:[media mediaURL]] error:error];
		[media setMovie:movie];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPCurrentAssetChanged" object:media];
}

- (float)elapsedPlaybackTime
{
	QTTime current = [movie currentTime];
	double ret = 0.0;
	QTGetTimeInterval(current, &ret);
	return (float)ret;
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

- (void)setState:(int)newState
{
	state = newState;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPStateChanged" object:self];
}

- (void)play
{
	[self stopSkip];
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];
	[self setState:3];
	[movie play];
}

- (void)pause
{
	[self stopSkip];
	[self stopUITimer];
	[self setState:1];
	[movie stop];
}

- (void)stop
{
	[self stopSkip];
	[self stopUITimer];
	[self setState:0];
	[movie stop];
}

- (void)stopUITimer
{
	[updateTimer invalidate];
	updateTimer = nil;
}

- (void)pressAndHoldLeftArrow
{
	[self setSkipTimer];
	skipSpeed = -1;
}

- (void)pressAndHoldRightArrow
{
	[self setSkipTimer];
	skipSpeed = 1;
}

- (void)setSkipTimer
{
	[self stopSkip];
	skipTimer = [NSTimer scheduledTimerWithTimeInterval:SKIP_INTERVAL target:self selector:@selector(doSkip:) userInfo:nil repeats:YES];
	[self doSkip:nil];
}

- (void)doSkip:(NSTimer *)timer
{
	skipTimer = nil;
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
	updateTimer = nil;
	if([self elapsedPlaybackTime] >= [self trackDuration])
		[self stop];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPPlaybackProgressChanged" object:nil];
}

@end
