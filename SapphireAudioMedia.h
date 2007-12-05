//
//  SapphireAudioMedia.h
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMedia.h"

/*!
 * @brief A media asset class designed to play back audio files
 *
 * This class is designed to allow the playback of audio files.  It contains some cover art, and a QTMovie to perform the actual playback.  The QTMovie is played to produce the audio since BackRow doesn't provied the means to do this on its own.
 */

@interface SapphireAudioMedia : SapphireMedia {
	QTMovie		*movie;		/*!< @brief The movie to play*/
	CGImageRef	coverArt;	/*!< @brief The cover art to display*/
}
/*!
 * @brief Sets the movie for this asset to play
 *
 * The media asset requires a QTMovie object of the audio to play
 */
- (void)setMovie:(QTMovie *)newMovie;

@end
