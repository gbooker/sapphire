/*
 * CMPMPPlayerController.m
 * CommonMediaPlayer
 *
 * Created by Kevin Bradley on June 5th 2010
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

#import "CMPMPPlayerController.h"
#import "CMPMPPlayer.h"
#import "CMPATVVersion.h"
#import "CoreGraphicsServices.h"



@implementation CMPMPPlayerController

+ (NSSet *)knownPlayers
{
	return [NSSet setWithObject:[CMPMPPlayer class]];
}

#ifdef PLAY_WITH_OVERLAY
static NSTimer *timer = nil;
#endif

- (id)initWithScene:(BRRenderScene *)scene player:(id <CMPPlayer>)aPlayer
{
	if([[BRMenuController class] instancesRespondToSelector:@selector(initWithScene:)])
		self = [super initWithScene:scene];
	else
		self = [super init];
	if(!self)
		return self;
	
	[[self list] setDatasource:self];
	
	player = [aPlayer retain];
	[player setController:self];
	
	[self setListTitle:@"Initiating MPlayer Playback"];
	[self setListIcon:nil];
	

	
	return self;
}





- (void) dealloc
{

	[player release];
	[delegate release];
	[super dealloc];
}


- (id <CMPPlayer>)player
{
	return player;
}

- (void)setPlaybackSettings:(NSDictionary *)settings
{
	NSNumber *resume = [settings objectForKey:CMPPlayerResumeTimeKey];
	
	if(resume != nil)
		[player setResumeTime:[resume intValue]];

	BOOL stopValue = TRUE;
	NSNumber *useStopTimer = [settings objectForKey:CMPPlayerUseStopTimer];
	if(![useStopTimer boolValue])
		stopValue = FALSE;
	
	[player setUseStopTimer:stopValue];
	
	CFBooleanRef passthroughValue = kCFBooleanFalse;
	NSNumber *passthrough = [settings objectForKey:CMPPlayerUsePassthroughDeviceKey];
	if([passthrough boolValue])
	{
		passthroughValue = kCFBooleanTrue;
		[player setUsePassthrough:YES];
	}

	
	CFStringRef devDomain = CFSTR("com.cod3r.ac3passthroughdevice");
	CFPreferencesSetAppValue(CFSTR("engageCAC3Device"), passthroughValue, devDomain);
	CFPreferencesAppSynchronize(devDomain);
}

- (void)setPlaybackDelegate:(id <CMPPlayerControllerDelegate>)aDelegate
{
	delegate = [aDelegate retain];
}

- (id <CMPPlayerControllerDelegate>)delegate
{
	return delegate;
}

- (void)releaseScreen
{
	screenRelease = [[CMPScreenReleaseAction alloc] initWithController:self andSettings:nil];
	[screenRelease openWithError:nil];
}

- (void)initiatePlayback
{

	BOOL resume = NO;

	[self releaseScreen];
	[player initiatePlaybackWithResume:&resume];
	
}

- (void)playbackStopped
{
	[[self stack] popController];
}

- (void)controlWasActivated
{
	[super controlWasActivated];
	//[[BRRenderer singleton] addPlaybackDelegate:self]; -- not sure what this does
}


- (void)wasPushed
{
	[super wasPushed];
	[self performSelector:@selector(initiatePlayback) withObject:nil afterDelay:0.3];
}

- (void)wasPopped
{
	[super wasPopped];

	NSMutableDictionary *endSettings = [[NSMutableDictionary alloc] init];
	//double elapsed = [player elapsedPlaybackTime];
	//double duration = [player trackDuration];
	//NSLog(@"duration: %d, elapsed: %d", elapsed, duration);
	//if(elapsed >= 0.0)
	//	[endSettings setObject:[NSNumber numberWithDouble:elapsed] forKey:CMPPlayerResumeTimeKey];
	//if(duration >= 0.0)
	//	[endSettings setObject:[NSNumber numberWithDouble:duration] forKey:CMPPlayerDurationTimeKey];

	CFStringRef devDomain = CFSTR("com.cod3r.ac3passthroughdevice");
	CFPreferencesSetAppValue(CFSTR("engageCAC3Device"), NULL, devDomain);
	CFPreferencesAppSynchronize(devDomain);
	
	[delegate controller:self didEndWithSettings:endSettings];
	[delegate autorelease];
	delegate = nil;
	[endSettings release];
	
	[player stopPlayback];
	[screenRelease closeWithError:nil];
	//[windowCreation closeWithError:nil];
}




- (BOOL)brEventAction:(BREvent *)event
{
	//NSLog(@"Got event %@", event);
	BREventRemoteAction action = [CMPATVVersion remoteActionForEvent:event];
	if(![player playing])
		return [super brEventAction:event];
	
	if([event value] == 0 && action != kBREventRemoteActionMenu)
		return NO;
	
	switch (action) {
		case kBREventRemoteActionSwipeRight:
		case kBREventRemoteActionRight:
			
			[player seekTenForward];
			
			break;
			
		case kBREventRemoteActionSwipeLeft:
		case kBREventRemoteActionLeft:
			
			[player seekTenBack];
			break;
	
		case kBREventRemoteActionSwipeUp:
		case kBREventRemoteActionUp:
			
			[player volumeUp];
			
			break;
		case kBREventRemoteActionSwipeDown:
		case kBREventRemoteActionDown:
			
			[player volumeDown];
			break;
		
		case kBREventRemoteActionMenu:
			
			[player stopPlayback];
			break;
			
		case kBREventRemoteActionPlay:
		case kBREventRemoteActionPlayNew:
			
			[player play];
			break;
			
		default:
			NSLog(@"unknown %d", action);
			return [super brEventAction:event];
	}
	
	
	return YES;
}

- (NSString *)titleForRow:(long)row {
	return nil;
}

-(float)heightForRow:(long)row {
	return 0.0f;
}

-(id)itemForRow:(long)row {
	return nil;
}

- (long)itemCount {
	return 0;
}

- (void)itemSelected:(long)row
{
}

- (id<BRMediaPreviewController>)previewControllerForItem:(long)row
{
	return nil;
}

- (id<BRMediaPreviewController>)previewControlForItem:(long)row
{
	return [self previewControllerForItem:row];
}

@end
