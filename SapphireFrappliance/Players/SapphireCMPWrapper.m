/*
 * SapphireCMPWrapper.m
 * Sapphire
 *
 * Created by Graham Booker on Feb. 3, 2010.
 * Copyright 2010 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireCMPWrapper.h"
#import <CommonMediaPlayer/CMPPlayerManager.h>
#import "SapphireFileMetaData.h"
#import "SapphireMetaDataSupport.h"

@implementation SapphireCMPWrapper

- (id)initWithFile:(SapphireFileMetaData *)aFile scene:(BRRenderScene *)scene
{
	self = [super init];
	if(!self)
		return self;
	
	file = [aFile retain];
	FileContainerType fileContainerType = aFile.fileContainerTypeValue;
	CMPPlayerManagerFileType playerType = CMPPlayerManagerFileTypeQTCompatibleVideo;
	if(fileContainerType == FILE_CONTAINER_TYPE_VIDEO_TS)
		playerType = CMPPlayerManagerFileTypeVideo_TS;
	
	CMPPlayerManager *playerManager = [CMPPlayerManager sharedPlayerManager];
	id <CMPPlayer> player = [playerManager playerForPath:aFile.path type:playerType preferences:nil];
	
	controller = [[playerManager playerControllerForPlayer:player scene:scene preferences:nil] retain];
	NSNumber *resumeTime = file.resumeTime;
	if(resumeTime != nil)
	{
		NSDictionary *settings = [NSDictionary dictionaryWithObject:resumeTime forKey:CMPPlayerResumeTimeKey];
		[controller setPlaybackSettings:settings];
	}
	[controller setPlaybackDelegate:self];

	return self;
}

- (void) dealloc
{
	[file release];
	[controller release];
	[super dealloc];
}

- (id)controller
{
	return controller;
}

- (void)controller:(id <CMPPlayerController>)controller didEndWithSettings:(NSDictionary *)settings
{
	NSNumber *elapsedNumber = [settings objectForKey:CMPPlayerResumeTimeKey];
	NSNumber *durationNumber = [settings objectForKey:CMPPlayerDurationTimeKey];
	
	if(elapsedNumber != nil && durationNumber != nil)
	{
		float elapsed = [elapsedNumber floatValue];
		float duration = [durationNumber floatValue];
		if(duration == 0.0f)
			elapsed = duration = 1.0f;
		
		/*Get the resume time to save*/
		if(elapsed < duration - 2)
			[file setResumeTimeValue:elapsed];
		else
			[file setResumeTime:nil];
		
		if(elapsed / duration > 0.9f)
		/*Mark as watched and reload info*/
			[file setWatchedValue:YES];
		[SapphireMetaDataSupport save:[file managedObjectContext]];
	}
}

- (NSDictionary *)controllerInfo
{
	return nil;
}

@end
