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

/*!
 * @brief Set the resume time for the media
 *
 * @param time the time at which to resume
 */
- (void)setResumeTime:(unsigned int)time
{
	resumeTime = time;
}

/*!
 * @brief Overrides the bookmark time
 *
 * @return The resume time if exists, otherwise the bookmark time
 */
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
	return [BRMediaType TVShow];
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
