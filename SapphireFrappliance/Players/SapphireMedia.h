/*
 * SapphireMedia.h
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


/*!
 * @brief A media asset class to provied custom resume times and cover art
 *
 * This class is designed to allow the custom settings of resume time as well as a custom image path.  It extends from BRSimpleMediaAsset, so it can be used whenever a URL based asset is needed.
 */
@interface SapphireMedia : BRXMLMediaAsset {
	unsigned int		resumeTime;		/*!< @brief The resume time to use, 0 to use super*/
	NSString			*imagePath;		/*!< @brief The cover art path to use, nil to use super*/
	NSImage				*coverart;		/*!< @brief The cover art as image data */
}

/*!
 * @brief Creates a media with a URL. Compatibility with old calling mechanism
 *
 * @param url The url to use for this media.
 * @return The media
 */
- (id)initWithMediaURL:(NSURL *)url;

/*!
 * @brief Set the resume time for the media
 *
 * @param time the time at which to resume
 */
- (void)setResumeTime:(unsigned int)time;

/*!
 * @brief Sets the image path for cover art so it can be displayed
 *
 * param path The path to the cover art
 */
- (void)setImagePath:(NSString *)path;

/*!
 * @brief Sets the image for cover art so it can be displayed
 *
 * param[in] image The cover art as an NSImage object
 */
- (void)setImage:(NSImage *)image;

@end
