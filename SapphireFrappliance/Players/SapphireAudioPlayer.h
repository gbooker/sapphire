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

@class QTMovie, SapphireAudioMedia;

/*!
 * @brief A player to playback an audio asset
 *
 * This class is designed to allow the playback of audio files.  Unlike with video, BackRow doesn't provide a class which will playback audio files for you, so this one is designed to provide the basic functionality.
 */

@interface SapphireAudioPlayer : BRMusicPlayer {
	QTMovie					*movie;				/*!< @brief The movie to play*/
	int						state;				/*!< @brief Our state machine, 0 for stopped, 1 for paused, 3 for playing*/
	NSTimer					*updateTimer;		/*!< @brief A timer to update the display (not retained)*/
	float					skipSpeed;			/*!< @brief Speed at which to skip around the audio track*/
	NSTimer					*skipTimer;			/*!< @brief A timer to reset do the actual skip (not retained)*/
	int						soundState;			/*!< @brief Sound state before we played the current file*/
	
	//Some media players are just stubs, so we override a lot of functionality here
	SapphireAudioMedia		*myMedia;			/*!< @brief The current media*/
	NSArray					*myTrackList;		/*!< @brief The current track list*/
}
@end

//From Apple's headers (nice of you to provide them)

// kBRMediaPlayerPlaybackProgressChanged is sent whenever the playback progress
// has changed. Be careful to not do too much during the handling of this
// notification because it can be sent often, e.g. 2x per second.
extern NSString* kBRMediaPlayerPlaybackProgressChanged;

// kBRMediaPlayerStateChanged is sent out whenever the player's state has
// changed. Note that this will be sent out both when the state is changed by
// an explicit call (i.e. fast forward, rewind) or automatically, such as when
// playback reaches the end of the media and stops.
extern NSString* kBRMediaPlayerStateChanged;

// kBRMediaPlayerCurrentAssetChanged is sent out whenever the current media
// asset has changed. This usually occurs as the result of a track change.
extern NSString* kBRMediaPlayerCurrentAssetChanged;

// kBRMediaPlayerPlaybackError is sent when a fatal error is encountered during
// playback. Playback can no longer proceed and the controller that instantiated
// the player should handle this accordingly. The actual NSError will be returned
// in the user info dictionary referenced by the kBRMediaPlayerPlaybackErrorErrorKey.
extern NSString* kBRMediaPlayerPlaybackError;

// kBRMediaPlayerVolumeChanged is sent when the volume has changed or tried
// to change.  E.g., if the volume gets incremented but was already at maximum, the notification
// still gets sent.
extern NSString* kBRMediaPlayerVolumeChanged;
