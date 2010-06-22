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

#import <DVDPlayback/DVDPlayback.h>
#import "CMPDVDPlayer.h"
#import "CMPDVDFrameworkLoadAction.h"
#import "CMPDVDPlayerController.h"
#import "CMPOverlayAction.h"
#import <AudioUnit/AudioUnit.h>

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

@implementation CMPDVDPlayer

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
	currentElapsedTime = -1;
	titleDuration = -1;
	
	return self;
}


- (void) dealloc
{
	[asset release];
	[frameworkLoad release];
	[stopTimer invalidate];
	[playhead release];
	[super dealloc];
}

- (double)elapsedPlaybackTime
{
	if(titleCount != 1)
		return -1;
	
	return currentElapsedTime;
}

- (double)trackDuration
{
	if(titleCount != 1)
		return -1;

	return titleDuration;
}

- (BOOL)canPlay:(NSString *)path withError:(NSError **)error
{
	//NSLog(@"Testing can play");
	BOOL usable = [frameworkLoad openWithError:error];
	if(!usable)
		return NO;
	
	//NSLog(@"Usable from %@ says %d", frameworkLoad, usable);
	
	usable = [self initializeFrameworkWithError:error];
	if(!usable)
		return NO;

/* The ATV seems to return false for valid VIDEO_TS directories.  Not sure why, so skipping this check
	const char *cPath = [[path stringByAppendingPathComponent:@"VIDEO_TS"] fileSystemRepresentation];
	FSRef fsRef;
	OSStatus resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	
	NSLog(@"Result for make ref of %s is %d", cPath, resultz);
	
	Boolean isValid = false;
	if(resultz == noErr)
		resultz = DVDIsValidMediaRef(&fsRef, &isValid);
	
	NSLog(@"Is valid is %d:%d", isValid, resultz);
	
	if(!isValid && error)
		*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  BRLocalizedString(@"Media isn't valid DVD", @"Failure to load media error message"), NSLocalizedDescriptionKey,
																		  nil]];
	return isValid;*/
	return YES;
}

+ (BOOL)isVolume:(NSString *)theVolume
{
	NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:theVolume traverseLink:YES];
	int fsType = [[attrs objectForKey:NSFileSystemFileNumber] intValue];
	//NSLog(@"Fstype: %i", fsType);
	//NSLog(@"attrs: %@", attrs);
	BOOL isVolume = NO;
	switch (fsType) {
			
		case 2: //is volume
			//NSLog(@"%@, is a volume!", [theVolume lastPathComponent]);
			isVolume = YES;
			break;
		default:
			//NSLog(@"not a volume: %i, %@", fsType,[theVolume lastPathComponent]);
			isVolume = NO;
			break;
	}
	return isVolume;
}

+ (BOOL)isImage:(NSString *)theVolume
{
	if (![self isVolume:theVolume])
	{
		NSLog(@"%@ is NOT a disc image", [theVolume lastPathComponent]);
		return NO;
	}
	
	
	NSTask *hdiTask = [[NSTask alloc] init];
	NSPipe *pipe = [[NSPipe alloc] init];
	NSFileHandle *handle = [pipe fileHandleForReading];
	[hdiTask setLaunchPath:@"/usr/bin/hdiutil"];
	[hdiTask setArguments:[NSArray arrayWithObjects:@"info", @"-plist", nil]];
	[hdiTask setStandardError:pipe];
	[hdiTask setStandardOutput:pipe];
	
	[hdiTask launch];
	[hdiTask waitUntilExit];
	id vDict = nil;
	NSString *error = nil;
	NSPropertyListFormat format;
	NSData *outData;
	while((outData = [handle readDataToEndOfFile]) && [outData length])
    {
		
		vDict = [NSPropertyListSerialization propertyListFromData:outData
												 mutabilityOption:NSPropertyListImmutable
														   format:&format
												 errorDescription:&error];	
	}
	
	[hdiTask release];
	hdiTask = nil;
	[pipe release];
	pipe = nil;
	
	if (error == nil)
	{
		NSArray *imageArray = [vDict objectForKey:@"images"];
		NSEnumerator *imageEnum = [imageArray objectEnumerator];
		id currentObject;
		while (currentObject = [imageEnum nextObject])
		{
			NSArray *plistArray = [currentObject objectForKey:@"system-entities"];
			id currentItem = [plistArray objectAtIndex:0];
			NSString *mountPath = [currentItem objectForKey:@"mount-point"];
			if ([[mountPath lastPathComponent] isEqualToString:[theVolume lastPathComponent]])
			{
				//NSLog(@"%@ is a disc image", [theVolume lastPathComponent]);
				return YES;
			}
			
		}
	}
	NSLog(@"%@ is NOT a disc image", [theVolume lastPathComponent]);
	return NO;
}

