/*
 * CMPDVDWindowCreationAction.m
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

#import "CMPDVDWindowCreationAction.h"
#import "CMPScreenReleaseAction.h"
#import "CoreGraphicsServices.h"
#import "CMPOverlayModeAction.h"
#import "CMPATVVersion.h"
#import "CMPDVDPlayer.h"
#import "CMPOverlayAction.h"

@interface BRDisplayManager (compat)
+ (BRDisplayManager *)sharedInstance;
@end

@implementation CMPDVDWindowCreationAction

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	self = [super init];
	if(!self)
		return self;
	
//	screenRelease = [[CMPOverlayModeAction alloc] initWithController:controller andSettings:settings];
	screenRelease = [[CMPScreenReleaseAction alloc] initWithController:controller andSettings:settings];
	
	return self;
}

- (void) dealloc
{
	[screenRelease release];
	[overlayAction release];
	[dvdWindow release];
	[super dealloc];
}

static int CreateEmptyWindow(CGRect myFrame)
{
	//NSLog(@"createEmptyWindow");
    CGSRegion frameRgn;
    CGSRegion emptyRgn;
    int window;
    char something[100];
	
	
    CGSNewRegionWithRect(&myFrame, &frameRgn);
    CGSNewEmptyRegion(&emptyRgn);
	
    int conn = CGSMainConnectionID();
	
	//NSLog(@"connection id: %i", conn);
	
    CGSNewWindowWithOpaqueShape(conn, 2, 0, 0, frameRgn, emptyRgn, 0, &something,
								32, &window);
	
    
	CGSSetWindowOpacity(conn, window, 1);
	
	
    CGSReleaseRegion(emptyRgn);
    CGSReleaseRegion(frameRgn);
	
    return window;
}

- (BOOL)openWithError:(NSError **)error
{
	BOOL success = [screenRelease openWithError:error];
	
	if(!success)
	{	
		NSLog(@"Release failed");
		return NO;
	}
	
	//NSLog(@"createDvdWindow");
    CGDirectDisplayID display = [(BRDisplayManager *)[BRDisplayManager sharedInstance] display];
    CGRect frame = CGDisplayBounds(display);
    frame.size.width = CGDisplayPixelsWide(display);
    frame.size.height = CGDisplayPixelsHigh(display);
	
    if(frame.size.width < 0.0f)
        frame.size.width = ABS(frame.size.width);
    if(frame.size.height < 0.0f)
        frame.size.height = ABS(frame.size.height);
	
	NSRect frameRect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	NSApplicationLoad();
	dvdWindow = [[NSWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[dvdWindow setReleasedWhenClosed:NO];
	[dvdWindow setBackgroundColor:[NSColor blackColor]];
	int dvdWindowID = [dvdWindow windowNumber];
	//dvdWindowID = CreateEmptyWindow(frame);
	CGSSetWindowLevel(_CGSDefaultConnection(), dvdWindowID, CGShieldingWindowLevel()+1);
		
	CGSOrderWindow(_CGSDefaultConnection(), dvdWindowID, kCGSOrderAbove, 0);
	
    CGContextRef ctx = (CGContextRef)CGWindowContextCreate(_CGSDefaultConnection(), dvdWindowID, NULL);
	
    CGContextClear(ctx);
    CGContextFlush(ctx);
    CGContextRelease(ctx);
	
	overlayAction = [[CMPOverlayAction alloc] initWithController:nil andSettings:[NSDictionary dictionaryWithObjectsAndKeys:dvdWindow, CMPOverlayActionWindowKey, nil]];
	[overlayAction openWithError:nil];
		
	OSStatus setWindowErr = DVDSetVideoWindowID(dvdWindowID);
	if(setWindowErr != noErr)
		NSLog(@"Set DVD Window error is %d", setWindowErr);
	OSStatus displayErr = DVDSetVideoDisplay([[BRDisplayManager sharedInstance] display]);
	if(displayErr != noErr)
		NSLog(@"Set DVD Video error is %d", displayErr);
	
	return setWindowErr == noErr && displayErr == noErr;
}

- (void)setWindowAlpha:(float)alpha
{
	[dvdWindow setAlphaValue:alpha];
}

- (CMPOverlayAction *)overlayAction
{
	return overlayAction;
}

- (BOOL)closeWithError:(NSError **)error
{
//	int conn = _CGSDefaultConnection();
//	NSLog(@"conn: %i dvdWindow: %i", conn, dvdWindowID);
//	OSStatus theErr = CGSReleaseWindow(conn, dvdWindowID);
//	NSLog(@"CGSReleaseWindow: %d", theErr);
	[dvdWindow close];
	[overlayAction closeWithError:error];
	
	return [screenRelease closeWithError:error];
}
@end
