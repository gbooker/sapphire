/*
 * CMPATVVersion.m
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

#import "CMPATVVersion.h"

//Take 3 Remote Actions
enum {
	kBREventRemoteActionTake3TouchBegin = 29,
	kBREventRemoteActionTake3TouchMove,
	kBREventRemoteActionTake3TouchEnd,
	kBREventRemoteActionTake3SwipeLeft,
	kBREventRemoteActionTake3SwipeRight,
	kBREventRemoteActionTake3SwipeUp,
	kBREventRemoteActionTake3SwipeDown,
};

//Take 3.0.2 Remote Actions

enum {
	kBREventRemoteActionTake302TouchBegin = 30,
	kBREventRemoteActionTake302TouchMove,
	kBREventRemoteActionTake302TouchEnd,
	kBREventRemoteActionTake302SwipeLeft,
	kBREventRemoteActionTake302SwipeRight,
	kBREventRemoteActionTake302SwipeUp,
	kBREventRemoteActionTake302SwipeDown,
};


@implementation CMPATVVersion

static CMPATVVersionValue atvVersion = CMPATVVersionUnknown;
static BOOL usingLeopard = NO;
static BOOL usingATypeOfTakeTwo = NO;
static BOOL usingLeopardOrATypeOfTakeTwo = NO;
static BOOL usingATypeOfTakeThree = NO;

+ (void)initialize
{
	if(NSClassFromString(@"BRAdornedMenuItemLayer") == nil)
	{
		atvVersion = CMPATVVersionLeopardFrontrow;
		usingLeopard = YES;
		usingLeopardOrATypeOfTakeTwo = YES;
	}
	
	if(NSClassFromString(@"BRBaseAppliance") != nil)
	{
		atvVersion = CMPATVVersion2;
		usingLeopard = NO;
		usingATypeOfTakeTwo = YES;
	}
	
	if(NSClassFromString(@"BRVideoPlayerController") == nil)
		atvVersion = CMPATVVersion2Dot2;
	
	if([(Class)NSClassFromString(@"BRController") instancesRespondToSelector:@selector(wasExhumed)])
		atvVersion = CMPATVVersion2Dot3;
	
	if(NSClassFromString(@"BRPhotoImageProxy") != nil)
		atvVersion = CMPATVVersion2Dot4;
	
	if(NSClassFromString(@"BRFullscreenRenderTarget") != nil)
	{	
		atvVersion = CMPATVVersion3;
		usingATypeOfTakeThree = YES;
		NSDictionary *finderDict = [[NSBundle mainBundle] infoDictionary];
		NSString *theVersion = [finderDict objectForKey: @"CFBundleVersion"];
		//NSLog(@"appletversion: %@",  theVersion);
		
		NSComparisonResult theResult = [@"3.0.2" compare:theVersion options:NSNumericSearch];
		if ( theResult == NSOrderedAscending ){
			atvVersion = CMPATVVersion302;
		} else if ( theResult == NSOrderedSame ) {
			atvVersion = CMPATVVersion302;
		}
	}
}

+ (CMPATVVersionValue)atvVersion
{
	return atvVersion;
}

+ (BOOL)usingLeopard
{
	return usingLeopard;
}

+ (BOOL)usingATypeOfTakeTwo
{
	return usingATypeOfTakeTwo;
}

+ (BOOL)usingLeopardOrATypeOfTakeTwo
{
	return usingLeopardOrATypeOfTakeTwo;
}

+ (BOOL)usingFrontRow
{
	return atvVersion >= CMPATVVersionLeopardFrontrow;
}

+ (BOOL)usingTakeTwo
{
	return atvVersion >= CMPATVVersion2;
}

+ (BOOL)usingTakeTwoDotTwo
{
	return atvVersion >= CMPATVVersion2Dot2;
}

+ (BOOL)usingTakeTwoDotThree
{
	return atvVersion >= CMPATVVersion2Dot3;
}

+ (BOOL)usingTakeTwoDotFour
{
	return atvVersion >= CMPATVVersion2Dot4;
}

+ (BREventRemoteAction)remoteActionForEvent:(BREvent *)event
{
	if(atvVersion >= CMPATVVersion302)
	{
		BREventRemoteAction action = [event remoteAction];
		switch (action) {
			case kBREventRemoteActionTake302TouchEnd:
			case kBREventRemoteActionTake302SwipeLeft:
			case kBREventRemoteActionTake302SwipeRight:
			case kBREventRemoteActionTake302SwipeUp:
			case kBREventRemoteActionTake302SwipeDown:
				return action - 2;
				break;
			case kBREventRemoteActionTake302TouchBegin:
			case kBREventRemoteActionTake302TouchMove:
				return 0;
				break;
			default:
				return action;
				break;
		}
	}
	if(atvVersion >= CMPATVVersion3)
	{
		BREventRemoteAction action = [event remoteAction];
		switch (action) {
			case kBREventRemoteActionTake3TouchEnd:
			case kBREventRemoteActionTake3SwipeLeft:
			case kBREventRemoteActionTake3SwipeRight:
			case kBREventRemoteActionTake3SwipeUp:
			case kBREventRemoteActionTake3SwipeDown:
				return action - 1;
				break;
			default:
				return action;
				break;
		}
	}
	if(atvVersion >= CMPATVVersion2Dot4)
		return [event remoteAction];
	
	BREventPageUsageHash hashVal = (uint32_t)([event page] << 16 | [event usage]);
	switch (hashVal) {
		case kBREventTapMenu:
		case BREVENT_HASH(kBREventPageAdvanced, kBREventBasicMenu):
			return kBREventRemoteActionMenu;
		case kBREventTapPlayPause:
		case kBREventPlay:
		case kBREventPause:
		case kBREventHoldPlayPause:  //PlayPause Hold should never be actually sent, but front row seems to use it
			return kBREventRemoteActionPlay;
		case kBREventTapRight:
			return kBREventRemoteActionRight;
		case kBREventTapLeft:
			return kBREventRemoteActionLeft;
		case kBREventTapUp:
		case kBREventHoldUp:
			return kBREventRemoteActionUp;
		case kBREventTapDown:
		case kBREventHoldDown:
			return kBREventRemoteActionDown;
		case kBREventHoldMenu:
			return kBREventRemoteActionMenuHold;
		case kBREventHoldLeft:
			return kBREventRemoteActionHoldLeft;
		case kBREventHoldRight:
			return kBREventRemoteActionHoldRight;
			
			//Unknowns:
		case kBREventTapExit:
		case kBREventFastForward:
		case kBREventRewind:
		case kBREventNextTrack:
		case kBREventPreviousTrack:
		case kBREventStop:
		case kBREventEject:
		case kBREventRandomPlay:
		case kBREventVolumeUp:
		case kBREventVolumeDown:
			/* Commented out due to it throwing warnings
			 case kBREventPairRemote:
			 case kBREventUnpairRemote:
			 case kBREventLowBattery:
			 case kBREventSleepNow:
			 case kBREventSystemReset:
			 case kBREventBlackScreenRecovery:*/
		default:
			return 0;
	}
}

@end
