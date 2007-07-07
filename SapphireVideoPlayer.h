//
//  SapphireVideoPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireFileMetaData;

@interface SapphireVideoPlayer : BRQTKitVideoPlayer {
	double					ffTime;
	double					revTime;
	BOOL					enabled;
	NSTimer					*resetTimer;
	SapphireFileMetaData	*meta;
}

/*
 * Set the File information
 * @param newMeta the meta data
 */
- (void)setMetaData:(SapphireFileMetaData *)newMeta;

@end
