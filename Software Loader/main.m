//
//  main.m
//  Software Loader
//
//  Created by Graham Booker on 12/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

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