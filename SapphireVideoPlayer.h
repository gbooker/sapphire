//
//  SapphireVideoPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
