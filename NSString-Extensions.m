//
//  NSString-Extensions.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "NSString-Extensions.h"

@implementation NSString (PostStrings)
/*!
 * @brief URL encode a string
 *
 * @return A url encoded version of the string
 */
- (NSString *)URLEncode
{
	/*Create a new one using the CFURL function*/
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	/*Return it*/
	return [result autorelease];
}
@end
