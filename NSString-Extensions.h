//
//  NSString-Extensions.h
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
