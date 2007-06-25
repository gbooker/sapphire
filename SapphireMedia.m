//
//  SapphireMedia.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMedia.h"


@implementation SapphireMedia

- (void)setResumeTime:(unsigned int)time
{
	resumeTime = time;
}

- (unsigned int)bookmarkTimeInSeconds
{
	if(time == 0)
		return [super bookmarkTimeInSeconds];
	return resumeTime;
}

@end
