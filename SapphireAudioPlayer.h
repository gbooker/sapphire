//
//  SapphireAudioPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@class QTMovie;

/*!
 * @brief A player to playback an audio asset
 *
 * This class is designed to allow the playback of audio files.  Unlike with video, BackRow doesn't provide a class which will playback audio files for you, so this one is designed to provide the basic functionality.
 */

@interface SapphireAudioPlayer : BRMusicPlayer {
	QTMovie		*movie;				/*!< @brief The movie to play*/
	int			state;				/*!< @brief Our state machine, 0 for stopped, 1 for paused, 3 for playing*/
	NSTimer		*updateTimer;		/*!< @brief A timer to update the display (not retained)*/
	float		skipSpeed;			/*!< @brief Speed at which to skip around the audio track*/
	NSTimer		*skipTimer;			/*!< @brief A timer to reset do the actual skip (not retained)*/
}

@end
