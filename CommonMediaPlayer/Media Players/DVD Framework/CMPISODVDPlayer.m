/*
 * CMPDVDPlayer.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 2 2010
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

#import "CMPDVDPlayer.h"
#import "CMPISODVDPlayer.h"
#import <DVDPlayback/DVDPlayback.h>
#import "CMPDVDFrameworkLoadAction.h"
#import "CMPDVDPlayerController.h"
#import <AudioUnit/AudioUnit.h>
#import "CMPDVDImageAction.h"

enum{
	kDVDAudioModeUninitialized 		= 0,
	kDVDAudioModeProLogic 			= 1 << 0,
	kDVDAudioModeSPDIF				= 1 << 1
};
typedef SInt32	DVDAudioMode;

extern	OSStatus	DVDGetAudioOutputModeCapabilities(DVDAudioMode *outModes)									AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDSetAudioOutputMode(DVDAudioMode inMode)													AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDGetAudioOutputMode(DVDAudioMode *outMode)												AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDGetSPDIFDataOutDeviceCount(UInt32 *outCount)												AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDGetSPDIFDataOutDeviceCFName(UInt32 inIndex, CFStringRef *outName)						AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDSetSPDIFDataOutDevice(UInt32 inIndex)													AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;
extern	OSStatus	DVDGetSPDIFDataOutDevice(UInt32 *outIndex)													AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER;

@interface CMPDVDPlayer()
- (void)updateVideoBounds;
- (BOOL)initializeFrameworkWithError:(NSError **)error;
- (void)playbackStopped;
- (void)titleChanged;
- (void)titleTimeChanged;
@end

static UInt32						eventCallbackID = 0;

@implementation CMPISODVDPlayer

+ (NSSet *)knownControllers
{
	return [NSSet setWithObject:[CMPDVDPlayerController class]];
}

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	frameworkLoad = [[CMPDVDFrameworkLoadAction alloc] initWithController:nil andSettings:nil];
	
	return self;
}

- (void) dealloc
{
	[asset release];
	[frameworkLoad release];
	[super dealloc];
}

- (double)elapsedPlaybackTime
{
	if(titleCount != 1)
		return 0.0;
	
	return currentElapsedTime;
}

- (double)trackDuration
{
	if(titleCount != 1)
		return 0.0;
	
	return titleDuration;
}

static BOOL pauseOnPlay = NO;
- (void)initiatePlaybackWithResume:(BOOL *)resume;
{
	//mount iso here

	NSURL *url = [NSURL URLWithString:[asset mediaURL]];
	NSString *path = [url path];
	//NSLog(@"imagePath: %@", path);
	imageMount = [[CMPDVDImageAction alloc] initWithPlayer:self andPath:path];
	if (![imageMount openWithError:nil] == YES)
	{
		NSLog(@"fail");
		return;
	}
	
	//NSLog(@"mountedPath = %@", [self mountedPath]);
	if (![self openMediaWithError:nil])
	{
		NSLog(@"open media failed!");
		return;
	}
	DVDGetNumTitles(&titleCount);
	BOOL doingResume = titleCount == 1 && resumeTime != 0;
	DVDMute(true);
	OSStatus playError = DVDPlay();
	if(doingResume)
	{
		pauseOnPlay = YES;
		DVDSetTime(kDVDTimeCodeElapsedSeconds, resumeTime, 0);
		DVDPause();
	}
	DVDMute(false);
	if(resume)
		*resume = doingResume;
	
	if(playError != noErr)
		return;
	
	[self updateVideoBounds];
	
	Boolean hasMenu = false;
	OSStatus menuCheck = DVDHasMenu(kDVDMenuRoot, &hasMenu);
	
	if(menuCheck == noErr && hasMenu && !doingResume)
		DVDGoToMenu(kDVDMenuRoot);
}

- (BOOL)openMediaWithError:(NSError * *)error
{
	NSString *path = [[self mountedPath] stringByAppendingPathComponent:@"VIDEO_TS"];
	NSLog(@"Going to play %@", path);
	const char *cPath = [path fileSystemRepresentation];
	
	BOOL ret = [frameworkLoad openWithError:error];
	NSLog(@"Framework usable is %d", ret);
	if(!ret)
		return NO;
	ret = [self initializeFrameworkWithError:error];
	NSLog(@"Initialize is %d", ret);
	if(!ret)
		return NO;
	
	FSRef fsRef;
	OSStatus resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	NSLog(@"make path is %d", resultz);
	OSStatus openError = resultz;
	if(resultz == noErr)
		openError = DVDOpenMediaFile(&fsRef);
	
	NSLog(@"open error is %d", openError);
	return openError == noErr;
}

- (BOOL)setMedia:(BRBaseMediaAsset *)anAsset error:(NSError * *)error
{
	[asset release];
	asset = [anAsset retain];
	
	return YES;
	/*
	NSURL *url = [NSURL URLWithString:[asset mediaURL]];
	NSString *path = [[url path] stringByAppendingPathComponent:@"VIDEO_TS"];
	NSLog(@"Going to play %@", path);
	const char *cPath = [path fileSystemRepresentation];
	
	BOOL ret = [frameworkLoad openWithError:error];
	NSLog(@"Framework usable is %d", ret);
	if(!ret)
		return NO;
	ret = [self initializeFrameworkWithError:error];
	NSLog(@"Initialize is %d", ret);
	if(!ret)
		return NO;
	
	FSRef fsRef;
	OSStatus resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	NSLog(@"make path is %d", resultz);
	OSStatus openError = resultz;
	if(resultz == noErr)
		openError = DVDOpenMediaFile(&fsRef);
	
	NSLog(@"open error is %d", openError);
	return openError == noErr;

	 */
}

- (BRBaseMediaAsset *)asset
{
	return asset;
}

- (void)stopPlayback
{
	NSLog(@"Stopping");
	DVDUnregisterEventCallBack(eventCallbackID);
	eventCallbackID = 0;
	DVDStop();
	DVDCloseMediaFile();
	DVDCloseMediaVolume();
	DVDSetVideoDisplay(kCGNullDirectDisplay);
	DVDDispose();
	[imageMount closeWithError:nil];
}

- (NSArray *)isoExtensions
{
	NSArray *isoExt = [NSArray arrayWithObjects:@"iso", @"img", @"dmg", @"toast", nil];
	return isoExt;
}


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
		 
		 
		 
		 */
		
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
	*/
	
}

- (NSString *)mountedPath {
    return [[mountedPath retain] autorelease];
}

- (void)setMountedPath:(NSString *)value {
    if (mountedPath != value) {
        [mountedPath release];
        mountedPath = [value copy];
    }
}




@end
