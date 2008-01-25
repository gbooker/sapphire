/*
 * SLoadDownloadDelegate.h
 * Software Loader
 *
 * Created by Graham Booker on Dec. 30 2007.
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

#import "SLoadDownloadDelegate.h"
#import "NSData-HashSupport.h"
#import "SLoadDelegateProtocol.h"

@implementation SLoadDownloadDelegate

- (id) initWithDest:(NSString *)dest
{
	self = [super init];
	if (self == nil)
		return nil;
	
	destination = [dest retain];
	
	return self;
}

- (void) dealloc
{
	[destination release];
	[downloadHash release];
	[target release];
	[delegate release];
	[super dealloc];
}

- (void)setTarget:(id <NSObject>)targ success:(SEL)succussSelector failure:(SEL)failureSelector
{
	[target release];
	target = [targ retain];
	success = succussSelector;
	failure = failureSelector;
}

- (void)setHash:(NSData *)hash
{
	[downloadHash release];
	downloadHash = [hash retain];
}

- (void)setLoadDelegate:(id <SLoadDelegateProtocol>)aDelegate
{
	[delegate release];
	delegate = [aDelegate retain];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
	[download setDestination:destination allowOverwrite:YES];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	if([[NSData md5HashForFile:destination] isEqualToData:downloadHash])
		[target performSelector:success withObject:destination];
	else
		[target performSelector:failure withObject:BRLocalizedString(@"Downloaded File Does Not Match Hash", @"Download Failed Error")];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[target performSelector:failure withObject:error];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	total = [response expectedContentLength];
	completed = 0;
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte
{
	completed = startingByte;
	total = startingByte + [response expectedContentLength];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	completed += length;
	[delegate setDownloadedBytes:completed ofTotal:total];
}

@end