+ (OSErr)getFSRefAtPath:(NSString*)sourceItem ref:(FSRef*)sourceRef
{
    OSErr    err;
    BOOL    isSymLink;
    id manager=[NSFileManager defaultManager];
    NSDictionary *sourceAttribute = [manager fileAttributesAtPath:sourceItem
													 traverseLink:NO];
    isSymLink = ([sourceAttribute objectForKey:@"NSFileType"] ==
				 NSFileTypeSymbolicLink);
    if(isSymLink){
        const UInt8    *sourceParentPath;
        FSRef        sourceParentRef;
        HFSUniStr255    sourceFileName;
        
        sourceParentPath = (UInt8*)[[sourceItem
									 stringByDeletingLastPathComponent] fileSystemRepresentation];
        err = FSPathMakeRef(sourceParentPath, &sourceParentRef, NULL);
        if(err == noErr){
            [[sourceItem lastPathComponent]
			 getCharacters:sourceFileName.unicode];
            sourceFileName.length = [[sourceItem lastPathComponent] length];
            if (sourceFileName.length == 0){
                err = fnfErr;
            }
            else err = FSMakeFSRefUnicode(&sourceParentRef,
										  sourceFileName.length, sourceFileName.unicode, kTextEncodingFullName,
										  sourceRef);
        }
    }
    else{
        err = FSPathMakeRef((UInt8 *)[sourceItem fileSystemRepresentation],
							sourceRef, NULL);
    }
    
    return err;
}

- (BOOL)setMedia:(BRBaseMediaAsset *)anAsset error:(NSError * *)error
{
	[asset release];
	asset = [anAsset retain];
	
	NSURL *url = [NSURL URLWithString:[asset mediaURL]];
	NSString *path = [[url path] stringByAppendingPathComponent:@"VIDEO_TS"];
	//NSLog(@"Going to play %@", path);
	
	BOOL ret = [frameworkLoad openWithError:error];
	//NSLog(@"Framework usable is %d", ret);
	if(!ret)
		return NO;
	ret = [self initializeFrameworkWithError:error];
	//NSLog(@"Initialize is %d", ret);
	if(!ret)
		return NO;

	FSRef fsRef;
	OSStatus resultz=[CMPDVDPlayer getFSRefAtPath:path ref:&fsRef];
	//OSStatus resultz = FSPathMakeRef((UInt8*)cPath, &fsRef, NULL);
	//NSLog(@"make path is %d", resultz);
	OSStatus openError = resultz;
	if(resultz == noErr)
		openError = DVDOpenMediaFile(&fsRef);
	
	//NSLog(@"open error is %d", openError);
	return openError == noErr;
}

- (BRBaseMediaAsset *)asset
{
	return asset;
}

- (void)setController:(CMPDVDPlayerController *)aController
{
	controller = aController;
}

- (BOOL)playing
{
	Boolean playing = false;
	DVDIsPlaying(&playing);
	return playing;
}

- (BOOL)hasMenu
{
	Boolean hasMenu = false;
	if([self playing])
		DVDHasMenu(kDVDMenuRoot,&hasMenu);
	return hasMenu;
}

- (BOOL)inMenu
{
	Boolean onMenu = false;
	
	if([self hasMenu])
	{
		DVDMenu whichMenu;
		DVDIsOnMenu(&onMenu, &whichMenu);
	}
	
	return onMenu;
}

