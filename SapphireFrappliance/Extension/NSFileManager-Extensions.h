/*
 * NSFileManager-Extensions.h
 * Sapphire
 *
 * Created by Patrick Merrill on Dec. 09, 2007.
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
 * @brief File Manager extensions
 *
 * This class provides additional functionaly for NSFileManager
 */
@interface NSFileManager (SapphireExtensions)

/*!
 * @brief Returns all allowed video extensions
 *
 * @return All allowed video extensions
 */
+ (NSSet *)videoExtensions;

/*!
 * @brief Returns all allowed audio extensions
 *
 * @return All allowed audio extensions
 */
+ (NSSet *)audioExtensions;

/*!
 * @brief Construct the proposed directory path
 *
 * @param proposedPath The path
 * @return YES when made NO otherwise
 */
- (BOOL)constructPath:(NSString *)proposedPath;

/*!
 * @brief Returns whether the path contains a VIDEO_TS directory
 *
 * @param path The path to check
 * @return YES if it contains a VIDEO_TS dir, NO otherwise
 */
- (BOOL)hasVIDEO_TS:(NSString *)path;

/*!
 * @brief Returns whether the path exists and is a directory
 *
 * @param path The path to check
 * @return YES if it is a directory, NO otherwise
 */
- (BOOL)isDirectory:(NSString *)path;

/*!
 * @brief Returns whether a given path is acceptible for Sapphire's use
 *
 * @param path The path to check
 * @return YES if file can be played, NO otherwise
 */
- (BOOL)acceptFilePath:(NSString *)path;

/*!
 * @brief Returns the cover art path for a TV show & season
 *
 * @param[in] show      TV Show name
 * @param[in] seasonNum Season number
 *
 * @return cover art path
 */
+ (NSString *)previewArtPathForTV:(NSString *)show season:(unsigned int)seasonNum;
@end
