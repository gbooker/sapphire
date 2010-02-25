/*
 * CMPScreenReleaseAction.m
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

#import <objc/objc-runtime.h>

#import "CMPScreenReleaseAction.h"
#import "CMPATVVersion.h"
#import "CMPTypesDefines.h"

#ifndef CARenderer
typedef void CARenderer;
#endif

@interface BRRenderer (ReleaseAdditions)
- (BRRenderDisplayLink *) link;
- (BRRenderContext *) context;
- (id) target;
- (CARenderer*) renderer;
- (void) setRenderer:(CARenderer*) theRenderer;

@end

@interface NSObject (compat)
+ (id)settingsFacade;
- (NSDictionary *)modeDictionary;
- (int)screenSaverTimeout;
- (void)setScreenSaverTimeout:(int)newTimeout;
- (void)updateActivity;
- (void)startRenderingOnDisplay:(CGDirectDisplayID)display;
@end

@interface BRDisplayManager (compat)
+ (BRDisplayManager *)sharedInstance;
@end

@interface BRRenderScene (compat)
+ (BRRenderScene *)singleton;
- (BRRenderContext *)context;
- (BRRenderContext *)persistentContext;
@end

@interface BRRenderer (compat)
+ (BRRenderer *)singleton;
@end

@interface BRRenderDisplayLink (compat)
- (void)setLinkRunning:(BOOL)running;
@end

@interface BRRenderScene (ReleaseAdditions)
- (BOOL)_attachDrawableContext;
@end

@implementation BRRenderer (ReleaseAdditions)

- (CARenderer*) renderer {
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_renderer");
	
	return *(CARenderer * *)(((char *)self)+ret->ivar_offset);
}

- (void) setRenderer:(CARenderer*) theRenderer{
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_renderer");
	
	*(CARenderer * *)(((char *)self)+ret->ivar_offset) = theRenderer;
}


- (id) target
{
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_target");
	
	return *(id *)(((char *)self)+ret->ivar_offset);
	
}

- (BRRenderDisplayLink *) link
{
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_link");
	
	return *(BRRenderDisplayLink * *)(((char *)self)+ret->ivar_offset);
	
}

- (BRRenderContext *) context
{
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_context");
	
	return *(BRRenderContext * *)(((char *)self)+ret->ivar_offset);
	
}

@end

@implementation BRRenderScene (ReleaseAdditions)

- (void) _updateSceneBounds
{
    [self setSize: [[BRDisplayManager sharedInstance] renderingSize]];
	
    NSRect frame = [self interfaceFrame];
    [[BRThemeInfo sharedTheme] setSize: frame.size];
}

- (void) _updateScaling
{
    CGLContextObj ctx = [_context CGLContext];
    BRDisplayManager * mgr = [BRDisplayManager sharedInstance];
	
    if ( [mgr needsGLUpscaling] )
    {
        int glsize[2];
        NSSize size = [mgr renderingSize];
		
        glsize[0] = (int) size.width;
        glsize[1] = (int) size.height;
		
        CGLSetParameter( ctx, kCGLCPSurfaceBackingSize, (long *)glsize );
        CGLEnable( ctx, kCGLCESurfaceBackingSize );
		
        //NSLog( @"BRRenderScene: Upscale requested" );
    }
    else
    {
        //NSLog( @"BRRenderScene: No upscale requested" );
    }
}

- (BOOL) _attachDrawableContext
{
    BRDisplayManager * mgr = [BRDisplayManager sharedInstance];
    if ( [mgr displayOnline] == NO )
        return ( NO );
	
    //NSLog( @"BRRenderScene: attach drawable context" );
	
    BRRenderPixelFormat * format = [BRRenderPixelFormat doubleBufferedWithDisplay: [mgr display]];
    if ( format == nil )
    {
		//  NSLog( @"BRRenderScene: unable to create pixel format" );
        return ( NO );
    }
	
    _context = [[BRRenderContext alloc] initWithPixelFormat: format
                                              sharedContext: [self persistentContext]];
    if ( _context == nil )
    {
        //NSLog( @"BRRenderScene: Unable to create render context" );
        return ( NO );
    }
	
    [self _updateScaling];
    [self setDrawableContext: _context];
	
    [mgr captureAllDisplays];
    CGLError err = CGLSetFullScreen( [_context CGLContext] );
    if ( err != 0 )
    {
        //NSLog( @"BRRenderScene: Unable to set context fullscreen> Err = %ld",err );
        return ( NO );
    }
	
    [self _updateSceneBounds];
    //[_scene renderScene];
	
    CGDisplayHideCursor( [mgr display] );
	return YES;
}

- (BRRenderContext *) context
{
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_context");
	
	return *(BRRenderContext * *)(((char *)self)+ret->ivar_offset);
}

@end

@implementation CMPScreenReleaseAction

- (BOOL)releaseAllDisplaysWithoutFadeWithError:(NSError **)error
{ 
	if ([CMPATVVersion atvVersion] >= CMPATVVersion3)
	{
		if (CGReleaseAllDisplays() != kCGErrorSuccess) {
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"Couldn't release the display", @"Couldn't release the display error message"), NSLocalizedDescriptionKey,
																				  nil]];			
			return NO;
		} 
		return YES;
	}
	
	CGLContextObj ctx = CGLGetCurrentContext();
//	CGLError clearDraw = CGLClearDrawable(ctx); 
//	CGLError destroyCntx = CGLDestroyContext(ctx); 
//	CGLError nullContext = CGLSetCurrentContext(NULL);
	CGLClearDrawable(ctx); 
	CGLDestroyContext(ctx); 
	CGLSetCurrentContext(NULL);
	
	if (CGReleaseAllDisplays() != kCGErrorSuccess) {
		if(error)
			*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			  BRLocalizedString(@"Couldn't release the display", @"Couldn't release the display error message"), NSLocalizedDescriptionKey,
																			  nil]];			
		return NO;
	}
	
	return YES;
}

- (BOOL)shouldGoOffline
{
	
	if ([[BRDisplayManager sharedInstance] interlaced])
		return NO;
//	CGDirectDisplayID theDisplay = [[BRDisplayManager sharedInstance] display];
//	boolean_t captured = CGDisplayIsCaptured(theDisplay);
//	NSLog(@"CGDisplayIsCaptured: %d", captured);
	
	if (![[BRDisplayManager sharedInstance] displayOnline])
	{
		NSLog(@"display already offline, returning");
		return NO;
	}
	
	
	//NSDictionary *currentDisplayMode = [[BRDisplayManager sharedInstance] displayMode];
	NSDictionary *currentDisplayMode = nil;
	if ([CMPATVVersion atvVersion] >= CMPATVVersion3)
	{
		currentDisplayMode = [[[BRDisplayManager sharedInstance] displayMode] modeDictionary];
	} else {
		currentDisplayMode = [[BRDisplayManager sharedInstance] displayMode];
	}
	//NSLog(@"currentDisplayMode: %@", currentDisplayMode);
	int currentHeight = [[currentDisplayMode valueForKey:@"Height"] intValue];
	if (currentHeight >= 720)
		return YES;
	else
		return NO;
	return NO;
}

- (void) goOffline
{
	if ([CMPATVVersion usingLeopard])
		return;
	Class cls = NSClassFromString(@"BRRenderScene");
	if (cls != nil)
	{
		BRRenderScene* scene = [BRRenderScene singleton];
		//NSLog(@"current scene: %@ root: %@", scene, [scene root]);
		CGLContextObj ctx2 = [[scene context] CGLContext];
		CGLClearDrawable( ctx2 ); 
	} else {
		
		if ([CMPATVVersion atvVersion] >= CMPATVVersion3)
		{
			BRRenderer *theRender = [BRRenderer singleton];
			//s_renderer = [theRender renderer];
			//[theRender setRenderer:nil];
			CGLContextObj ctx = [[theRender context] CGLContext];
			CGLClearDrawable( ctx ); 
		}
		
	}
}

- (void)disableScreenSaver
{
	Class cls = NSClassFromString(@"ATVScreenSaverManager");
	if(cls != nil)
	{
		Class cls2 = NSClassFromString(@"ATVSettingsFacade");
		
		screensaverTimeout = [[cls2 singleton] screenSaverTimeout];
		[[cls2 singleton] setScreenSaverTimeout:-1];
		[[cls singleton] _updateActivity:nil];
	}
	else if(cls == nil)
	{
		cls = NSClassFromString(@"BRScreenSaverManager");
		if(cls != nil)
		{
			screensaverTimeout = [[BRSettingsFacade settingsFacade] screenSaverTimeout];
			[[BRSettingsFacade settingsFacade] setScreenSaverTimeout:-1];
		}
	}
}

- (void)captureAllDisplays
{
	BRDisplayManager *shared = [BRDisplayManager sharedInstance];
	CGDirectDisplayID display = [[BRDisplayManager sharedInstance] display];
	if([shared respondsToSelector:@selector(_updateDisplayInfo)])
	{
		if([self shouldGoOffline])
		{
			BRRenderer *theRender = [BRRenderer singleton];
			
			BRRenderDisplayLink *theLink = [theRender link];
			id theTarget = [theRender target];
			[theLink setLinkRunning:YES];
			[theTarget startRenderingOnDisplay:display];
		}
	}
	[shared captureAllDisplays];
	if([CMPATVVersion usingLeopard])
		[[[[NSClassFromString(@"BRSentinel") sharedInstance] rendererProvider] renderer] orderIn];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerConfigurationEnd" object: [BRDisplayManager sharedInstance]];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"BRDisplayManagerDisplayChanged" object: [BRDisplayManager sharedInstance]];
	
	CGError cgErr = CGDisplayCaptureWithOptions(display, 6);
    if (cgErr != noErr)
    {
        //NSLog(@"DRDisplayManager: CGDisplayCaptureWithOptions failed (err = %ld). Trying CGCaptureAllDisplays", cgErr );
        cgErr = CGCaptureAllDisplays();
//        if (cgErr == noErr)
//        {
//            NSLog(@"BRDisplayManager: CGCaptureAllDisplays succeeded. Hotplug notifications are disabled (err = %ld)", noErr );
//        }
//        else
//        {
//            NSLog(@"BRDisplayManager: CGCaptureAllDisplays failed (err = %ld). Unable to capture the display.", cgErr );
//        }
    }
	
    cgErr = CGDisplayHideCursor(display);
    if (cgErr != noErr)
        NSLog(@"BRDisplayManager: Unable to hide cursor");
}

- (void)resetScreenSaver
{
	Class cls = NSClassFromString(@"ATVScreenSaverManager");
	if(cls != nil)
	{
		Class cls2 = NSClassFromString(@"ATVSettingsFacade");
		[[cls2 singleton] setScreenSaverTimeout:screensaverTimeout];
		[[cls singleton] _updateActivity:nil];
	}
	else if(cls == nil)
	{
		cls = NSClassFromString(@"BRScreenSaverManager");
		if(cls != nil)
		{
			[[BRSettingsFacade settingsFacade] setScreenSaverTimeout:screensaverTimeout];
			[[cls sharedInstance] updateActivity];
		}
	} 
}

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	return [super init];
}

- (BOOL)openWithError:(NSError **)error
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"BRDisplayManagerStopRenderingNotification" object: [BRDisplayManager sharedInstance]];
	
	BOOL success = [self releaseAllDisplaysWithoutFadeWithError:error];

	if(success && [self shouldGoOffline])
		[self goOffline];
	
	if(success)
		[self disableScreenSaver];
	
	return success;
}

- (BOOL)closeWithError:(NSError **)error
{
	[self captureAllDisplays];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"BRDisplayManagerResumeRenderingNotification" object: [BRDisplayManager sharedInstance]];
	if([CMPATVVersion atvVersion] < CMPATVVersion2Dot3 && ![CMPATVVersion usingLeopard])
	{
		BRRenderScene *theScene = [BRRenderScene singleton]; 
		[theScene _attachDrawableContext]; //for atv versions lower than 2.3 we have custom methods to detach and attach drawable contexts to circumvent well known screen release issues.
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"BRDisplayManagerRenderingSizeChanged" object: [BRDisplayManager sharedInstance]];
	}
	
	[self resetScreenSaver];
	
	return YES;
}

@end
