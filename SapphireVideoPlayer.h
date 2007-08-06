//
//  SapphireVideoPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireFileMetaData;

typedef enum {
	SKIP_STATE_NONE,
	SKIP_STATE_FORWARD_INCREASING,
	SKIP_STATE_BACKWARD_INCREASING,
	SKIP_STATE_DECREASING,
} SkipState;

@interface SapphireVideoPlayer : BRQTKitVideoPlayer {
	double					skipTime;
	SkipState				state;
	BOOL					enabled;
	NSTimer					*resetTimer;
	NSTimeInterval			duration;
}

@end
