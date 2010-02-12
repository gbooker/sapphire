/*
 * CMPLeopardDVDPlayer.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 6 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */

#import "CMPLeopardDVDPlayer.h"
#import "CMPLeopardDVDPlayerController.h"
#import "CMPATVVersion.h"
#import <DVDPlayback/DVDPlayback.h>

@implementation CMPLeopardDVDPlayer

+ (NSSet *)knownControllers
{
	return [NSSet setWithObject:[CMPLeopardDVDPlayerController class]];
}

- (double)elapsedPlaybackTime
{
	return 0.0f;
}

- (double)trackDuration
{
	return 0.0f;
}

- (BOOL)canPlay:(NSString *)path withError:(NSError **)error
{
	if(![CMPATVVersion usingLeopard])
		return NO;
	
	OSStatus resultz = DVDInitialize();
	if(resultz != noErr)
	{
		if(error)
			*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			  BRLocalizedString(@"Could not initialize DVD Framwork", @"Failure to initialize error message"), NSLocalizedDescriptionKey,
																			  nil]];
		return NO;
	}
	
	const char *cPath = [[path stringByAppendingPathComponent:@"VIDEO_TS"] fileSystemRepresentation];
	FSRef fsRef;
	resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	
	Boolean isValid = false;
	if(resultz == noErr)
		resultz = DVDIsValidMediaRef(&fsRef, &isValid);
	
	if(!isValid && error)
		*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  BRLocalizedString(@"Media isn't valid DVD", @"Failure to load media error message"), NSLocalizedDescriptionKey,
																		  nil]];	
	return isValid;	
}
- (BOOL)setMedia:(BRBaseMediaAsset *)anAsset error:(NSError **)error
{
	[asset release];
	asset = [anAsset retain];
	
	return YES;
}

- (BRBaseMediaAsset *)asset
{
	return asset;
}

@end
