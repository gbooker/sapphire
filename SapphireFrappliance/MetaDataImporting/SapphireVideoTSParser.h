/*
 * SapphireVideoTsParser.h
 * Sapphire
 *
 * Created by Warren Gavin on May. 7, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

@interface SapphireVideoTsParser : NSObject {
	NSFileHandle   *ifo;

	NSString *video;
	NSString *audio;
	NSString *subtitles;
	long long       duration;
	NSNumber *size;
}

/*!
 * @brief Creates a new parser for the DVD information stored in a VIDEO_TS folder
 *
 * This will read the IFO file for the main title in VIDEO_TS and gather
 * information about the video track, film duration, supported audio tracks and subtitles.
 *
 * @param[in] path   Location of ripped DVD folder
 * @return           The VIDEO_TS parser
 */
- (id) initWithPath: (NSString *)path;

/*!
 * @brief Returns the video attributes of the ripped DVD
 *
 * Video attributes are specified in two bytes starting at offset 0x200 in the IFO file.
 *
 * @return Video attributes in the form "<Coding-Mode>, NTSC/PAL, <Resolution> (<Aspect ratio>)".
 */
- (NSString * const) videoFormatsString;

/*!
 * @brief Returns the audio attributes of the ripped DVD
 *
 * Audio attributes are specified in eight bytes and a maximum of 8 audio tracks may be present.
 * The number of audio attributes blocks is specified as a 16 bit integer (Big Endian) at offset 0x202.
 * The audio attributes are stored in a 8x8 block at offset 0x204.
 *
 * This will not report audio tracks such as commentaries, only the main audio.
 *
 * @return Audio attributes in the form "<Lang1> [-DTS] [(Surround)], <Lang2> [-DTS] [(Surround)], ..."
 */
- (NSString * const) audioFormatsString;

/*!
 * @brief Returns the supported subtitles of the ripped DVD
 *
 * Subtitle attributes are specified in 32 six-byte blocks starting at offset 0x256 in the IFO file.
 * The number of subtitle attributes blocks is specified as a 16 bit integer (Big Endian) at offset 0x254.
 *
 * This will not report subtitles such as commentaries, only the main audio subtitles.
 *
 * @return A comma separated list of each supported subtitle (except duplicates)
 */
- (NSString * const) subtitlesString;

/*!
 * @brief Return the running time of a ripped DVD
 *
 * Duration means main feature time for a ripped film, or totalled episode time for TV series disc.
 *
 * @return  Calculated DVD running time
 */
- (NSNumber * const) mainFeatureDuration;

/*!
 * @brief Return the size of a ripped DVD
 *
 * @return  Calculated DVD size
 */
- (NSNumber * const) totalSize;

@end
