/*
 * SapphireMedia.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SapphireMedia.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SapphireMedia

- (id)initWithMediaURL:(NSURL *)url
{
	//This is here to fix 2.2
	self = [super initWithMediaProvider:nil];
	NSString *urlString = [url absoluteString];
	NSString *filename = [url path];
	[self setObject:[filename lastPathComponent] forKey:@"id"];
	[self setObject:[BRMediaType movie] forKey:@"mediaType"];
	[self setObject:urlString forKey:@"mediaURL"];
	
	return self;
}

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
