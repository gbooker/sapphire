/*
 * NSFileManager-Extensions.m
 * Sapphire
 *
 * Created by Patrick Merrill on Dec. 09, 2007.
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

#import "NSFileManager-Extensions.h"
#import "SapphireMetaDataSupport.h"

@implementation NSFileManager (SapphireExtensions)
- (BOOL)constructPath:(NSString *)proposedPath
{
	BOOL isDir ;
	if(!([self fileExistsAtPath:proposedPath isDirectory:&isDir]&& isDir))
		if(![self createDirectoryAtPath:proposedPath attributes:nil])
			if([self constructPath:[proposedPath stringByDeletingLastPathComponent]])
				return [self createDirectoryAtPath:proposedPath attributes:nil];
			else
				return NO;
	return YES;	
}

// Static set of file extensions to filter
static NSSet *videoExtensions = nil;
static NSSet *audioExtensions = nil;
static NSSet *allExtensions = nil;

+ (void)load
{
	videoExtensions = [[NSSet alloc] initWithObjects:
					   @"avi", @"divx", @"xvid",
					   @"mov",
					   @"mpg", @"mpeg", @"m2v", @"ts",
					   @"wmv", @"asx", @"asf",
					   @"mkv",
					   @"flv",
					   @"mp4", @"m4v",
					   @"3gp",
					   @"pls",
					   @"avc",
					   @"ogm",
					   @"dv",
					   @"fli",
					   nil];
	audioExtensions = [[NSSet alloc] initWithObjects:
					   @"m4b", @"m4a",
					   @"mp3", @"mp2",
					   @"wma",
					   @"wav",
					   @"aif", @"aiff",
					   @"flac",
					   @"alac",
					   @"m3u",
					   @"ac3",
					   nil];
	NSMutableSet *mutSet = [videoExtensions mutableCopy];
	[mutSet unionSet:audioExtensions];
	allExtensions = [[NSSet alloc] initWithSet:mutSet];
	[mutSet release];
}

+ (NSSet *)videoExtensions
{
	return videoExtensions;
}

+ (NSSet *)audioExtensions
{
	return audioExtensions;
}

- (BOOL)hasVIDEO_TS:(NSString *)path
{
	BOOL isDir = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[path stringByAppendingPathComponent:@"VIDEO_TS"] isDirectory:&isDir] && isDir)
		return YES;
	return NO;
}

- (BOOL)isDirectory:(NSString *)path
{
	BOOL isDir = NO;
	BOOL exists = [self fileExistsAtPath:path isDirectory:&isDir];
	BOOL ret = exists && isDir;
	if(ret)
	{
		if([self hasVIDEO_TS:path])
			return NO;
	}
	return ret;
}

- (BOOL)acceptFilePath:(NSString *)path
{
	if(path == nil)
		return NO;
	NSString *name = [path lastPathComponent];
	
	/*Skip hidden files*/
	if([name hasPrefix:@"."])
		return NO;
	
	/*Skip the Cover Art directory*/
	if([name isEqualToString:@"Cover Art"])
		return NO;
	
	BOOL isDir;
	return ([allExtensions containsObject:[path pathExtension]] || ([self fileExistsAtPath:path isDirectory:&isDir] && isDir));
}

+ (NSString *)previewArtPathForTV:(NSString *)show season:(unsigned int)seasonNum
{
	return [NSString stringWithFormat:@"%@/@TV/%@/%@",	[SapphireMetaDataSupport collectionArtPath],
														show,
														[NSString stringWithFormat:@"Season %d", seasonNum]];
}
@end
