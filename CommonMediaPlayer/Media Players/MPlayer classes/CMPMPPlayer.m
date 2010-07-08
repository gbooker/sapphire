/*
 * CMPMPPlayer.m
 * CommonMediaPlayer
 *
 * Created by Kevin Bradley on June. 5 2010
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

#import "CMPMPPlayer.h"
#import "CMPMPPlayerController.h"
#import <AudioUnit/AudioUnit.h>

#define MPPlay @"p"
#define MPPause @"p"

#define MPVolumeDown @"/"
#define MPVolumeUp @"*"
#define MPMute @"m"

#define MPNextPlaylistItem @">I"
#define MPPreviousPlaylistItem @"<"

#define MPSeekTenForward @"R"
#define MPSeekTenBackwards @"L"
#define MPSeekSixtyForward @"U"
#define MPSeekSixtyBackwards @"Z"
#define MPSeek600Forwards @"C"
#define MPSeek600Backwards @"X"

#define MPToggleAudio @"#"
#define MPIncrementAudioTiming @"+"
#define MPDelayAudio @"-"

#define MPToggleSub @"j"
#define MPMoveSubsUp @"t"
#define MPMoveSubsDown @"r"
#define MPIncrementSubsTiming @"x"
#define MPDelaySubs @"z"

#define MPToggleOSD @"o"


@implementation CMPMPPlayer

+ (NSSet *)knownControllers
{
	return [NSSet setWithObject:[CMPMPPlayerController class]];
}

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	

	
	return self;
}


- (void) dealloc
{
	[asset release];
	[stopTimer invalidate];
	[super dealloc];
}


- (BOOL)canPlay:(NSString *)path withError:(NSError **)error
{
	
	/*
	 
	 i guess we would test the extension here against a list, but seems like this will already be taken care of the register
	 with player/extension section.
	 
	 */

	return YES;
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
	
	NSString *properPath = [url path];

	
	[asset setObject:properPath forKey:@"mediaURL"];

	return YES;
}

- (BRBaseMediaAsset *)asset
{
	return asset;
}

- (void)setController:(CMPMPPlayerController *)aController
{
	controller = aController;
}

- (BOOL)playing
{
	if(mpTask && [mpTask isKindOfClass:[NSTask class]]) {
		if([mpTask isRunning])
			return YES;
		else
			return NO;
	}
	return NO;
}


- (void)playbackStopped
{
	[controller playbackStopped];
}

- (void)setResumeTime:(UInt32)aResumeTime
{
	resumeTime = aResumeTime;
}

- (void)sendCommand:(NSString *)theString
{
	
	//BRLog(@"%@ %s: %@", self, _cmd, theString);
	if(theString == nil)
		return;
	
	NSData *outData;
	outData = [theString dataUsingEncoding:NSASCIIStringEncoding
					  allowLossyConversion:YES];
	[[[mpTask standardInput] fileHandleForWriting] writeData:outData];

}

- (BOOL)usePassthrough {
    return usePassthrough;
}

- (void)setUsePassthrough:(BOOL)value {
    if (usePassthrough != value) {
        usePassthrough = value;
    }
}



- (void)play
{
	[self sendCommand:MPPlay];
}

- (void)pause
{
	
	[self sendCommand:MPPause];
}

- (void)nextAudioStream
{
	[self sendCommand:MPToggleAudio];
}

- (void)nextSubStream
{
	[self sendCommand:MPToggleSub];
}

- (void)volumeUp
{
	[self sendCommand:MPVolumeUp];
}

- (void)volumeDown
{
	[self sendCommand:MPVolumeDown];
}

- (void)seekTenForward
{
	[self sendCommand:MPSeekTenForward];
}

- (void)seekTenBack
{
	[self sendCommand:MPSeekTenBackwards];
}

- (void)seekSixtyForward
{
	[self sendCommand:MPSeekSixtyForward];
}

- (void)seekSixtyBack
{
	[self sendCommand:MPSeekTenBackwards];
}

