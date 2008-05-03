/*
 * SapphireVideoPlayerController.m
 * Sapphire
 *
 * Created by pnmerrill on Apr. 26, 2008.
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

#import <AudioUnit/AudioUnit.h>

#import "SapphireVideoPlayerController.h"
#import "SapphireMetaData.h"
#import "SapphireSettings.h"

#define PASSTHROUGH_KEY		(CFStringRef)@"attemptPassthrough"
#define A52_DOMIAN			(CFStringRef)@"com.cod3r.a52codec"

#define SOUND_STATE_SOUND_ENABLED		1
#define SOUND_STATE_SOUND_PASSTHROUGH	2

@implementation SapphireVideoPlayerController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRVideoPlayerController class] instancesRespondToSelector:@selector(initWithScene:)])
		self = [super initWithScene:scene];
	else
		self = [super init];
	
	return self;
}

- (void) dealloc
{
	[currentPlayFile release];
	[super dealloc];
}

static BOOL findCorrectDescriptionForStream(AudioStreamID streamID, int sampleRate)
{
	OSStatus err;
	UInt32 propertySize = 0;
	err = AudioStreamGetPropertyInfo(streamID, 0, kAudioStreamPropertyPhysicalFormats, &propertySize, NULL);
	
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioStreamBasicDescription *descs = malloc(propertySize);
	if(descs == NULL)
		return NO;
	
	int formatCount = propertySize / sizeof(AudioStreamBasicDescription);
	err = AudioStreamGetProperty(streamID, 0, kAudioStreamPropertyPhysicalFormats, &propertySize, descs);
	
	if(err != noErr)
	{
		free(descs);
		return NO;
	}
	
	int i;
	BOOL ret = NO;
	for(i=0; i<formatCount; i++)
	{
		if (descs[i].mBitsPerChannel == 16 && descs[i].mFormatID == kAudioFormatLinearPCM)
		{
			if(descs[i].mSampleRate == sampleRate)
			{
				err = AudioStreamSetProperty(streamID, NULL, 0, kAudioStreamPropertyPhysicalFormat, sizeof(AudioStreamBasicDescription), descs + i);
				if(err != noErr)
					continue;
				ret = YES;
				break;
			}
		}
	}
	free(descs);
	return ret;
}

static BOOL setupDevice(AudioDeviceID devID, int sampleRate)
{
	OSStatus err;
	UInt32 propertySize = 0;
	err = AudioDeviceGetPropertyInfo(devID, 0, FALSE, kAudioDevicePropertyStreams, &propertySize, NULL);
	
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioStreamID *streams = malloc(propertySize);
	if(streams == NULL)
		return NO;
	
	int streamCount = propertySize / sizeof(AudioStreamID);
	err = AudioDeviceGetProperty(devID, 0, FALSE, kAudioDevicePropertyStreams, &propertySize, streams);
	if(err != noErr)
	{
		free(streams);
		return NO;
	}
	
	int i;
	BOOL ret = NO;
	for(i=0; i<streamCount; i++)
	{
		if(findCorrectDescriptionForStream(streams[i], sampleRate))
		{
			ret = YES;
			break;
		}
	}
	free(streams);
	return ret;
}

static BOOL setupAudioOutput(int sampleRate)
{
	OSErr err;
	UInt32 propertySize = 0;
	
	err = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, NULL);
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioDeviceID *devs = malloc(propertySize);
	if(devs == NULL)
		return NO;
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, devs);
	if(err != noErr)
	{
		free(devs);
		return NO;
	}
	
	int i, devCount = propertySize/sizeof(AudioDeviceID);
	BOOL ret = NO;
	for(i=0; i<devCount; i++)
	{
		if(setupDevice(devs[i], sampleRate))
		{
			err = AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, sizeof(AudioDeviceID), devs + i);
			if(err != noErr)
				continue;
			ret = YES;
			break;
		}
	}
	free(devs);
	return ret;
}

- (void)enablePassthrough
{
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	BOOL useAC3Passthrough = NO;

	if([settings useAC3Passthrough])
	{
		Float64 sampleRate = [currentPlayFile sampleRate];
		UInt32 type = [currentPlayFile audioFormatID];
		
		if((type == 'ac-3' || type == 0x6D732000) && setupAudioOutput((int)sampleRate))
			useAC3Passthrough = YES;
	}
	
	Boolean temp;
	BOOL passthrough = CFPreferencesGetAppBooleanValue(PASSTHROUGH_KEY, A52_DOMIAN, &temp);
	BOOL soundsWereEnabled = NO;
	if(useAC3Passthrough)
	{
		RUIPreferences *prefs = [RUIPreferences sharedFrontRowPreferences];
		soundsWereEnabled = [prefs boolForKey:@"PlayFrontRowSounds"];
		if(soundsWereEnabled)
			[prefs setBool:NO forKey:@"PlayFrontRowSounds"];
		CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:1], A52_DOMIAN);
	}
	else
		CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:0], A52_DOMIAN);
	soundState = (passthrough ? SOUND_STATE_SOUND_PASSTHROUGH : 0) | (soundsWereEnabled ? SOUND_STATE_SOUND_ENABLED : 0);
	CFPreferencesAppSynchronize(A52_DOMIAN);
}

- (void)setPlayFile:(SapphireFileMetaData *)file
{
	currentPlayFile = [file retain];
	[self enablePassthrough];
}

- (void)willBePopped
{
	[super willBePopped];
	//Turn off the AC3 Passthrough hack
	CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:((soundState & SOUND_STATE_SOUND_PASSTHROUGH)? 1 : 0)], A52_DOMIAN);
	CFPreferencesAppSynchronize(A52_DOMIAN);
	if(soundState & SOUND_STATE_SOUND_ENABLED)
		[(RUIPreferences *)[RUIPreferences sharedFrontRowPreferences] setBool:YES forKey:@"PlayFrontRowSounds"];
	
	/*resume time*/
	BRVideoPlayer *player = [self player];
	float elapsed = [player elapsedPlaybackTime];
	float duration = [player trackDuration];
	if(elapsed / duration > 0.9f)
		/*Mark as watched and reload info*/
		[currentPlayFile setWatched:YES];
	
	/*Get the resume time to save*/
	if(elapsed < duration - 2)
		[currentPlayFile setResumeTime:elapsed];
	else
		[currentPlayFile setResumeTime:0];
	[currentPlayFile writeMetaData];	 
}

@end
