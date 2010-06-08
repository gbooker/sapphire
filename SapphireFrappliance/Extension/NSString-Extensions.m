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
	NSString *encoded = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, CFSTR(" "), CFSTR("?=&+"), kCFStringEncodingUTF8);
	/*Return it*/
	NSString *result = [encoded stringByReplacingAllOccurancesOf:@" " withString:@"+"];
	[encoded release];
	return result;
}
@end

@implementation NSString (Replacements)
- (NSString *)stringByReplacingAllOccurancesOf:(NSString *)search withString:(NSString *)replacement
{
	NSMutableString *mut = [[self mutableCopy] autorelease];
	[mut replaceAllOccurancesOf:search withString:replacement];
	return [NSString stringWithString:mut];
}

- (NSString *)searchCleanedString
{
	NSString *ret = [self stringByReplacingAllOccurancesOf:@"_" withString:@" "];
	ret = [ret stringByReplacingAllOccurancesOf:@"." withString:@" "];
	ret = [ret stringByReplacingAllOccurancesOf:@"-" withString:@" "];
	return ret;
}
@end

@implementation NSString (Additions)
+ (NSString *)stringByCroppingDirectoryPath:(NSString *)directoryPath toLength:(int)requestedLength
{
	int dirLength=[[directoryPath pathComponents] count];
	NSString *returnPath=directoryPath ;
	if(dirLength>requestedLength)
	{
		NSRange croppedRange;
		croppedRange.location=dirLength-requestedLength;
		croppedRange.length=requestedLength;
		returnPath=[NSString stringWithFormat:@" .../%@",[NSString pathWithComponents:[[directoryPath pathComponents] subarrayWithRange:croppedRange]]];
	}
	return returnPath;
}

+ (NSString *)colonSeparatedTimeStringForSeconds:(int)seconds
{
	int secs = seconds % 60;
	int mins = (seconds /60) % 60;
	int hours = seconds / 3600;
	NSString *durationStr = nil;
	if(hours != 0)
		durationStr = [NSString stringWithFormat:@"%d:%02d:%02d", hours, mins, secs];
	else if (mins != 0)
		durationStr = [NSString stringWithFormat:@"%d:%02d", mins, secs];
	else
		durationStr = [NSString stringWithFormat:@"%ds", secs];
	return durationStr;
}

- (NSComparisonResult)nameCompare:(NSString *)other
{
	NSString *myShortenedName=nil ;
	NSString *otherShortenedName=nil ;
	/* Make sure we get titles leading with "A" & "The" where the belong */
	if([[self lowercaseString] hasPrefix:@"a "] && [self length]>2)
		myShortenedName=[self substringFromIndex:2];
	else if([[self lowercaseString] hasPrefix:@"the "] && [self length]>4)
		myShortenedName=[self substringFromIndex:4];
	if([[other lowercaseString] hasPrefix:@"a "]&& [other length]>2)
		otherShortenedName=[other substringFromIndex:2];
	else if([[other lowercaseString] hasPrefix:@"the "] && [other length]>4)
		otherShortenedName=[other substringFromIndex:4];
	
	if(myShortenedName==nil)
		myShortenedName=self;
	if(otherShortenedName==nil)
		otherShortenedName=other;
	
	return [myShortenedName	compare:otherShortenedName options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end


@implementation NSMutableString (Replacements)
- (void)replaceAllOccurancesOf:(NSString *)search withString:(NSString *)replacement
{
	[self replaceOccurrencesOfString:search withString:replacement options:0 range:NSMakeRange(0, [self length])];
}
@end
