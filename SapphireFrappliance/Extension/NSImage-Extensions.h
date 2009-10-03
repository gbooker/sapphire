/*
 * NSImage-Extensions.h
 * Sapphire
 *
 * Created by Warren Gavin on April. 15, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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
 * @brief Image extensions for QT screen caps
 */
@interface NSImage (SapphireExtensions)

/*!
* @brief Get an image from a movie located at a specified path
 *
 * @param[in] path  Location of movie
 *
 * @return          JPG image as a NSData object, or nil if there is no movie
 */
+ (NSData *) imageFromMovie: (NSString *)path;

/*!
 * @brief Get an image at a certain time from a movie located at a specified path
 *
 * @param[in] path     Location of movie
 * @param[in] instant  Time at which to grab the image, specified in seconds
 *
 * @return          JPG image as a NSData object, or nil if there is no movie
 */
+ (NSData *) imageFromMovie: (NSString *)path atTime: (unsigned int)instant;

/*!
 * @brief Get an array of random images from a movie
 *
 * @param[in] path  Location of movie
 * @param[in] size  Number of images requested
 *
 * @return          An array of NSImage objects, or nil if there is no movie
 */
+ (NSArray *) imagesFromMovie: (NSString *)path forArraySize: (unsigned int) size;

/*!
 * @brief Convert NSImage data to CGImageRef
 */
- (CGImageRef) newImageRef;

/*!
 * @brief writes image data to a file as JPG
 *
 * @param[in] path		Location to save image
 * @praam[in] atomic	YES if image should be writen atomicly
 */
- (BOOL) writeToFile:(NSString *)path atomically:(BOOL)atomic;
@end