- (CMPDVDState)state
{
	DVDState currentState = kDVDStateUnknown;
	DVDGetState(&currentState);
	
	switch (currentState) {
		case kDVDStateUnknown:
			return CMPDVDStateUnknown;
		case kDVDStatePlaying:
			return CMPDVDStatePlaying;
		case kDVDStatePlayingStill:
			return CMPDVDStatePlayingStill;
		case kDVDStatePaused:
			return CMPDVDStatePaused;
		case kDVDStateStopped:
			return CMPDVDStateStopped;
		case kDVDStateScanning:
		{
			DVDScanRate outRate;
			DVDScanDirection outDirection;
			DVDGetScanRate(&outRate, &outDirection);
			if(outDirection == kDVDScanDirectionForward)
				return CMPDVDStateScanningForward;
			return CMPDVDStateScanningBackward;
			
		}
		case kDVDStateIdle:
			return CMPDVDStateIdle;
		case kDVDStatePlayingSlow:
		{
			DVDScanRate outRate;
			DVDScanDirection outDirection;
			DVDGetScanRate(&outRate, &outDirection);
			if(outDirection == kDVDScanDirectionForward)
				return CMPDVDStatePlayingSlowForward;
			return CMPDVDStatePlayingSlowBackward;
			
		}
		default:
			break;
	}
	return kDVDStateUnknown;
}

- (void)doUserNavigation:(CMPDVDPlayerNavigation)navigation
{
	DVDUserNavigation nav = 0;
	switch (navigation) {
		case CMPDVDPlayerNavigationUp:
			nav = kDVDUserNavigationMoveUp;
			break;
		case CMPDVDPlayerNavigationDown:
			nav = kDVDUserNavigationMoveDown;
			break;
		case CMPDVDPlayerNavigationLeft:
			nav = kDVDUserNavigationMoveLeft;
			break;
		case CMPDVDPlayerNavigationRight:
			nav = kDVDUserNavigationMoveRight;
			break;
		case CMPDVDPlayerNavigationEnter:
			nav = kDVDUserNavigationEnter;
			break;
		default:
			break;
	}
	DVDDoUserNavigation(nav);
}

- (void)setResumeTime:(UInt32)aResumeTime
{
	resumeTime = aResumeTime;
}

- (void)goToMenu
{
	//NSLog(@"Going to Menu");
	if(DVDGoToMenu(kDVDMenuRoot) != noErr)
	{
		//Go to beginning if there's no root menu
		DVDSetTime(kDVDTimeCodeElapsedSeconds, 0, 0);
		DVDPlay();
	}
}

- (void)play
{
	//NSLog(@"Playing");
	DVDPlay();
}

- (void)pause
{
	//NSLog(@"Pausing");
	DVDPause();
}

static BOOL ignoreStopUntilPlay = NO;

- (void)restart
{
	ignoreStopUntilPlay = YES;
	DVDStop();
	//Second one clears playback position
	DVDStop();
	DVDPlay();
}

DVDScanRate incrementedNewRate(DVDScanRate currentRate)
{
	switch (currentRate) {
		case kDVDScanRateOneEigth:
			return kDVDScanRateOneFourth;
		case kDVDScanRateOneFourth:
			return kDVDScanRateOneHalf;
		case kDVDScanRateOneHalf:
			return kDVDScanRate1x;
		case kDVDScanRate1x:
			return kDVDScanRate2x;
		case kDVDScanRate2x:
			return kDVDScanRate4x;
		case kDVDScanRate4x:
			return kDVDScanRate8x;
		case kDVDScanRate8x:
			return kDVDScanRate16x;
		case kDVDScanRate16x:
		case kDVDScanRate32x:
			return kDVDScanRate32x;
	}
	return currentRate;
}

