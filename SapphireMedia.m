//
//  SapphireMedia.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMedia.h"
#import "SapphireFrontRowCompat.h"

@implementation SapphireMedia

- (void)dealloc
{
	[imagePath release];
	[super dealloc];
}

- (void)setResumeTime:(unsigned int)time
{
	resumeTime = time;
}

/* Overrides the bookmark time */
- (unsigned int)bookmarkTimeInSeconds
{
	/*Check for resume time and if none, return bookmark time*/
	if(time == 0)
		return [super bookmarkTimeInSeconds];
	/*return resume time*/
	return resumeTime;
}

- (void)setImagePath:(NSString *)path
{
	[imagePath release];
	imagePath = [path retain];
}

- (id)mediaType
{
	if([SapphireFrontRowCompat usingFrontRow])
		return [BRMediaType TVShow];
	else
		return [super mediaType];
}

- (BOOL)hasCoverArt
{
	return YES;
}

- (id)coverArt
{
	return [SapphireFrontRowCompat imageAtPath:imagePath];
}

@end
