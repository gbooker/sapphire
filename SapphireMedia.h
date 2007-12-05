//
//  SapphireMedia.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//


/*!
 * @brief A media asset class to provied custom resume times and cover art
 *
 * This class is designed to allow the custom settings of resume time as well as a custom image path.  It extends from BRSimpleMediaAsset, so it can be used whenever a URL based asset is needed.
 */
@interface SapphireMedia : BRSimpleMediaAsset {
	unsigned int		resumeTime;		/*!< @brief The resume time to use, 0 to use super*/
	NSString			*imagePath;		/*!< @brief The cover art path to use, nil to use super*/
}

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

@end