DVDScanRate decrementedNewRate(DVDScanRate currentRate)
{
	switch (currentRate) {
		case kDVDScanRateOneEigth:
		case kDVDScanRateOneFourth:
			return kDVDScanRateOneEigth;
		case kDVDScanRateOneHalf:
			return kDVDScanRateOneFourth;
		case kDVDScanRate1x:
			return 0;  //Reverse direction
		case kDVDScanRate2x:
			return kDVDScanRateOneHalf;
		case kDVDScanRate4x:
			return kDVDScanRate2x;
		case kDVDScanRate8x:
			return kDVDScanRate4x;
		case kDVDScanRate16x:
			return kDVDScanRate8x;
		case kDVDScanRate32x:
			return kDVDScanRate16x;
	}
	return currentRate;
}

- (void)incrementScanRate
{
	//NSLog(@"Incrementing scan rate");
	//Really increment in terms of forward direction
	DVDScanRate outRate;
	DVDScanDirection outDirection;
	
	DVDGetScanRate(&outRate, &outDirection);
	//NSLog(@"Scan rate in currently %d:%d", outDirection, outRate);
	DVDScanRate newRate;
	if(outDirection == kDVDScanDirectionForward)
		newRate = incrementedNewRate(outRate);
	else
		newRate = decrementedNewRate(outRate);
	
	if(newRate == 0)
	{
		outDirection = (outDirection == kDVDScanDirectionForward) ? kDVDScanDirectionBackward : kDVDScanDirectionForward;
		newRate = outRate;
	}
	//NSLog(@"Scan rate in now %d:%d", outDirection, newRate);
	DVDScan(newRate, outDirection);
}

- (void)decrementScanRate
{
	//NSLog(@"Decrementing scan rate");
	//Really decrement in terms of forward direction
	DVDScanRate outRate;
	DVDScanDirection outDirection;
	
	DVDGetScanRate(&outRate, &outDirection);
	//NSLog(@"Scan rate in currently %d:%d", outDirection, outRate);
	DVDScanRate newRate;
	if(outDirection == kDVDScanDirectionForward)
		newRate = decrementedNewRate(outRate);
	else
		newRate = incrementedNewRate(outRate);
	
	if(newRate == 0)
	{
		outDirection = (outDirection == kDVDScanDirectionForward) ? kDVDScanDirectionBackward : kDVDScanDirectionForward;
		newRate = outRate;
	}
	//NSLog(@"Scan rate in now %d:%d", outDirection, newRate);
	DVDScan(newRate, outDirection);
}

- (int)playSpeed
{
	DVDScanRate outRate;
	DVDScanDirection outDirection;
	
	DVDGetScanRate(&outRate, &outDirection);
	return abs(outRate);
}

- (int)chapters
{
	UInt16 title, chapters;
	DVDGetTitle(&title);
	DVDGetNumChapters(title, &chapters);
	return chapters;
}

- (int)currentChapter
{
	UInt16 chapter;
	DVDGetChapter(&chapter);
	return chapter;
}

- (NSString *)currentAudioFormat
{
	UInt16 streamNum;
	DVDGetAudioStream(&streamNum);
	DVDAudioFormat format;
	UInt32 bitsPerSample, samplesPerSecond, channels;
	DVDGetAudioStreamFormat(&format, &bitsPerSample, &samplesPerSecond, &channels);
	DVDLanguageCode code;
	DVDAudioExtensionCode extension;
	DVDGetAudioLanguageCode(&code, &extension);
	
	NSString *formatStr;
	switch (format) {
		case kDVDAudioAC3Format:
			formatStr = @"AC3";
			break;
		case kDVDAudioMPEG1Format:
			formatStr = @"MPEG1";
			break;
		case kDVDAudioMPEG2Format:
			formatStr = @"MPEG2";
			break;
		case kDVDAudioPCMFormat:
			formatStr = @"PCM";
			break;
		case kDVDAudioDTSFormat:
			formatStr = @"DTS";
			break;
		case kDVDAudioSDDSFormat:
			formatStr = @"SDDS";
			break;
		case kDVDAudioMLPFormat:
			formatStr = @"MLP";
			break;
		case kDVDAudioUnknownFormat:
		default:
			formatStr = @"Unknown";
			break;
	}
	
	NSString *sampleRate;
	if(samplesPerSecond % 1000 == 0)
		sampleRate = [NSString stringWithFormat:@"%dkHz", samplesPerSecond / 1000];
	else
		sampleRate = [NSString stringWithFormat:@"%3.1fkHz", ((float)samplesPerSecond)/1000.0f];
	return [NSString stringWithFormat:@"%d-%c%c: %d chan %@ %@ %dbit", streamNum, (code>>24)&0xff, (code>>16)&0xff, channels, sampleRate, formatStr, bitsPerSample];
}

