//
//  SapphireVideoPlayer.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireVideoPlayer.h"
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
- (QTMovie *)gimmieMovie;
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
- (QTMovie *)gimmieMovie
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_movie");
	
	return *(QTMovie * *)(((char *)self)+ret->ivar_offset);
}
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
	[resetTimer invalidate];
	[super dealloc];
}

- (BOOL)prerollMedia:(NSError * *)fp8
{
	BOOL ret = [super prerollMedia:fp8];
	
	if(!ret)
		return ret;
	
	/*Check to see if the movie has any chapters by default*/
	QTMovie *myMovie = [[self gimmieVideo] gimmieMovie];
	if(![myMovie hasChapters])
		enabled = TRUE;
	
	QTGetTimeInterval([myMovie duration], &duration);
	
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
	
	if(ret > duration + 10.0f)
		/*Halve the distance to the end of the file if skipping so much*/
		ret = (current + duration) / 2;
	
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

@end
