/*
 * helper.m
 * Software Loader
 *
 * Created by Graham Booker on Dec. 28 2007.
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

#import "SLoadInstallClient.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#ifdef DEBUG_BUILD
	Debugger();
#endif
	NSString *myPath = [[NSBundle bundleForClass:[SLoadInstallClient class]] bundlePath];
	NSString *utilsFrameworkPath = [myPath stringByAppendingPathComponent:@"Contents/Frameworks/SLoadUtilities.framework"];
	NSBundle *utilsFramework = [NSBundle bundleWithPath:utilsFrameworkPath];
	[utilsFramework load];
	SLoadInstallClient *client = [[SLoadInstallClient alloc] init];
	[client startChild];
	NSRunLoop *currentRL = [NSRunLoop currentRunLoop];
	while([client keepRunning] && [currentRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
		;
	[client release];
	[pool release];
	return 0;
}