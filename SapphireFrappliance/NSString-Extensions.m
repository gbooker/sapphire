/*
 * NSString-Extensions.m
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

#import "NSString-Extensions.h"

@implementation NSString (PostStrings)
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

@implementation NSString (Additions)
+ (NSString *)stringByCroppingDirectoryPath:(NSString *)directoryPath toLength:(int)requestedLength
{
	int dirLength=[[directoryPath pathComponents] count];
	NSString *returnPath=directoryPath ;
	if(dirLength>requestedLength)
	{
		NSLog(@"Directory %@ is %d - req %d",directoryPath, dirLength,requestedLength);
		NSRange croppedRange;
		croppedRange.location=dirLength-requestedLength;
		croppedRange.length=requestedLength;
		returnPath=[NSString stringWithFormat:@" ../%@/",[NSString pathWithComponents:[[directoryPath pathComponents] subarrayWithRange:croppedRange]]];
	}
	return returnPath;
}
@end


@implementation NSMutableString (Replacements)
- (void)replaceAllOccurancesOf:(NSString *)search withString:(NSString *)replacement
{
	[self replaceOccurrencesOfString:search withString:replacement options:0 range:NSMakeRange(0, [self length])];
}
@end
