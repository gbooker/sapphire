//
//  SapphireMedia.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRSimpleMediaAsset.h>


@interface SapphireMedia : BRSimpleMediaAsset {
	unsigned int		resumeTime;
}

- (void)setResumeTime:(unsigned int)time;
- (unsigned int)bookmarkTimeInSeconds;

@end
