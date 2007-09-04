//
//  SapphireMedia.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@interface SapphireMedia : BRSimpleMediaAsset {
	unsigned int		resumeTime;
}

- (void)setResumeTime:(unsigned int)time;
- (unsigned int)bookmarkTimeInSeconds;

@end