- (NSString *)currentSubFormat
{
	UInt16 numStreams;
	DVDGetNumSubPictureStreams(&numStreams);
	if(!numStreams)
		return @"None";
	Boolean displaying;
	DVDIsDisplayingSubPicture(&displaying);
	if(!displaying)
		return @"Off";
	UInt16 streamNum;
	DVDGetSubPictureStream(&streamNum);
	DVDLanguageCode code;
	DVDSubpictureExtensionCode extension;
	DVDGetSubPictureLanguageCode(&code, &extension);
	
	return [NSString stringWithFormat:@"%d-%c%c", streamNum, (code>>24)&0xff, (code>>16)&0xff];
}

- (int)titleElapsedTime
{
	UInt32 elapsed;
	UInt16 frames;
	DVDGetTime(kDVDTimeCodeElapsedSeconds, &elapsed, &frames);
	return elapsed;
}

- (int)titleDurationTime
{
	UInt32 duration;
	UInt16 frames;
	DVDGetTime(kDVDTimeCodeTitleDurationSeconds, &duration, &frames);
	return duration;
}

- (void)nextChapter
{
	//NSLog(@"Going to next chapter");
	DVDNextChapter();
}

- (void)previousChapter
{
	//NSLog(@"Going to previous chapter");
	UInt32 elapsed;
	UInt16 frames;
	DVDGetTime(kDVDTimeCodeChapterElapsedSeconds, &elapsed, &frames);
	if(elapsed < 2)
		DVDPreviousChapter();
	else
	{
		UInt16 chapter;
		DVDGetChapter(&chapter);
		DVDSetChapter(chapter);
	}
}

- (void)nextFrame
{
	DVDStepFrame(kDVDScanDirectionForward);
}

- (void)previousFrame
{
	DVDStepFrame(kDVDScanDirectionBackward);
}

- (void)nextAudioStream
{
	UInt16 numStreams;
	DVDGetNumAudioStreams(&numStreams);
	if(!numStreams)
		return;
	
	UInt16 streamNum;
	DVDGetAudioStream(&streamNum);
	if(streamNum == numStreams)
		DVDSetAudioStream(1);
	else
		DVDSetAudioStream(streamNum + 1);
}

- (void)nextSubStream
{
	UInt16 numStreams;
	DVDGetNumSubPictureStreams(&numStreams);
	if(!numStreams)
		return;
	
	Boolean displaying;
	DVDIsDisplayingSubPicture(&displaying);
	if(!displaying)
	{
		DVDSetSubPictureStream(0);
		DVDDisplaySubPicture(1);
		return;
	}
	UInt16 streamNum;
	DVDGetSubPictureStream(&streamNum);
	if(streamNum == numStreams)
		DVDDisplaySubPicture(0);
	else
		DVDSetSubPictureStream(streamNum+1);
}

- (void)setZoomLevel:(CMPDVDZoomLevel)level
{
	zoomLevel = level;
	[self updateVideoBounds];
}

- (CMPDVDZoomLevel)zoomLevel
{
	return zoomLevel;
}

- (void)setPlayhead:(CMPPlayerPlayHead *)aPlayhead
{
	[playhead release];
	playhead = [aPlayhead retain];
	[playhead updateDisplayWithElapsed:currentElapsedTime duration:titleDuration];
}

