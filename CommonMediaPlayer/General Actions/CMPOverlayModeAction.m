/*
 * CMPOverlayModeAction.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 8 2010
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

#import "CMPOverlayModeAction.h"
#import "CMPATVVersion.h"
#import "CMPPlayerController.h"
#import "CoreGraphicsServices.h"

@interface NSObject (compat)
- (void)setOpacity:(float)opacity;
@end

@interface BRRenderScene (compat)
+ (BRRenderScene *)singleton;
- (void)setBackgroundRemoved:(BOOL)removed;
- (BRRenderContext *)drawableContext;

//Really BRRenderer
- (BRRenderContext *)persistentContext;
@end

@interface BRRenderer (compat)
//Not really a scene, but we can use it as such below
+ (BRRenderScene *)singleton;
@end


@interface BRRenderScene (propertyAccess)
- (BRRenderContext *)getContext;
@end

@implementation BRRenderScene (propertyAccess)

- (BRRenderContext *)getContext
{
	if([self respondsToSelector:@selector(drawableContext)])
		return [self drawableContext];
	
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_context");
	return *(BRRenderContext * *)(((char *)self)+ret->ivar_offset);
}

@end

@implementation BRRenderer (propertyAccess)

- (BRRenderContext *)getContext
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_context");
	return *(BRRenderContext * *)(((char *)self)+ret->ivar_offset);
}

@end

@implementation CMPOverlayModeAction

- (id)initWithController:(id <CMPPlayerController>)aController andSettings:(NSDictionary *)settings
{
	controller = [aController retain];
	return [super init];
}

- (void) dealloc
{
	[controller release];
	[super dealloc];
}

//int getMainWindowID()
//{
//	int windowCount = 0;
//	CGSGetOnScreenWindowCount(_CGSDefaultConnection(), 0, &windowCount);
//	NSLog(@"Found %d windows", windowCount);
//	
//	CGSWindowID ids[windowCount];
//	CGSGetOnScreenWindowList(_CGSDefaultConnection(), 0, windowCount, ids, &windowCount);
//	CGWindowLevel level, searchLevel = CGShieldingWindowLevel()+1;
//	int i, windowID = 0;
//	for(i=0; i<windowCount; i++)
//	{
//		CGSGetWindowLevel(_CGSDefaultConnection(), ids[i], &level);
//		NSLog(@"Window %d is at %d", ids[i], level);
//		if(level >= searchLevel)
//		{
//			NSLog(@"Found window %d/%d at level %d", ids[i], searchLevel, level);
//			windowID = ids[i];
//		}
//	}
//	
//	return windowID;
//}
//
- (BOOL)openWithError:(NSError **)error
{
//	BRRenderScene *scene;
//	CMPATVVersionValue version = [CMPATVVersion atvVersion];
//	if(version == CMPATVVersion1)
//		scene = [controller scene];
//	else if(version < CMPATVVersion3)
//		scene = [BRRenderScene singleton];
//	else
//		scene = [BRRenderer singleton];
//	
//	long opacity = NO;
//	if([scene respondsToSelector:@selector(setOpaque:)])
//		[scene setOpaque:NO];
//	if(version >= CMPATVVersion3)
//	{
//		id stackManager = [NSClassFromString(@"BRApplicationStackManager") singleton];
//		NSLog(@"stack manager is %@", stackManager);
//		id stackLayer = [[stackManager stack] layer];
//		NSLog(@"Stack layer is %@", stackLayer);
//		[stackLayer setOpacity:0.0f];
//		id window = [stackManager window];
//		NSLog(@"window is %@", window);
////		[window setIsOpaque:NO];
//		id content = [window content];
//		NSLog(@"content is %@", content);
//		id layer = [content layer];
//		NSLog(@"Layer is %@", layer);
//		[layer setOpaque:NO];
//		id rootlayer = [NSClassFromString(@"BRWindow") rootLayer];
//		NSLog(@"root layer is %@", rootlayer);
//		[rootlayer setOpacity:0.0f];
//		[rootlayer setOpaque:NO];
//		[rootlayer setBackgroundColor:BRThemeColorClear()];
//		CGReleaseAllDisplays();
//	}
//	if([scene respondsToSelector:@selector(setBackgroundRemoved:)])
//	   [scene setBackgroundRemoved:YES];
//	
//	windowID = getMainWindowID();
//	NSLog(@"Window is %d", windowID);
//	
//	CGSSetWindowOpacity(_CGSDefaultConnection(), windowID, 0);
//	CGLSetParameter([[scene getContext] CGLContext], kCGLCPSurfaceOpacity, &opacity);
//	NSLog(@"Done on %@", [scene getContext]);
//	
//	if([scene respondsToSelector:@selector(persistentContext)])
//	{	
//		CGLSetParameter([[scene persistentContext] CGLContext], kCGLCPSurfaceOpacity, &opacity);
//		NSLog(@"Done on %@", [scene persistentContext]);
//	}
	return YES;
}

- (BOOL)closeWithError:(NSError **)error
{
	return YES;
	
	BRRenderScene *scene;
	CMPATVVersionValue version = [CMPATVVersion atvVersion];
	if(version == CMPATVVersion1)
		scene = [controller scene];
	else if(version < CMPATVVersion3)
		scene = [BRRenderScene singleton];
	else
		scene = [BRRenderer singleton];
	
	long opacity = YES;
	if([scene respondsToSelector:@selector(setOpaque:)])
		[scene setOpaque:YES];
	if([scene respondsToSelector:@selector(setBackgroundRemoved:)])
		[scene setBackgroundRemoved:NO];
	if([scene respondsToSelector:@selector(persistentContext)])
		CGLSetParameter([[scene persistentContext] CGLContext], kCGLCPSurfaceOpacity, &opacity);
	
	CGSSetWindowOpacity(_CGSDefaultConnection(), windowID, 1);
	CGLSetParameter([[scene getContext] CGLContext], kCGLCPSurfaceOpacity, &opacity);
	
	return YES;
}


@end
