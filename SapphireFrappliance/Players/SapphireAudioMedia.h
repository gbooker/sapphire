/*
 * SapphireAudioMedia.h
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

#import "SapphireMedia.h"

/*!
 * @brief A media asset class designed to play back audio files
 *
 * This class is designed to allow the playback of audio files.  It contains some cover art, and a QTMovie to perform the actual playback.  The QTMovie is played to produce the audio since BackRow doesn't provied the means to do this on its own.
 */

@class SapphireFileMetaData;

@interface SapphireAudioMedia : SapphireMedia {
	QTMovie					*movie;		/*!< @brief The movie to play*/
	id						coverArt;	/*!< @brief The cover art to display*/
	SapphireFileMetaData	*file;		/*!< @brief The current file*/
}
/*!
 * @brief Sets the movie for this asset to play
 *
 * The media asset requires a QTMovie object of the audio to play
 */
- (void)setMovie:(QTMovie *)newMovie;

/*!
 * @brief Sets the current file metedata
 *
 * @param Meta The current metadata
 */
- (void)setFileMetaData:(SapphireFileMetaData *)meta;

/*!
 * @brief Gets the current file metedata
 *
 * @return The current metadata
 */
- (SapphireFileMetaData *)fileMetaData;

@end