static BOOL pauseOnPlay = NO;
- (void)initiatePlaybackWithResume:(BOOL *)resume;
{
	DVDAudioMode audioMode = 0;
	//See if we can go SPDIF
	OSStatus SPDIFresult = DVDGetAudioOutputModeCapabilities(&audioMode);
	//NSLog(@"SPDIF get is %d with mode %d", SPDIFresult, audioMode);
	if(audioMode & kDVDAudioModeSPDIF)
	{
		//Engage the SPDIF interface
		SPDIFresult = DVDSetAudioOutputMode(kDVDAudioModeSPDIF);
		//NSLog(@"Set to SPDIF with result %d", SPDIFresult);
		SPDIFresult = DVDSetSPDIFDataOutDevice(0);
		//NSLog(@"Set SPDIF device with result %d", SPDIFresult);
	}	
	
	DVDGetNumTitles(&titleCount);
	BOOL doingResume = titleCount == 1 && resumeTime != 0;
	OSStatus playError = DVDPlay();
	DVDMute(true);
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

- (void)stopPlayback
{
	//NSLog(@"Stopping");
	DVDUnregisterEventCallBack(eventCallbackID);
	eventCallbackID = 0;
	[stopTimer invalidate];
	stopTimer = nil;
	DVDStop();
	DVDCloseMediaFile();
	DVDCloseMediaVolume();
	//Seems to crash SL
	//DVDSetVideoDisplay(kCGNullDirectDisplay);
	DVDDispose();
}

- (BOOL)useStopTimer {
    return useStopTimer;
}

- (void)setUseStopTimer:(BOOL)value {
    if (useStopTimer != value) {
        useStopTimer = value;
    }
}



static void MyDVDEventHandler(DVDEventCode inEventCode, UInt32 inEventData1, UInt32 inEventData2, UInt32 inRefCon)
{
	if(!eventCallbackID)
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CMPDVDPlayer *player = (CMPDVDPlayer *)inRefCon;
	
	switch (inEventCode) {
		case kDVDEventDomain:
			//Domain has changed
			switch(inEventData1) {
				case kDVDSTOPDomain:
					if(!ignoreStopUntilPlay)
						[player performSelectorOnMainThread:@selector(playbackStopped) withObject:nil waitUntilDone:NO];
					break;
				case kDVDFPDomain:
					//First Play domain
					ignoreStopUntilPlay = NO;
					break;
//				case kDVDVMGMDomain:
//					//Video Manager
//				case kDVDVTSMDomain:
//					//Video title set
//				case kDVDTTDomain:
//					//Title
//				case kDVDAMGMDomain:
//					//Audio manager menu (DVD-Audio only)
//				case kDVDTTGRDomain:
//					//Title group (DVD-Audio only)
//					break;
			}
			break;
		case kDVDEventVideoStandard:
			//Video format has changed (NTSC/PAL)
		case kDVDEventDisplayMode:
			//Display mode has changed (aspect)
			[player performSelectorOnMainThread:@selector(updateVideoBounds) withObject:nil waitUntilDone:NO];
			break;
			
		case kDVDEventTitle:
			//Title has changed
			[player titleChanged];
			break;
		case kDVDEventTitleTime:
			//Time in title (elapsed/duration)
			[player titleTimeChanged];
			break;
//		case kDVDEventPTT:
//			//Chapter has changed
//		case kDVDEventValidUOP:
//			//Allowed User opperations has changed (is it up to us to enforce this?)
//		case kDVDEventAngle:
//			//Angle has changed
//		case kDVDEventAudioStream:
//			//Audio stream has changed
//		case kDVDEventSubpictureStream:
//			//Subtitle has changed
//		case kDVDEventBitrate:
//			//Bitrate has changed
//		case kDVDEventStill:
//			//Still picture on or off
//		case kDVDEventPlayback:
//			//Playback state has changed
//		case kDVDEventStreams:
//			//Stream has changed
//		case kDVDEventScanSpeed:
//			//Scan rate has changed
//		case kDVDEventMenuCalled:
//			//Menu has changed
//		case kDVDEventParental:
//			//Parental level has changed
//		case kDVDEventPGC:
//			//Program has changed
//		case kDVDEventGPRM:
//			//GPRM has changed
//		case kDVDEventRegionMismatch:
//			//Region mismatch between disk and device
//		case kDVDEventSubpictureStreamNumbers:
//			//Number of subtitle streams has changed
//		case kDVDEventAudioStreamNumbers:
//			//Number of audio streams has changed
//		case kDVDEventAngleNumbers:
//			//Number of angles has changed
//		case kDVDEventError:
//			//Hardware error
//		case kDVDEventCCInfo:
//			//Closed Captioning has changed
//		case kDVDEventChapterTime:
//			//Chapter time has changed (elapsed/duration)
		default:
			break;
	}
	[pool drain];
}

- (void)playbackStopped
{
	if(!eventCallbackID)
		return;
	[controller playbackStopped];
}

- (void)stopTimerFire
{
	
	if([self useStopTimer])
	{
		stopTimer = nil;
		[controller playbackStopped];
	}
		
}

- (void)resetStopTimer
{
	if(!eventCallbackID)
		return;
	[stopTimer invalidate];
	if([self useStopTimer])
	{
		stopTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 target:self selector:@selector(stopTimerFire) userInfo:nil repeats:NO];
	}
	
}

