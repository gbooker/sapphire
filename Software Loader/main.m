/*
 * main.m
 * Software Loader
 *
 * Created by Graham Booker on Dec. 24 2007.
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

#import "SLoadApplianceController.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSBundle *myBundle = [NSBundle mainBundle];
	NSString *frapPath = [[myBundle bundlePath] stringByAppendingPathComponent:@"Software Loader.frappliance"];
	NSBundle *frap = [NSBundle bundleWithPath:frapPath];
	[frap load];
	SLoadApplianceController *cont = [[SLoadApplianceController alloc] initWithScene:nil];
	[NSTimer scheduledTimerWithTimeInterval:4.0 target:cont selector:@selector(itemSelected:) userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] run];
	[pool release];
	return 0;
}