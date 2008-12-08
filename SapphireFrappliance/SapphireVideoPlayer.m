/*
 * SapphireVideoPlayer.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
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

#import "SapphireVideoPlayer.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import <QTKit/QTKit.h>
#import <objc/objc-class.h>

/*This is a private function somewhere, so declare to remove warnings*/
@interface QTMovie (whoKnows)
- (BOOL)hasChapters;
@end

/*These interfaces are to access variables not available*/
@interface BRQTKitVideoPlayer (privateFunctions)
- (BRVideo *)gimmieVideo;
@end

@interface BRVideo (privateFunctions)
- (Movie)gimmieMovie;
@end

@implementation BRQTKitVideoPlayer (privateFunctions)
- (BRVideo *)gimmieVideo
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_video");
	
	return *(BRVideo * *)(((char *)self)+ret->ivar_offset);
}
@end

@implementation BRVideo (privateFunctions)
- (Movie)gimmieMovie
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_movie");
	
	if([SapphireFrontRowCompat usingTakeTwo])
		return *(Movie *)(((char *)self)+ret->ivar_offset);
	QTMovie *qtmov = *(QTMovie * *)(((char *)self)+ret->ivar_offset);
	return [qtmov quickTimeMovie];
}
@end

typedef enum
	{
		kBRMediaPlayerStateStopped =		0,
		kBRMediaPlayerStatePaused,
		kBRMediaPlayerStateLoading,
		kBRMediaPlayerStatePlaying,
		kBRMediaPlayerStateFastForwardLevel1,
		kBRMediaPlayerStateFastForwardLevel2,
		kBRMediaPlayerStateFastForwardLevel3,
		kBRMediaPlayerStateRewindLevel1,
		kBRMediaPlayerStateRewindLevel2,
		kBRMediaPlayerStateRewindLevel3,
		kBRMediaPlayerStateSlowForwardLevel1,
		kBRMediaPlayerStateSlowForwardLevel2,
		kBRMediaPlayerStateSlowForwardLevel3,
		kBRMediaPlayerStateSlowRewindLevel1,
		kBRMediaPlayerStateSlowRewindLevel2,
		kBRMediaPlayerStateSlowRewindLevel3,
		
		kBRMediaPlayerStateRewind = kBRMediaPlayerStateRewindLevel1,	// default
		kBRMediaPlayerStateFastForward = kBRMediaPlayerStateFastForwardLevel1,	// default
		
		kBRMediaPlayerStateRESERVED	=		20,
		
		// Individual player subclasses may create their own states beyond the
		// reserved states. For instance, the DVD player may want to create states
		// for when it's in menus.
		
	} BRMediaPlayerState;

@interface BRQTKitVideoPlayer (compat)
-(BOOL)setState:(BRMediaPlayerState)state error:(NSError **)error;
-(BOOL)setMedia:(BRBaseMediaAsset *)asset inTrackList:(NSArray *)tracklist error:(NSError **)error;
-(BOOL)setMediaAtIndex:(long)index inTrackList:(NSArray *)tracklist error:(NSError **)error;
-(double)duration;
-(double)elapsedTime;
@end


#define LOW_SKIP_TIME 5.0f

typedef enum {
	STATE_COMMAND_RESET,
	STATE_COMMAND_FORWARD,
	STATE_COMMAND_BACKWARD,
} StateCommand;

@implementation SapphireVideoPlayer

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	/* Initial skip times */
	skipTime = LOW_SKIP_TIME;
	state = SKIP_STATE_NONE;
	
	return self;
}

- (void)dealloc
{
//	[resetTimer invalidate];
	[super dealloc];
}

- (BOOL)movieHasChapters:(Movie)mov
{
	int tkCount = GetMovieTrackCount(mov);
	int i;
	for(i=0; i<tkCount; i++)
	{
		Track track = GetMovieIndTrack(mov, i);
		if(!GetTrackEnabled(track))
			continue;
		
		if(GetTrackReference(track, 'chap', 1) != NULL)
			return YES;
	}
	
	return NO;
}

- (void)checkIfCanEnable
{
	/*Check to see if the movie has any chapters by default*/
	Movie myMovie = [[self gimmieVideo] gimmieMovie];
	
	BOOL hasChapters = [self movieHasChapters:myMovie];
	duration = ((double)GetMovieDuration(myMovie)) / ((double)GetMovieTimeScale(myMovie));
	
	if(!hasChapters)
		enabled = TRUE;
}

- (BOOL)prerollMedia:(NSError * *)fp8
{
	BOOL ret = [super prerollMedia:fp8];
	
	if(!ret)
		return ret;
	
	[self checkIfCanEnable];

	return ret;
}

-(BOOL)setState:(BRMediaPlayerState)playState error:(NSError **)error;
{
	BOOL ret = [super setState:playState error:error];
	
	if(!ret)
		return ret;

	if(!enabledChecked)
	{
		[self checkIfCanEnable];
		enabledChecked = YES;
	}
	
	return ret;
}

