//
//  SapphireVideoPlayer.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireVideoPlayer.h"
#import <QTKit/QTKit.h>

@interface QTMovie (whoKnows)
- (BOOL)hasChapters;
@end

@interface BRQTKitVideoPlayer (privateFunctions)
- (BRVideo *)gimmieVideo;
@end

@interface BRVideo (privateFunctions)
- (QTMovie *)gimmieMovie;
@end

@implementation BRQTKitVideoPlayer (privateFunctions)
- (BRVideo *)gimmieVideo
{
	return _video;
}
@end

@implementation BRVideo (privateFunctions)
- (QTMovie *)gimmieMovie
{
	return _movie;
}
@end


@implementation SapphireVideoPlayer

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
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
	
	QTMovie *myMovie = [[self gimmieVideo] gimmieMovie];
	if(![myMovie hasChapters])
		enabled = TRUE;
	
	return ret;
}

- (void)setNewTimer
{
	[resetTimer invalidate];
	resetTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(resetTimes) userInfo:nil repeats:NO];
}

- (void)resetTimes
{
	resetTimer = nil;
	ffTime = revTime = 5.0f;
}

- (double)_nextChapterMark
{
	if(!enabled)
		return [super _nextChapterMark];
	double current = [self elapsedPlaybackTime];
	double ret = current + ffTime;
	ffTime *= 2.0f;
	revTime = 5.0f;
	[self setNewTimer];
	
	return ret;
}

- (double)_previousChapterMark
{
	if(!enabled)
		return [super _previousChapterMark];
	double current = [self elapsedPlaybackTime];
	double ret = current - revTime;
	revTime *= 2.0f;
	ffTime = 5.0f;
	
	if(ret < 0.0f)
		ret = 0.0f;
	[self setNewTimer];

	return ret;
}

@end
