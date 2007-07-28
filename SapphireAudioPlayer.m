//
//  SapphireAudioPlayer.m
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireAudioPlayer.h"
#import "SapphireAudioMedia.h"
#import <QTKit/QTKit.h>

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
	[updateTimer invalidate];
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

- (void)play
{
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];
	state = 3;
	[movie play];
}

- (void)pause
{
	[updateTimer invalidate];
	updateTimer = nil;
	state = 1;
	[movie stop];
}

- (void)stop
{
	[updateTimer invalidate];
	updateTimer = nil;
	state = 0;
	[movie stop];
	[movie gotoBeginning];
}

/*- (void)pressAndHoldLeftArrow;
- (void)pressAndHoldRightArrow;*/
- (void)resume
{
	[self play];
}

/*- (void)leftArrowClick;
- (void)rightArrowClick;*/

- (void)updateUI:(NSTimer *)Timer
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRMPPlaybackProgressChanged" object:nil];
}

@end