- (void)setNewTimer
{
	/*Reset the skip times after 3 seconds of non use*/
	[resetTimer invalidate];
	resetTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(resetTimes) userInfo:nil repeats:NO];
}

- (double)offsetForCommand:(StateCommand)command
{
	double ret = 0.0f;
	
	switch(command)
	{
		case STATE_COMMAND_RESET:
			state = SKIP_STATE_NONE;
			skipTime = LOW_SKIP_TIME;
			break;

		case STATE_COMMAND_FORWARD:
			switch(state)
			{
				case SKIP_STATE_NONE:
				case SKIP_STATE_FORWARD_INCREASING:
					state = SKIP_STATE_FORWARD_INCREASING;
					ret = skipTime;
					skipTime *= 2;
					break;
				case SKIP_STATE_BACKWARD_INCREASING:
					state = SKIP_STATE_DECREASING;
					skipTime /= 4;
				case SKIP_STATE_DECREASING:
					ret = skipTime;
					skipTime = MAX(skipTime / 2, LOW_SKIP_TIME);
			}
			break;
			
		case STATE_COMMAND_BACKWARD:
			switch(state)
			{
				case SKIP_STATE_NONE:
				case SKIP_STATE_BACKWARD_INCREASING:
					state = SKIP_STATE_BACKWARD_INCREASING;
					ret = -skipTime;
					skipTime *= 2;
					break;
				case SKIP_STATE_FORWARD_INCREASING:
					state = SKIP_STATE_DECREASING;
					skipTime /= 4;
				case SKIP_STATE_DECREASING:
					ret = -skipTime;
					skipTime = MAX(skipTime / 2, LOW_SKIP_TIME);
			}
			break;
	}
	return ret;
}

- (void)resetTimes
{
	/*Reset the times from the timer above*/
	resetTimer = nil;
	[self offsetForCommand:STATE_COMMAND_RESET];
}

- (double)_nextChapterMark
{
	/*Get the location of the next chapter mark*/
	if(!enabled)
		return [super _nextChapterMark];
	/*Compute our's*/
	double current = [self elapsedPlaybackTime];
	double ret = current + [self offsetForCommand:STATE_COMMAND_FORWARD];
	
	if(ret > duration + 5.0f)
	{
		/*Halve the distance to the end of the file if skipping so much*/
		ret = (current + duration) / 2;
		skipTime = duration - current;
	}
	
	/*Start the reset timer*/
	[self setNewTimer];
	
	return ret;
}

- (double)getPreviousChapterMarkAndUpdate:(BOOL)update
{
	/*Compute our previous chapter*/
	double current = [self elapsedPlaybackTime];
	double ret;
	if(update)
		ret = current - [self offsetForCommand:STATE_COMMAND_BACKWARD];
	else if(state == SKIP_STATE_DECREASING)
		ret = current - skipTime * 2;
	else
		ret = current - skipTime / 2;
	
	/*Make sure we don't go past the beginning of the file*/
	if(ret < 0.0f)
		ret = 0.0f;
	
	return ret;
}

- (double)_previousChapterMark
{
	/*Get the location of the previous chapter mark*/
	if(!enabled)
		return [super _previousChapterMark];
	
	/*Compute our's*/
	double ret = [self getPreviousChapterMarkAndUpdate:YES];
	
	/*Start the reset timer*/
	[self setNewTimer];

	return ret;
}

- (double)_virtualChapterMark
{
	if(!enabled)
		return [super _virtualChapterMark];
	/*If we are enabled, disable the virtual chapter marks*/
	return 0.0f;
}

- (double)_currentChapterMark
{
	if(!enabled)
		return [super _currentChapterMark];
	
	return [self getPreviousChapterMarkAndUpdate:NO];
}

- (BOOL)setMedia:(BRBaseMediaAsset *)asset error:(NSError **)error
{
	if([SapphireFrontRowCompat usingTakeTwoDotTwo])
	{
		if([[SapphireVideoPlayer superclass] instancesRespondToSelector:@selector(setMedia:inTrackList:error:)])
			return [super setMedia:asset inTrackList:[NSArray arrayWithObject:asset] error:error];
		else
			return [super setMediaAtIndex:0 inTrackList:[NSArray arrayWithObject:asset] error:error];
	}
	return [super setMedia:asset error:error];
}

- (double)elapsedPlaybackTime
{
	if([[SapphireVideoPlayer superclass] instancesRespondToSelector:@selector(elapsedPlaybackTime)])
		return [super elapsedPlaybackTime];
	return [super elapsedTime];
}

- (double)trackDuration
{
	if([[SapphireVideoPlayer superclass] instancesRespondToSelector:@selector(trackDuration)])
		return [super trackDuration];
	return [super duration];
}

@end
