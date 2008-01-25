/*
 * SapphireAudioPlayer.h
 * Sapphire
 *
 * Created by Graham Booker on Jul. 28, 2007.
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
