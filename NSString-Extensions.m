//
//  NSString-Extensions.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
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

@implementation NSString (Replacements)
- (NSString *)stringByReplacingAllOccurancesOf:(NSString *)search withString:(NSString *)replacement
{
	NSMutableString *mut = [[self mutableCopy] autorelease];
	[mut replaceAllOccurancesOf:search withString:replacement];
	return [NSString stringWithString:mut];
}
@end

@implementation NSMutableString (Replacements)
- (void)replaceAllOccurancesOf:(NSString *)search withString:(NSString *)replacement
{
	[self replaceOccurrencesOfString:search withString:replacement options:0 range:NSMakeRange(0, [self length])];
}
@end
