/*
 * CMPDVDPlayerController.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 3 2010
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

#import "CMPDVDPlayerController.h"
#import "CMPDVDPlayer.h"
#import "CMPDVDWindowCreationAction.h"
#import "CMPATVVersion.h"
#import "CoreGraphicsServices.h"

@interface NSObject (compat)
- (void)setOpacity:(float)opacity;
@end

@interface CMPDVDPlayerController ()
- (void)showResumeOverlayWithDismiss:(BOOL)dismiss;
@end


@implementation CMPDVDPlayerController

+ (NSSet *)knownPlayers
{
	return [NSSet setWithObject:[CMPDVDPlayer class]];
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
	
	[self setListTitle:@"Initiating DVD Playback"];
	[self setListIcon:nil];
	
	windowCreation = [[CMPDVDWindowCreationAction alloc] initWithController:self andSettings:nil];
#ifdef PLAY_WITH_OVERLAY
	[timer invalidate];
	timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(something) userInfo:nil repeats:NO];
#endif
	
	return self;
}

#ifdef PLAY_WITH_OVERLAY
- (void)setOpacity:(float)opacity
{
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	float clearComp[] = {0, 0, 0, 0};
	CGColorRef clear = CGColorCreate(space, clearComp);
	id layer = [[self header] layer];
	int count = 0;
	while(layer != nil)
	{
//		[layer setOpaque:NO];
		NSLog(@"Layer is %@ with %d children", layer, [[layer sublayers] count]);
		id superlayer = [layer superlayer];
		//		if(count < 6)
//		[layer setOpacity:opacity];
		[layer setBackgroundColor:clear];
		NSLog(@"Set opacity of %d layer", count);
		layer = superlayer;
		count++;
	}
}

- (void)something
{
	static int counter = 0;
	NSString *str = @"Some really long string for testing";
	[self setListTitle:[str substringToIndex:counter]];
//	[self setOpacity:0.0f];
//	if(counter == 0)
//	{
//		CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
//		float clearComp[] = {0, 0, 0, 0};
//		CGColorRef clear = CGColorCreate(space, clearComp);
//		id layer = [[self header] layer];
//		int count = 0;
//		while(layer != nil)
//		{
//			[layer setOpaque:NO];
//			NSLog(@"Layer is %@ with %d children", layer, [[layer sublayers] count]);
//			id superlayer = [layer superlayer];
////			if(count < 6)
//				[layer setOpacity:0.0f];
//			NSLog(@"Set opacity of %d layer", count);
//			layer = superlayer;
//			count++;
//		}
//	}
	counter++;
	if(counter < [str length])
		timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(something) userInfo:nil repeats:NO];
	else
	{
		timer = nil;
		counter = 0;
	}

}
#endif

- (void) dealloc
{
#ifdef PLAY_WITH_OVERLAY
	[timer invalidate];
	timer = nil;
#endif
	[player release];
	[delegate release];
	[windowCreation release];
	[overlayDismiss invalidate];
	[statusOverlay release];
	[subtitlesOverlay release];
	[audioOverlay release];
	[chapterOverlay release];
	[playheadOverlay release];
	[blurredMenu release];
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

	CFBooleanRef passthroughValue = kCFBooleanFalse;
	NSNumber *passthrough = [settings objectForKey:CMPPlayerUsePassthroughDeviceKey];
	if([passthrough boolValue])
		passthroughValue = kCFBooleanTrue;
	
	CFPreferencesSetAppValue(CFSTR("engageCAC3Device"), passthroughValue, CFSTR("com.cod3r.ac3passthroughdevice"));
}

- (void)setPlaybackDelegate:(id <CMPPlayerControllerDelegate>)aDelegate
{
	delegate = [aDelegate retain];
}

- (id <CMPPlayerControllerDelegate>)delegate
{
	return delegate;
}

- (void)initiatePlayback
{
//	[self setOpacity:0.0f];
	[windowCreation openWithError:nil];
	BOOL resume = NO;
	CMPDVDOverlayWindow *shield = [windowCreation addBlackShieldWindow];
	[shield display];
	[player initiatePlaybackWithResume:&resume];
	if(resume)
	{
		[self showResumeOverlayWithDismiss:NO];
		[windowCreation performSelector:@selector(closeOverlay:) withObject:shield afterDelay:0.5];
	}
	else
		[windowCreation closeOverlay:shield withFade:[NSNumber numberWithFloat:0]];
}

- (void)playbackStopped
{
	[[self stack] popController];
}

#ifdef PLAY_WITH_OVERLAY
- (BOOL)newFrameForTime:(void *)fp8
{
	return YES;
	static int count = 0;
	if(count == 0)
	{
		count = 0;
		return YES;
	}
//	count++;
	return NO;
}

- (void)drawFrameInBounds:(struct CGSize)size
{
	if(!blacked)
	{
		blacked = YES;
		glColor4f(0, 0, 0, GL_ONE);
		glBegin(GL_QUADS);
		glVertex2f(0, 0);
		glVertex2f(0, size.height);
		glVertex2f(size.width, size.height);
		glVertex2f(size.width, 0);
		glEnd();
	}
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	return;
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glPixelZoom( 1.0, -1.0 );
	CGSConnectionID cid = _CGSDefaultConnection();
	CGRect bounds;
	CGSWindowID dvdWindow = [windowCreation dvdWindow];
	if(!dvdWindow)
		return;
	CGSGetWindowBounds(cid, dvdWindow, &bounds);
	NSLog(@"Bounds is %fx%f - %fx%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
//	CGLGetCurrentContext()
	char *bitmap = malloc(bounds.size.width *bounds.size.height * 4);
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef context = CGBitmapContextCreate(bitmap, bounds.size.width, bounds.size.height, 8, bounds.size.width * 4, colorspace, kCGImageAlphaNoneSkipLast);
    // Copy the contents of the window to the graphic context
	CGContextCopyWindowCaptureContentsToRect(context, bounds, cid, dvdWindow, bounds);
	
	glRasterPos2f(0, 0);
	glDrawPixels(bounds.size.width, bounds.size.height, GL_RGBA, GL_UNSIGNED_BYTE, bitmap);
	
//	GLuint texName;
//	glGenTextures(1, &texName);
//	glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
//	glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, bounds.size.width, bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmap);
//	glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
//	
//	glBegin (GL_QUADS);
//	glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
//	glVertex2f (bounds.origin.x, bounds.origin.y);
//    
//	glTexCoord2f (0.0f, bounds.size.height); // draw lower left in world coordinates
//	glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
//    
//	glTexCoord2f (bounds.size.width, bounds.size.height); // draw upper right in world coordinates
//	glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
//    
//	glTexCoord2f (bounds.size.width, 0.0f); // draw lower right in world coordinates
//	glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
//	glEnd ();
//	glDeleteTextures(1, &texName);
	CGContextRelease(context);
	CGColorSpaceRelease(colorspace);
	free(bitmap);
}

- (void)controlWasActivated
{
	[super controlWasActivated];
	[[BRRenderer singleton] addPlaybackDelegate:self];
}
#endif

- (void)wasPushed
{
	[super wasPushed];
	[self performSelector:@selector(initiatePlayback) withObject:nil afterDelay:0.3];
}

- (void)wasPopped
{
	[super wasPopped];
#ifdef PLAY_WITH_OVERLAY
	[[BRRenderer singleton] removePlaybackDelegate:self];
	
//	id layer = [[self header] layer];
//	int count = 0;
//	while(layer != nil)
//	{
//		[layer setOpaque:YES];
//		NSLog(@"Layer is %@ with %d children", layer, [[layer sublayers] count]);
//		id superlayer = [layer superlayer];
//		[layer setOpacity:1.0f];
//		NSLog(@"Set opacity of %d layer", count);
//		layer = superlayer;
//		count++;
//	}	
	
#endif
	NSMutableDictionary *endSettings = [[NSMutableDictionary alloc] init];
	double elapsed = [player elapsedPlaybackTime];
	double duration = [player trackDuration];
	
	if(elapsed != 0.0)
		[endSettings setObject:[NSNumber numberWithDouble:elapsed] forKey:CMPPlayerResumeTimeKey];
	if(duration != 0.0)
		[endSettings setObject:[NSNumber numberWithDouble:duration] forKey:CMPPlayerDurationTimeKey];
	[delegate controller:self didEndWithSettings:endSettings];
	[delegate autorelease];
	delegate = nil;
	[endSettings release];
	
	[player stopPlayback];
	[windowCreation closeWithError:nil];
}

static void closeAndNilOverlay(CMPDVDWindowCreationAction *windowCreation, CMPDVDOverlayWindow * *overlay, NSNumber *fadeTime)
{
	CMPDVDOverlayWindow *actualOverlay = *overlay;
	[windowCreation closeOverlay:actualOverlay withFade:fadeTime];
	[actualOverlay release];
	*overlay = nil;
}

- (void)overlayModeChangedWithFade:(float)fade
{
	NSNumber *fadeTime = [NSNumber numberWithFloat:fade];
	BOOL closeStatus = (statusOverlay != nil);
	BOOL closeSubtitles = (subtitlesOverlay != nil);
	BOOL closeAudio = (audioOverlay != nil);
	BOOL closeChapter = (chapterOverlay != nil);
	BOOL closePlayhead = (playheadOverlay != nil);
	
	switch (overlayMode) {
		case CMPDVDPlayerControllerOverlayModeStatus:
			closeStatus = NO;
			closePlayhead = NO;
			break;
		case CMPDVDPlayerControllerOverlayModeSubAndAudio:
			closeSubtitles = NO;
			closeAudio = NO;
			break;
		case CMPDVDPlayerControllerOverlayModeChapters:
			closeChapter = NO;
			closePlayhead = NO;
			break;
		default:
			break;
	}
	
	if(closeStatus)
		closeAndNilOverlay(windowCreation, &statusOverlay, fadeTime);
	if(closeSubtitles)
		closeAndNilOverlay(windowCreation, &subtitlesOverlay, fadeTime);
	if(closeAudio)
		closeAndNilOverlay(windowCreation, &audioOverlay, fadeTime);
	if(closeChapter)
		closeAndNilOverlay(windowCreation, &chapterOverlay, fadeTime);
	if(closePlayhead)
		closeAndNilOverlay(windowCreation, &playheadOverlay, fadeTime);
}

- (void)fadeOverlays
{
	overlayDismiss = nil;
	overlayMode = CMPDVDPlayerControllerOverlayModeNone;
	[self overlayModeChangedWithFade:0.5];
}

- (void)resetOverlayTimerTo:(NSTimeInterval)time
{
	[overlayDismiss invalidate];
	overlayDismiss = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(fadeOverlays) userInfo:nil repeats:NO];
}

- (void)showPlayheadOverlay
{
	if(playheadOverlay)
		return;
	playheadOverlay = [[windowCreation addPlayheadOverlay] retain];
	[playheadOverlay setPlayer:player];
	[playheadOverlay displayWithFadeTime:0.1];
}

- (void)showSubAndAudioMode
{
	overlayMode = CMPDVDPlayerControllerOverlayModeSubAndAudio;
	[self overlayModeChangedWithFade:0];
	
	if(!subtitlesOverlay)
		subtitlesOverlay = [[windowCreation addTextOverlayInPosition:CMPDVDOverlayUpperLeft] retain];
	[subtitlesOverlay setText:[player currentSubFormat]];
	[subtitlesOverlay displayWithFadeTime:0.25];
	if(!audioOverlay)
		audioOverlay = [[windowCreation addTextOverlayInPosition:CMPDVDOverlayUpperRight] retain];
	[audioOverlay setText:[player currentAudioFormat]];
	[audioOverlay displayWithFadeTime:0.25];
	
	[self resetOverlayTimerTo:10];
}

- (void)showChapterMode
{
	overlayMode = CMPDVDPlayerControllerOverlayModeChapters;
	[self overlayModeChangedWithFade:0];
	
	if(!chapterOverlay)
		chapterOverlay = [[windowCreation addTextOverlayInPosition:CMPDVDOverlayUpperLeft] retain];
	[chapterOverlay setText:[NSString stringWithFormat:@"Chapter %d/%d", [player currentChapter], [player chapters]]];
	[chapterOverlay displayWithFadeTime:0.25];
	[self showPlayheadOverlay];
	
	[self resetOverlayTimerTo:10];
}

- (NSString *)stringForPlayerState
{
	CMPDVDState state = [player state];
	int speed = [player playSpeed];
	NSString *text = nil;
	if(state == CMPDVDStatePlaying)
		text = [NSString stringWithFormat:@"%C", 0x25B6];
	if(state == CMPDVDStatePaused)
		text = [NSString stringWithFormat:@"%C%C", 0x258C, 0x258C];
	else if(state == CMPDVDStateScanningForward)
		text = [NSString stringWithFormat:@"%C%C%dx", 0x25B6, 0x25B6, speed];
	else if(state == CMPDVDStateScanningBackward)
		text = [NSString stringWithFormat:@"%C%C%dx", 0x25C0, 0x25C0, speed];
	else if(state == CMPDVDStatePlayingSlowForward)
		text = [NSString stringWithFormat:@"%C1/%dx", 0x25B6, speed];
	else if(state == CMPDVDStatePlayingSlowBackward)
		text = [NSString stringWithFormat:@"%C1/%dx", 0x25C0, speed];
	
	return text;
}

- (void)showStateMode
{
	overlayMode = CMPDVDPlayerControllerOverlayModeStatus;
	[self overlayModeChangedWithFade:0];
	
	if(!statusOverlay)
		statusOverlay = [[windowCreation addTextOverlayInPosition:CMPDVDOverlayUpperLeft] retain];
	[statusOverlay setText:[self stringForPlayerState]];
	[statusOverlay displayWithFadeTime:0.25];
	[self showPlayheadOverlay];
	
	[self resetOverlayTimerTo:3];
}

- (void)dismissOverlaysWithFadeTime:(float)fadeTime
{
	overlayMode = CMPDVDPlayerControllerOverlayModeNone;
	[self overlayModeChangedWithFade:fadeTime];
	
	//Catch any others
	[windowCreation closeAllOverlaysWithFadeTime:fadeTime];
	
	[overlayDismiss invalidate];
	overlayDismiss = nil;
}

- (void)showResumeOverlayWithDismiss:(BOOL)dismiss
{
	if(dismiss)
		[self dismissOverlaysWithFadeTime:0];
	blurredMenu = [[windowCreation addBlurredMenuOverlayWithItems:[NSArray arrayWithObjects:@"Resume Playback", @"Start From Beginning", @"Main Menu", nil]] retain];
	[blurredMenu displayWithFadeTime:0.5];
}

- (BOOL)brEventAction:(BREvent *)event
{
	NSLog(@"Got event %@", event);
	BREventRemoteAction action = [CMPATVVersion remoteActionForEvent:event];
	if(![player playing])
		return [super brEventAction:event];
	
	if([event value] == 0 && action != kBREventRemoteActionMenu)
		return NO;
	
	BOOL inMenu = [player inMenu];
	CMPDVDState state = [player state];
	NSLog(@"State is %d and doing %d", state, action);
	BOOL playingInSomeForm = (state == CMPDVDStatePlaying || state == CMPDVDStateScanningForward || state == CMPDVDStateScanningBackward || state == CMPDVDStatePlayingSlowForward || state == CMPDVDStatePlayingSlowBackward);
	BOOL supressStateDisplay = inMenu;
	
	switch (action) {
		case kBREventRemoteActionSwipeRight:
		case kBREventRemoteActionRight:
			if(blurredMenu)
				return NO;
			else if(inMenu)
				[player doUserNavigation:CMPDVDPlayerNavigationRight];
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeSubAndAudio)
			{
				[player nextAudioStream];
				[audioOverlay setText:[player currentAudioFormat]];
				[self resetOverlayTimerTo:10];
			}
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeChapters)
			{
				[player nextChapter];
				[chapterOverlay setText:[NSString stringWithFormat:@"Chapter %d/%d", [player currentChapter], [player chapters]]];
				[self resetOverlayTimerTo:10];
			}
			else if(playingInSomeForm)
				[player incrementScanRate];
			else
				[player nextFrame];
			break;
		case kBREventRemoteActionSwipeLeft:
		case kBREventRemoteActionLeft:
			if(blurredMenu)
				return NO;
			else if(inMenu)
				[player doUserNavigation:CMPDVDPlayerNavigationLeft];
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeSubAndAudio)
			{
				[player nextSubStream];
				[subtitlesOverlay setText:[player currentSubFormat]];
				[self resetOverlayTimerTo:10];
			}
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeChapters)
			{
				[player previousChapter];
				[chapterOverlay setText:[NSString stringWithFormat:@"Chapter %d/%d", [player currentChapter], [player chapters]]];
				[self resetOverlayTimerTo:10];
			}
			else if(playingInSomeForm)
				[player decrementScanRate];
			else
				//We cannot step frame backwards!!!!
				[player decrementScanRate];
			break;
		case kBREventRemoteActionSwipeUp:
		case kBREventRemoteActionUp:
			if(blurredMenu)
				return [blurredMenu previousItem];
			else if(inMenu)
				[player doUserNavigation:CMPDVDPlayerNavigationUp];
			else if(overlayMode <= CMPDVDPlayerControllerOverlayModeStatus)
				[self showSubAndAudioMode];
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeSubAndAudio)
				overlayMode = CMPDVDPlayerControllerOverlayModeStatus;
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeChapters)
				overlayMode = CMPDVDPlayerControllerOverlayModeStatus;
			else
				;//Something else
			break;
		case kBREventRemoteActionSwipeDown:
		case kBREventRemoteActionDown:
			if(blurredMenu)
				return [blurredMenu nextItem];
			else if(inMenu)
				[player doUserNavigation:CMPDVDPlayerNavigationDown];
			else if(overlayMode <= CMPDVDPlayerControllerOverlayModeStatus)
				[self showChapterMode];
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeSubAndAudio)
				overlayMode = CMPDVDPlayerControllerOverlayModeStatus;
			else if(overlayMode == CMPDVDPlayerControllerOverlayModeChapters)
				overlayMode = CMPDVDPlayerControllerOverlayModeStatus;
			else
				;//Something else
			break;
		case kBREventRemoteActionMenu:
			if(blurredMenu != nil)
				return [super brEventAction:event];
			
			[player pause];
			[self showResumeOverlayWithDismiss:YES];
			supressStateDisplay = YES;
			break;
		case kBREventRemoteActionPlay:
		case kBREventRemoteActionPlayNew:
			if(blurredMenu)
			{
				int selection = [blurredMenu selectedItem];
				[self dismissOverlaysWithFadeTime:0];
				[blurredMenu release];
				blurredMenu = nil;
				switch (selection) {
					case 0:
						[player play];
						break;
					case 1:
						//Need to restart the playback somehow
						[player restart];
						break;
					case 2:
						[player goToMenu];
						break;
					default:
						break;
				}
				supressStateDisplay = YES;
			}
			else if(inMenu)
				[player doUserNavigation:CMPDVDPlayerNavigationEnter];
			else if(state == CMPDVDStatePlaying)
				[player pause];
			else if(playingInSomeForm || state == CMPDVDStatePaused)
				[player play];
			else
				[player pause];
			break;
		default:
			NSLog(@"unknown %d", action);
			return [super brEventAction:event];
	}
	
	if(!supressStateDisplay && overlayMode <= CMPDVDPlayerControllerOverlayModeStatus)
		[self showStateMode];
	
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
