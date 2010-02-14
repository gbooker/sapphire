/*
 * CMPISODVDPlayer.m
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 12 2010
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

#import "CMPISODVDPlayer.h"
#import "CMPDVDImageAction.h"
#import "CMPBaseMediaAsset.h"
#import "CMPDVDPlayerController.h"

@implementation CMPISODVDPlayer

+ (NSSet *)knownControllers
{
	return [NSSet setWithObject:[CMPDVDPlayerController class]];
}

/*- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	return self;
}*/

- (void) dealloc
{
	[imageMount release];
	[super dealloc];
}

- (void)initiatePlaybackWithResume:(BOOL *)resume;
{
	//mount iso here
	NSURL *url = [NSURL URLWithString:[imageAsset mediaURL]];
	NSString *path = [url path];
	//if ([CMPDVDImageAction isAvailable] != YES)
//	{
//		NSLog(@"dvd iso mounting unavailable");
//		return;
//	}
	imageMount = [[CMPDVDImageAction alloc] initWithPath:path];
	NSLog(@"imagePath: %@", path);
	if (![imageMount openWithError:nil] == YES)
	{
		NSLog(@"fail");
		return;
	}
	
	NSLog(@"mountedPath = %@", [imageMount mountedPath]);
	NSString *mountedPath = [imageMount mountedPath];
	
	CMPBaseMediaAsset *realAsset = [[CMPBaseMediaAsset alloc] initWithMediaURL:[NSURL fileURLWithPath:mountedPath]];
	BOOL success = [super setMedia:realAsset error:nil];
	[realAsset release];
	if(!success)
	{
		NSLog(@"open media failed!");
		return;
	}
	[super initiatePlaybackWithResume:resume];
}

- (BOOL)setMedia:(BRBaseMediaAsset *)anAsset error:(NSError * *)error
{
	[imageAsset release];
	imageAsset = [anAsset retain];
	
	return YES;
}

- (BRBaseMediaAsset *)asset
{
	return imageAsset;
}

- (void)stopPlayback
{
	[super stopPlayback];
	[imageMount closeWithError:nil];
}

- (NSArray *)isoExtensions
{
	NSArray *isoExt = [NSArray arrayWithObjects:@"iso", @"img", @"dmg", @"toast", nil];
	return isoExt;
}

- (BOOL)canPlay:(NSString *)path withError:(NSError **)error
{
	if([super canPlay:path withError:error])
	
	return [CMPDVDImageAction isAvailable];
}

/* For the moment, the super's canPlay doesn't actually check validity of the VIDEO_TS since the ATV likes to return false on valid directories.
- (BOOL)canPlay:(NSString *)path withError:(NSError **)error
{
	NSLog(@"Testing can play");
	BOOL usable = [frameworkLoad openWithError:error];
	if(!usable)
		return NO;
	
	NSLog(@"Usable from %@ says %d", frameworkLoad, usable);
	
	usable = [self initializeFrameworkWithError:error];
	if(!usable)
		return NO;
	
	NSString *ext = [[path pathExtension] lowercaseString];
	if ([[self isoExtensions] containsObject:ext])
	{
		/*
		 
		 right now this is all we check, to add the iso mount as part of the check i feel this method would run way too long, we are hoping they aren't selecting an ISO that isn't a DVD.
		 
		 
		 
		 *
		
		NSLog(@"returning yes for canPlay in CMPISODVDPlayer");
		return YES;
	}
	
	return NO;
	
	/*
	const char *cPath = [[path stringByAppendingPathComponent:@"VIDEO_TS"] fileSystemRepresentation];
	FSRef fsRef;
	OSStatus resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	
	NSLog(@"Result for make ref of %s is %d", cPath, resultz);
	
	Boolean isValid = false;
	if(resultz == noErr)
		resultz = DVDIsValidMediaRef(&fsRef, &isValid);
	
	NSLog(@"Is valid is %d:%d", isValid, resultz);
	isValid = 1;
	
	if(!isValid && error)
		*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  BRLocalizedString(@"Media isn't valid DVD", @"Failure to load media error message"), NSLocalizedDescriptionKey,
																		  nil]];	
	return isValid;
	*
	
}*/

@end
