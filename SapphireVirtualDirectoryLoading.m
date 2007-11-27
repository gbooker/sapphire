//
//  SapphireVirtualDirectoryLoading.m
//  Sapphire
//
//  Created by Graham Booker on 11/27/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectoryLoading.h"


@implementation SapphireVirtualDirectoryLoading

- (void)dealloc
{
	[checkTimer invalidate];
	[directory release];
	[browser release];
	[super dealloc];
}

- (void)setDirectory:(SapphireVirtualDirectory *)dir
{
	directory = [dir retain];
}

- (void)setBrowser:(SapphireBrowser *)browse
{
	browser = [browse retain];
}

- (void)doCheck
{
	if(![directory isLoaded])
		return;
	
	NSLog(@"Swapping with %@", [self stack]);
	[checkTimer invalidate];
	checkTimer = nil;
/*	[[self stack] pushController:directory];
	[[self stack] removeControl:self];*/
	[[self stack] swapController:browser];
}

- (void)wasPushed
{
	[super wasPushed];
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doCheck) userInfo:nil repeats:YES];
}

- (void)wasPopped
{
	[super wasPopped];
	[checkTimer invalidate];
	checkTimer = nil;
}

@end
