//
//  NSString-Extensions.m
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString-Extensions.h"

@implementation NSString (PostStrings)
- (NSString *)URLEncode
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return [result autorelease];
}
@end
