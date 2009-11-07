/*
 * SapphireAudioNowPlayingController.m
 * Sapphire
 *
 * Created by Graham Booker on Aug. 22, 2009.
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

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireAudioNowPlayingController.h"

#import <objc/objc-class.h>

@interface BRMusicNowPlayingControl <NSObject>
@end

@interface BRMediaPlayerEventHandler <NSObject>
@end

@interface BRMusicNowPlayingControl (compat)
+(id)control;
-(void)setFrame:(NSRect)frame;
-(void)setPlayer:(BRMusicPlayer *)player;
@end

@interface BRMediaPlayerEventHandler (compat)
+(BRMediaPlayerEventHandler *)handlerWithPlayer:(id)fp8;
-(BOOL)brEventAction:(id)fp8;
@end

@interface BRLayerController (compat)
- (void)setLayoutManager:(id)manager;
@end


@interface BRMusicNowPlayingControl (bypassAccess)
-(void)setPlayerThroughDirectAccess:(BRMusicPlayer *)player;
-(BRMusicPlayer *)getPlayerThroughDirectAccess;
@end

@implementation BRMusicNowPlayingControl (bypassAccess)
- (void)setPlayerThroughDirectAccess:(BRMusicPlayer *)player
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	BRMusicPlayer * *thePlayer = (BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
	
	[*thePlayer release];
	*thePlayer = [player retain];
}

- (BRMusicPlayer *)getPlayerThroughDirectAccess
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	return *(BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
}
@end

@implementation BRMusicNowPlayingController (bypassAccess)
- (void)setPlayer:(BRMusicPlayer *)player
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	BRMusicPlayer * *thePlayer = (BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
	
	[*thePlayer release];
	*thePlayer = [player retain];
}

- (BRMusicPlayer *)player
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	return *(BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
}

@end

@implementation SapphireAudioNowPlayingController

- (id)init
{
	self = [super init];
	if (self == nil)
		return nil;
	
	nowPlayingControl = [[BRMusicNowPlayingControl control] retain];
	[self addControl:nowPlayingControl];
	
	if([[BRLayerController class] instancesRespondToSelector:@selector(layoutManager)])
		[self setLayoutManager:self];
	
	return self;
}


- (id)initWithPlayer:(BRMusicPlayer *)newPlayer
{
	self = [self init];
	
	[self setPlayer:newPlayer];
	
	return self;
}

- (void) dealloc
{
	[player release];
	[nowPlayingControl release];
	[eventHandler release];
	[super dealloc];
}


- (void)setPlayer:(BRMusicPlayer *)newPlayer
{
	[player release];
	player = [newPlayer retain];
	
	if([nowPlayingControl respondsToSelector:@selector(setPlayer:)])
		[nowPlayingControl setPlayer:newPlayer];
	else
		[nowPlayingControl setPlayerThroughDirectAccess:newPlayer];
	
	[eventHandler release];
	if(NSClassFromString(@"BRMediaPlayerEventHandler") != nil)
		eventHandler = [[BRMediaPlayerEventHandler handlerWithPlayer:newPlayer] retain];
	else
		eventHandler = nil;
}

- (BRMusicPlayer *)player
{
	return player;
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventRemoteAction remoteAction = [event remoteAction];
	if(remoteAction == kBREventRemoteActionMenu)
	{
		[[self stack] popController];
		return YES;
	}
	else if(remoteAction == kBREventRemoteActionMenuHold)
	{
		[player stop];
		return YES;
	}
	else if(eventHandler != nil)
		return [eventHandler brEventAction:event];
	else
		return [super brEventAction:event];
}

- (void)layoutSublayers
{
	[nowPlayingControl setFrame:[SapphireFrontRowCompat frameOfController:self]];
}

- (void)layoutSublayersOfLayer:(id)layer
{
	[self layoutSublayers];
}

//ATV 3
- (void)layoutSubcontrols
{
	[self layoutSublayers];
}

@end
