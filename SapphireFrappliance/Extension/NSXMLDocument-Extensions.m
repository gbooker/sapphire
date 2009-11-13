/*
 * NSXMLDocument-Extensions.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 8, 2009.
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

#import "NSXMLDocument-Extensions.h"


@implementation NSXMLDocument (Extensions)

+ (NSXMLDocument *)tidyDocumentWithURL:(NSURL *)url error:(NSError * *)error
{
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	NSURLResponse *response = nil;
	NSData *documentData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	if(*error != nil)
	{
		SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_ERROR, @"Failed to load URL %@ with error: %@", url, *error);
		return nil;
	}
	
	NSStringEncoding responseEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]));
	NSString *documentString = [[NSString alloc] initWithData:documentData encoding:responseEncoding];
	if(documentString == nil)
	{
		//Most likely this is UTF-8 and some moron doesn't understand that the meta tags need to follow the same encoding.
		NSMutableData *mutData = [documentData mutableCopy];
		int length = [mutData length];
		const char *bytes = [mutData bytes];
		const char *location;
		while((location = strnstr(bytes, "<meta", length)) != NULL)
		{
			int offset = location - bytes;
			const char *end = strnstr(location, ">", length-offset);
			if(end != NULL)
			{
				int replaceLength = end-location+2;
				[mutData replaceBytesInRange:NSMakeRange(offset, replaceLength) withBytes:"" length:0];
				bytes = [mutData bytes];
				length = [mutData length];
			}
			else
				break;
		}
		documentString = [[NSString alloc] initWithData:mutData encoding:responseEncoding];
		[mutData release];
	}
	
	NSXMLDocument *ret = [[[NSXMLDocument alloc] initWithXMLString:documentString options:NSXMLDocumentTidyHTML error:error] autorelease];
	[documentString release];
	return ret;
}
@end
