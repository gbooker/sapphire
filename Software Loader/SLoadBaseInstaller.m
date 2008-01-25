/*
 * SLoadBaseInstaller.m
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

#import "SLoadBaseInstaller.h"
#import "SLoadFileUtilities.h"
#import "SLoadDelegateProtocol.h"

@implementation SLoadBaseInstaller

- (id) init
{
	self = [super init];
	if (self != nil) {
		filemanager = [NSFileManager defaultManager];
		fileUtils = [SLoadFileUtilities sharedInstance];
	}
	return self;
}

- (void) dealloc
{
	[error release];
	[delegate release];
	[downloader release];
	[super dealloc];
}

- (void)setError:(NSString *)format, ...
{
	va_list ap;
	va_start(ap, format);
	
	[error release];
	error = [[NSString alloc] initWithFormat:format arguments:ap];
	
	va_end(ap);
}

- (NSString *)error
{
	if(error == nil)
		return [fileUtils error];
	return error;
}

- (void)setDelegate:(id <SLoadDelegateProtocol>)aDelegate
{
	[delegate release];
	delegate = [aDelegate retain];
}

- (void)cancel
{
	[downloader cancel];
}

- (void)install:(NSDictionary *)software
{
}

@end
