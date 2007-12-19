/*
 * SapphireVideoPlayer.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
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

@class SapphireFileMetaData;

/*!
 * @brief Part of the SapphireVideoPlayer state machine
 */
typedef enum{
	SKIP_STATE_NONE,				/*!< @brief No special state*/
	SKIP_STATE_FORWARD_INCREASING,	/*!< @brief Skipping forward at increasing speed*/
	SKIP_STATE_BACKWARD_INCREASING,	/*!< @brief Skipping backward at increasing speed*/
	SKIP_STATE_DECREASING,			/*!< @brief Skipping at decreasing speed*/
} SkipState;

/*!
 * @brief A subclass of BRQTKitVideoPlayer which provides extra functions
 *
 * This class is designed to improve the playback of video files.  BackRow's video player works well on its own, but this one adds custom skipping ability to allow the user to skip around in files in a much better manner.
 * 
 * If the file does not contain chapters, this class is enabled.  The first skip will skip 5 seconds, then 10, then 20, and so on in exponentially increasing order.  The moment the user skips in the opposite direction, the skip time decreases exponentially.
 */
@interface SapphireVideoPlayer : BRQTKitVideoPlayer {
	double					skipTime;		/*!< @brief Time by which next skip should advance/reverse*/
	SkipState				state;			/*!< @brief Current state we are in*/
	BOOL					enabled;		/*!< @brief YES if we are enabled, NO if we behave the same as the super class*/
	NSTimer					*resetTimer;	/*!< @brief Timer to reset our state machine to default (not retained)*/
	NSTimeInterval			duration;		/*!< @brief Total length of the movie*/
}

@end