- (void)seekSixHundredForward
{
	[self sendCommand:MPSeek600Forwards];
}

- (void)seekSixHundredBackwards
{
	[self sendCommand:MPSeek600Backwards];
}

- (void)nextPlaylistItem
{
	[self sendCommand:MPNextPlaylistItem];
}

- (void)previousePlaylistItem
{
	[self sendCommand:MPPreviousPlaylistItem];
}

- (int)currentKeymap {
    return currentKeymap;
}

- (void)setCurrentKeymap:(int)value {
    if (currentKeymap != value) {
        currentKeymap = value;
    }
}



- (void)initiatePlaybackWithResume:(BOOL *)resume;
{

	if([mpTask isRunning]) {
		
		[self stopPlayback];
		
	}
	
	//NSArray *mpArgs = [nitoTVAppliance arrayForKey:@"mpArgs"];
	
	//NSMutableArray *mpMutable = [[NSMutableArray alloc] initWithArray:mpArgs copyItems:YES];
	
	int cacheSize = 4000;
	
	
	NSMutableArray *taskArray = [[NSMutableArray alloc] init];
	NSString *mplayerPath = [[NSBundle bundleForClass:[CMPMPPlayer class]] pathForResource:@"mplayer" ofType:@"" inDirectory:@"bin"];
	
	
	mpTask =[[NSTask alloc] init];
	[taskArray addObject:@"-framedrop"];
	[taskArray addObject:@"-autosync"];
	[taskArray addObject:@"30"];
	[taskArray addObject:@"-vo"];
	[taskArray addObject:@"quartz"];
	[taskArray addObject:@"-fs"];
	[taskArray addObject:@"-ontop"];
	
	
	if ([self usePassthrough] == YES)
	{
		
		[taskArray addObject:@"-afm"];
		[taskArray addObject:@"hwac3"];
		[taskArray addObject:@"-ac"];
		[taskArray addObject:@"hwdts,hwac3"];
		CFStringRef devDomain = CFSTR("com.cod3r.ac3passthroughdevice");
		CFPreferencesSetAppValue(CFSTR("engageCAC3Device"), [NSNumber numberWithBool:YES], devDomain);
		CFPreferencesAppSynchronize(devDomain);
		//defaults write com.cod3r.ac3passthroughdevice engageCAC3Device -bool true
	}
	
	
	if (cacheSize > 0)
	{
		[taskArray addObject:@"-cache"];
		[taskArray addObject:[NSString stringWithFormat:@"%i", cacheSize]];
	}
	/*
	 if([mpMutable count] > 0){
	 //	NSLog(@"extraArgs: %@", mpArgs);
	 [taskArray addObjectsFromArray:mpMutable];
	 [mpMutable release];
	 }
	 */
	
	NSString *filename = [asset mediaURL];
	
	
	if(filename != nil)
	{
		/*
		 if ([self addMonitorAspect:filename])
		 {
		 [taskArray addObject:@"-monitoraspect"];
		 [taskArray addObject:@"16:9"];
		 }
		 
		 if ([self addH264Strings:filename])
		 {
		 
		 [taskArray addObjectsFromArray:[self h264Arguments]];
		 
		 // [taskArray addObject:@"-vfm"];
		 //						  [taskArray addObject:@"ffmpeg"];
		 //						  [taskArray addObject:@"-lavdopts"];
		 //						  [taskArray addObject:@"skiploopfilter=nonref"];
		 }
		 */
		[taskArray addObject:filename];
	}
	
	
	
	[mpTask setLaunchPath:mplayerPath];
	[mpTask setArguments:taskArray];
	//NSLog(@"taskarray: %@", [taskArray componentsJoinedByString:@" "]);
	[taskArray release];
	
	//set outputs
	
	NSPipe *output = [[NSPipe alloc] init];
	[mpTask setStandardOutput:output];
	[output release];
	[mpTask setStandardError: [mpTask standardOutput]];
	
	//set inputs
	NSPipe *input = [[NSPipe alloc] init];
	[mpTask setStandardInput:input];
	[input release];
	
	
	
	//register output observer
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(getData:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:[[mpTask standardOutput] fileHandleForReading]];
	
	[[[mpTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	
	
	/*
	 
	 example code on how to set an environment dict for mplayer if we ever want to for any reason.
	 
	 NSMutableDictionary *envDict = [[NSMutableDictionary alloc] init];
	 [envDict setObject: @"1" forKey: @"DYLD_BIND_AT_LAUNCH"];
	 [mpTask setEnvironment:envDict];
	 [envDict release];
	 
	 NSMutableDictionary *envDict = [[NSMutableDictionary alloc] init];
	 [envDict setObject: @"en_US.UTF-8" forKey: @"LANG"];
	 [mpTask setEnvironment:envDict];
	 [envDict release];
	 
	 */
	
	//launch it!
	
	[mpTask launch];
	//[controller releaseScreen];
	
}

- (void) getData: (NSNotification *)aNotification
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
    int mpLog = 0;
	
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length])
    {

		
		
		NSString *theString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
		NSArray *lineArray = [theString componentsSeparatedByString:@"\n"];
		
		
		NSArray *currentArray = [[[lineArray objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
		
		NSString *stringTwo = [theString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([stringTwo isEqualToString:@"Exiting... (End of file)"])
		{
			
			resumeTime = 0;
			[self stopPlayback];
			
			return;
		}
		
		
		if(mpLog == 1)
			NSLog(@"%@", stringTwo);
		
		
		int mpResume = 0;
		
		if (mpResume == 1){
			if ([currentArray containsObject:@"A:"]){
				
				//NSLog(@"currentArray: %@",currentArray );
				if (![[currentArray objectAtIndex:2] isEqualToString:@"V:"])
					resumeTime = [currentArray objectAtIndex:2];
				else
					resumeTime = [currentArray objectAtIndex:1];
				
			}
		}
		
	
		//[self delayScreensaver];
		
    } 
	
	else 
	{
		//[self delayScreensaver];
        [self stopPlayback];
		[pool drain];
		[pool release];
    }
    
    // we need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];  
	
	
}

- (void)stopPlayback
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [[mpTask standardOutput] fileHandleForReading]];
    
    // Make sure the task has actually stopped!
	while([mpTask isRunning]) {
		//[mpTask interrupt];
		[mpTask terminate];
		//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
		[mpTask waitUntilExit];
	}

	mpTask = nil;
	[mpTask release];

	CFStringRef devDomain = CFSTR("com.cod3r.ac3passthroughdevice");
	CFPreferencesSetAppValue(CFSTR("engageCAC3Device"), NULL, devDomain);
	CFPreferencesAppSynchronize(devDomain);
	//[[self stack] popController];
	
	[self playbackStopped];
	
}

- (BOOL)isShuffled {
    return isShuffled;
}

- (void)setIsShuffled:(BOOL)value {
    if (isShuffled != value) {
        isShuffled = value;
    }
}

- (BOOL)repeatFile {
    return repeatFile;
}

- (void)setRepeatFile:(BOOL)value {
    if (repeatFile != value) {
        repeatFile = value;
    }
}

- (BOOL)isPlaylist {
    return isPlaylist;
}

- (void)setIsPlaylist:(BOOL)value {
    if (isPlaylist != value) {
        isPlaylist = value;
    }
}



- (BOOL)useStopTimer {
    return useStopTimer;
}

- (void)setUseStopTimer:(BOOL)value {
    if (useStopTimer != value) {
        useStopTimer = value;
    }
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

	[stopTimer invalidate];
	if([self useStopTimer])
	{
		stopTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 target:self selector:@selector(stopTimerFire) userInfo:nil repeats:NO];
	}
	
}

- (void)restart
{
	//nothing yet
}

- (double)elapsedPlaybackTime
{
	return nil;
}

- (double)trackDuration;
{
	return nil;
}





@end