- (void)titleChanged
{
	UInt16 frames;
	DVDGetTime(kDVDTimeCodeTitleDurationSeconds, &titleDuration, &frames);
	if(titleDuration != 0)
		currentElapsedTime = 0;
	else
		titleDuration = -1;
}

- (void)updatePlayhead
{
	[playhead updateDisplayWithElapsed:currentElapsedTime duration:titleDuration];
}

- (void)titleTimeChanged
{
	if ([self useStopTimer])
	{
		[self performSelectorOnMainThread:@selector(resetStopTimer) withObject:nil waitUntilDone:NO];
	}
	
	UInt16 frames;
	UInt32 time = 0;
	DVDGetTime(kDVDTimeCodeElapsedSeconds, &time, &frames);
	if(time != 0)
		currentElapsedTime = time;
	if(playhead != nil)
		[self performSelectorOnMainThread:@selector(updatePlayhead) withObject:nil waitUntilDone:NO];
}

- (NSSize)size
{
	DVDAspectRatio aspectRatio = kDVDAspectRatioUninitialized;
	DVDGetAspectRatio (&aspectRatio);
	float aspect = 4.0/3.0;
	
	switch (aspectRatio) {
		case kDVDAspectRatio4x3:
		case kDVDAspectRatio4x3PanAndScan:
		case kDVDAspectRatioUninitialized:
			aspect = 4.0/3.0;
			break;
		case kDVDAspectRatio16x9:
		case kDVDAspectRatioLetterBox:
			aspect = 16.0/9.0;
			break;
	}
	
	UInt16 width = 720, height = 480;
	DVDGetNativeVideoSize(&width, &height);
	
	NSSize nativeSize;
	nativeSize.height = height;
	nativeSize.width = nativeSize.height * aspect;
	
	return nativeSize;
}

- (void)updateVideoBounds
{	
	
	NSString *displayUIString = [BRDisplayManager currentDisplayModeUIString];
	//NSLog(@"displayUIString: %@", displayUIString);
	NSArray *displayCom = [displayUIString componentsSeparatedByString:@" "];
	NSString *shortString = [displayCom objectAtIndex:0];
	//NSLog(@"%@ %s", self, _cmd);
	//NSWindow *win = [self outputWindow];
	
	NSSize nativeSize = [self size];
	//NSRect frame = [win frame];
	CGDirectDisplayID display = [(BRDisplayManager *)[BRDisplayManager sharedInstance] display];
	
	NSSize currentSize;
	if([shortString isEqualToString:@"1080i"])
	{
		currentSize.width = 1280;
		currentSize.height = 1080;
	}
	else
	{
		currentSize.width = CGDisplayPixelsWide(display);
		currentSize.height = CGDisplayPixelsHigh(display);
	}
	
	NSRect rect;
	if(NSEqualSizes(currentSize, nativeSize))
	{
		rect.size = currentSize;
	}
	else if(currentSize.width/currentSize.height > nativeSize.width/nativeSize.height)
	{
		float resizeScale = currentSize.height/nativeSize.height;
		rect.size.width = nativeSize.width * resizeScale;
		rect.size.height = currentSize.height;
	}
	else
	{
		float resizeScale = currentSize.width/nativeSize.width;
		rect.size.height = nativeSize.height * resizeScale;
		rect.size.width = currentSize.width;
	}
	
	switch (zoomLevel) {
		case CMPDVDZoomLetterBoxInFullFrame:
			rect.size.width *= 4.0f/3.0f;
			rect.size.height *= 4.0f/3.0f;
			break;
		case CMPDVDZoom2x:
			rect.size.width *= 2.0f;
			rect.size.height *= 2.0f;
			break;
		default:
			break;
	}

	rect.origin.x = (currentSize.width - rect.size.width)/2;
	rect.origin.y = (currentSize.height - rect.size.height)/2;
	
	Rect qdRect;
	qdRect.left = rect.origin.x;
	qdRect.right = rect.origin.x + rect.size.width;
	qdRect.top = rect.origin.y;
	qdRect.bottom = rect.origin.y + rect.size.height;
	
	DVDSetVideoBounds(&qdRect);
}

