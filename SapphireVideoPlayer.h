//
//  SapphireVideoPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRQTKitVideoPlayer.h>

@class SapphireFileMetaData;

@interface SapphireVideoPlayer : BRQTKitVideoPlayer {
	double					ffTime;
	double					revTime;
	BOOL					enabled;
	NSTimer					*resetTimer;
	SapphireFileMetaData	*meta;
}

- (void)setMetaData:(SapphireFileMetaData *)newMeta;

@end
