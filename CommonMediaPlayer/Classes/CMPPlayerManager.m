/*
 * CMPPlayerManager.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 1 2010
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

#import "CMPPlayerManager.h"
#import "CMPBaseMediaAsset.h"
#import "CMPDVDPlayer.h"
#import "CMPDVDPlayerController.h"
#import "CMPLeopardDVDPlayer.h"
#import "CMPLeopardDVDPlayerController.h"
#import "CMPISODVDPlayer.h"
@implementation CMPPlayerManager

+ (CMPPlayerManager *)sharedPlayerManager
{
	CMPPlayerManager *shared = nil;
	if(shared == nil)
		shared = [[CMPPlayerManager alloc] init];
	
	return shared;
}

- (id) init
{
	self = [super init];
	if (self == nil)
		return self;
	
	knownPlayers = [[NSMutableSet alloc] init];
	knownControllers = [[NSMutableSet alloc] init];
	playersForTypes = [[NSMutableDictionary alloc] init];
	controllersForPlayerTypes = [[NSMutableDictionary alloc] init];
	
	[knownPlayers addObject:[CMPDVDPlayer class]];
	[knownPlayers addObject:[CMPISODVDPlayer class]];
	[knownControllers addObject:[CMPDVDPlayerController class]];
//	[knownPlayers addObject:[CMPLeopardDVDPlayer class]];
//	[knownControllers addObject:[CMPLeopardDVDPlayerController class]];
	
	NSMutableArray *dvdPlayers = [[NSMutableArray alloc] initWithObjects:/*[CMPLeopardDVDPlayer class], */[CMPDVDPlayer class], nil];
	NSMutableDictionary *dvdPlayerTypes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										   dvdPlayers, @"",
										   nil];
	[playersForTypes setObject:dvdPlayerTypes forKey:[NSNumber numberWithInt:CMPPlayerManagerFileTypeVideo_TS]];
	[dvdPlayerTypes release];
	[dvdPlayers release];
	
	
	NSMutableArray *isoPlayers = [[NSMutableArray alloc] initWithObjects:[CMPISODVDPlayer class], nil];
	NSMutableDictionary *isoPlayerTypes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										   isoPlayers, @"",
										   nil];
	
	[playersForTypes setObject:isoPlayerTypes forKey:[NSNumber numberWithInt:CMPPlayerManagerFileTypeDVDImage]];
	
	[playersForTypes setObject:isoPlayerTypes forKey:@"iso"];
	[playersForTypes setObject:isoPlayerTypes forKey:@"dmg"];
	[playersForTypes setObject:isoPlayerTypes forKey:@"img"];
	[isoPlayerTypes release];
	[isoPlayers release];
	
	return self;
}

- (void) dealloc
{
	[knownPlayers release];
	[knownControllers release];
	[playersForTypes release];
	[controllersForPlayerTypes release];
	[super dealloc];
}


- (void)registerPlayer:(Class)player forTypes:(NSDictionary *)types
{
	
}

- (id <CMPPlayer>)playerForPath:(NSString *)path type:(CMPPlayerManagerFileType)type preferences:(NSDictionary *)preferences
{
	NSString *ext = [path pathExtension];
	NSMutableArray *players = [[NSMutableArray alloc] init];
	
	NSDictionary *playersForExtension = [playersForTypes objectForKey:[NSNumber numberWithInt:type]];
	if([ext length])
	{
		NSArray *specificPlayers = [playersForExtension objectForKey:[ext lowercaseString]];
		if([specificPlayers count])
			[players addObjectsFromArray:specificPlayers];
	}
	NSArray *genericPlayers = [playersForExtension objectForKey:@""];
	if([genericPlayers count])
		[players addObjectsFromArray:genericPlayers];

	NSLog(@"List of players is %@", players);
	NSEnumerator *playerEnum = [players objectEnumerator];
	Class playerClass;
	id <CMPPlayer> player = nil;
	while((playerClass = [playerEnum nextObject]) != nil)
	{
		player = [[playerClass alloc] init];
		
		NSLog(@"Testing %@", player);
		BOOL canPlay = [player canPlay:path withError:nil];
		NSLog(@"can play is %d", canPlay);
		if(canPlay)
		{
			CMPBaseMediaAsset *asset = [[CMPBaseMediaAsset alloc] initWithMediaURL:[NSURL fileURLWithPath:path]];
			canPlay &= [player setMedia:asset error:nil];
			NSLog(@"Set asset is %d", canPlay);
			[asset release];
		}
		if(canPlay)
		{
			NSLog(@"Using Player");
			[player retain];
			break;
		}
		
		[player release];
		player = nil;
	}
	
	[players release];
	
	return [player autorelease];
}

- (id <CMPPlayerController>)playerControllerForPlayer:(id <CMPPlayer>)player scene:(BRRenderScene *)scene preferences:(NSDictionary *)preferences
{
	NSMutableSet *goodControllers = [[NSMutableSet alloc] init];
	NSSet *playersControllers = [[player class] knownControllers];
	if([playersControllers count])
		[goodControllers unionSet:playersControllers];
	
	NSEnumerator *controllerEnum = [knownControllers objectEnumerator];
	Class <CMPPlayerController> controllerClass;
	while((controllerClass = [controllerEnum nextObject]) != nil)
	{
		if([[controllerClass knownPlayers] containsObject:[player class]])
			[goodControllers addObject:controllerClass];
	}
	
	NSLog(@"Controllers is %@", goodControllers);
	
	//XXX Prefs
	id <CMPPlayerController> controller = [[(Class)[goodControllers anyObject] alloc] initWithScene:scene player:player];
	return [controller autorelease];
}

@end