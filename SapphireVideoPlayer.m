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


@implementation SapphireVideoPlayer

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	/* Initial skip times */
	revTime = ffTime = 5.0f;
	
	return self;
}

- (void)dealloc
{
	[resetTimer invalidate];
	[meta release];
	[super dealloc];
}

- (void)setMetaData:(SapphireFileMetaData *)newMeta
{
	meta = [newMeta retain];
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
	
	return ret;
}

- (void)setNewTimer
{
	/*Reset the skip times after 3 seconds of non use*/
	[resetTimer invalidate];
	resetTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(resetTimes) userInfo:nil repeats:NO];
}

- (void)resetTimes
{
	/*Reset the times from the timer above*/
	resetTimer = nil;
	ffTime = revTime = 5.0f;
}

- (double)_nextChapterMark
{
	/*Get the location of the next chapter mark*/
	if(!enabled)
		return [super _nextChapterMark];
	/*Compute our's*/
	double current = [self elapsedPlaybackTime];
	double ret = current + ffTime;
	/*Double the ff time and reset the rev time*/
	ffTime *= 2.0f;
	revTime = 5.0f;
	/*Start the reset timer*/
	[self setNewTimer];
	
	return ret;
}

- (double)_previousChapterMark
{
	/*Get the location of the previous chapter mark*/
	if(!enabled)
		return [super _previousChapterMark];
	/*Compute our's*/
	double current = [self elapsedPlaybackTime];
	double ret = current - revTime;
	/*Double the rev time and reset the ff time*/
	revTime *= 2.0f;
	ffTime = 5.0f;
	
	/*Make sure we don't go past the beginning of the file*/
	if(ret < 0.0f)
		ret = 0.0f;
	/*Start the reset timer*/
	[self setNewTimer];

	return ret;
}

@end
