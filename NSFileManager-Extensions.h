//
//  NSFileManager-Extensions.h
//  Sapphire
//
//  Created by Patrick Merrill on 12/09/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

/*!
 * @brief String extensions for posts
 *
 * This class provides a method to URL encode a string.
 */
@interface NSFileManager (CollectionArtPaths)
/*!
 * @brief construct the proposed directory path
 *
 * @param proposedPath
 * @return YES when made NO otherwise ?
 */
- (BOOL)constructPath:(NSString *)proposedPath;
@end

