/*
 * CMPATVVersion.h
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

#import <Cocoa/Cocoa.h>

typedef enum {
	CMPATVVersionUnknown = 0,
	CMPATVVersion1 = 1,
	CMPATVVersionLeopardFrontrow,
	CMPATVVersion2,
	CMPATVVersion2Dot2,
	CMPATVVersion2Dot3,
	CMPATVVersion2Dot4,
	CMPATVVersion3,
	CMPATVVersion302,
} CMPATVVersionValue;

// Gesture events have a dictionary defining the touch points and other info.
typedef enum {
	kBREventOriginatorRemote = 1,
	kBREventOriginatorGesture = 3
} BREventOriginator;

typedef enum {
	// for originator kBREventOriginatorRemote
	kBREventRemoteActionMenu = 1,
	kBREventRemoteActionMenuHold,
	kBREventRemoteActionUp,
	kBREventRemoteActionDown,
	kBREventRemoteActionPlay,
	kBREventRemoteActionLeft,
	kBREventRemoteActionRight,
	
	kBREventRemoteActionPlayNew = 10,
	kBREventRemoteActionPlayHold = 20,
	
	// Gestures, for originator kBREventOriginatorGesture
	kBREventRemoteActionTap = 30,
	kBREventRemoteActionSwipeLeft,
	kBREventRemoteActionSwipeRight,
	kBREventRemoteActionSwipeUp,
	kBREventRemoteActionSwipeDown,
	
	// Custom remote actions for old remote actions
	kBREventRemoteActionHoldLeft = 0xfeed0001,
	kBREventRemoteActionHoldRight,
	kBREventRemoteActionHoldUp,
	kBREventRemoteActionHoldDown,
} BREventRemoteAction;

@interface CMPATVVersion : NSObject {
}

/*!
 * @brief Determine the ATV version
 *
 * @return The ATV Version
 */
+ (CMPATVVersionValue)atvVersion;

/*!
 * @brief Are we on a leopard machine?
 *
 * @return YES if on leopard, NO otherwise
 */
+ (BOOL)usingLeopard;

/*!
 * @brief Are we on a type of ATV Take Two?
 *
 * @return YES if on take two, NO otherwise
 */
+ (BOOL)usingATypeOfTakeTwo;

/*!
 * @brief Are we on leopard or a type of ATV Take Two?
 *
 * @return YES if on leopard or take 2, NO otherwise
 */
+ (BOOL)usingLeopardOrATypeOfTakeTwo;

/*!
 * @brief Get the remoteAction in a compatable way
 *
 * @param event The event for which to fetch the remote action
 * @return The remote action for the event
 */
+ (BREventRemoteAction)remoteActionForEvent:(BREvent *)event;

@end