- (BOOL)initializeFrameworkWithError:(NSError **)error
{
	OSStatus result = DVDInitialize();
	//NSLog(@"DVDInitialize: %d", result);
	DVDEventCode eventCodes[] = {
		kDVDEventDisplayMode, 
		kDVDEventError,
		/* registering for and handling this event makes the use of
		 DVDGetState unnecessary */
		kDVDEventPlayback, 
		kDVDEventPTT, 
		kDVDEventTitle,
		kDVDEventMenuCalled,
		kDVDEventTitleTime,
		kDVDEventVideoStandard,
		kDVDEventDomain,
	};
	
	result = DVDRegisterEventCallBack (
									   MyDVDEventHandler, 
									   eventCodes, 
									   sizeof(eventCodes)/sizeof(DVDEventCode), 
									   (UInt32)self, 
									   &eventCallbackID);
	//NSLog(@"DVD Register Callbacks: %d", result);
	switch(result)
	{
			
		case kDVDErrorPlaybackOpen:
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"The framework is already open (probably by another process).", @"Failure to load framework error message"), NSLocalizedDescriptionKey,
																				  nil]];			
			DVDDispose();
			return NO;
			
		case kDVDErrorInitializingLib:
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"There was an error initializing the playback framework", @"Failure to load framework error message"), NSLocalizedDescriptionKey,
																				  nil]];
			//DVDDispose();
			//DVDInitialize();
			return NO;
			//break;
			
		case kDVDErrorMissingDrive:
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"The DVD drive is not available. Un-patched DVDPlayback.framework likely", @"Failure to load framework error message"), NSLocalizedDescriptionKey,
																				  nil]];
//			BRAlertController *aController = [BRAlertController alertOfType:1 titled:BRLocalizedString(@"Un-patched DVDPlayback Detected", @"Message for DVDPlayback.framework not being patched") primaryText:BRLocalizedString(@"Attempting to patch...", @"Primary text in patching dialog") secondaryText:BRLocalizedString(@"Will reboot finder upon success", @"Secondary text for patching dialog")];
//			
//			[[self stack] pushController:aController];
//			NSFileManager *man = [NSFileManager defaultManager];
//			NSString *userPathToFramework = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework/Versions/A/DVDPlayback"];
//			if ([man fileExistsAtPath:userPathToFramework])
//			{
//				//if ([man isWritableFileAtPath:[userPathToFramework stringByDeletingLastPathComponent]])
//				if([self patchworkOrange:userPathToFramework] == FALSE)
//				{
//					//NSLog(@"po w/o perm failed, attempted w/ perm");
//					[self helperPatch];
//				}
//				
//			}
			
			
			//BRAlertController *aController = [BRAlertController alertOfType:1 titled:@"Un-patched framework" primaryText:@"You must patch the DVDPlayback framework for it to function on the AppleTV" secondaryText:@"Continuing with mplayer" withScene:[self scene]];
			
			//[[self stack] pushController:aController];
			return NO;
	}
	DVDSetTimeEventRate(100);
	return result == noErr;
}

@end
