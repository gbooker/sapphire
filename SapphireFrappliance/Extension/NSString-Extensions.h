/*
 * NSString-Extensions.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 30, 2007.
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
 * @brief String extensions for posts
 *
 * This class provides a method to URL encode a string.
 */
@interface NSString (PostStrings)
/*!
 * @brief URL encode a string
 *
 * @return A url encoded version of the string
 */
- (NSString *)URLEncode;
@end

/*!
 * @brief String extensions for Replacements
 *
 * This class provides a method to replace one substring with another.
 */
@interface NSString (Replacements)
/*!
 * @brief Replace a substring in the current string with another string
 *
 * This method creates a mutable string, does the replacement there and returns a new string from the mutable string.
 *
 * @param search The search string
 * @param replacement The replacement string
 * @return The new string after all replacements
 */
- (NSString *)stringByReplacingAllOccurancesOf:(NSString *)search withString:(NSString *)replacement;

/*!
 * @brief Replace all -_. with spaces
 *
 * @return The cleaned string
 */
- (NSString *)searchCleanedString;
@end

@interface NSString (Additions)
/*!
 * @brief Crop a string (path) into something shorter
 *
 * This method creates a crops a string (path) if it is greater than the desired path component length
 *
 * @param directoryPath The path string
 * @param toLength The number of path components to return
 * @return The new string after cropping
 */
+ (NSString *)stringByCroppingDirectoryPath:(NSString *)directoryPath toLength:(int)requestedLength;

/*!
 * @brief Gives a time string for a given number of seconds
 *
 * @param seconds Number of second to turn into a string
 * @return The number of second in a string
 */
+ (NSString *)colonSeparatedTimeStringForSeconds:(int)seconds;

/*!
 * @brief Comparison for names
 *
 * @param other The other string to compare
 * @return The comparison result of the compare
 */
- (NSComparisonResult)nameCompare:(NSString *)other;
@end

/*!
 * @brief Mutable string extensions for Replacements
 *
 * This class provides a method to replace one substring with another.
 */
@interface NSMutableString (Replacements)
/*!
 * @brief Replace a substring in the current string with another string
 *
 * @param search The search string
 * @param replacement The replacement string
 */
- (void)replaceAllOccurancesOf:(NSString *)search withString:(NSString *)replacement;
@end
