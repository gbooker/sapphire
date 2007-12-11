//
//  NSFileManager-Extensions.m
//  Sapphire
//
//  Created by Patrick Merrill on 12/09/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "NSFileManager-Extensions.h"

@implementation NSFileManager (CollectionArtPaths)
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
@end