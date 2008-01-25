/*
 * SLoadInstallServer.h
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

#import "SLoadInstallServer.h"
#import "SLoadInstallClient.h"

@implementation SLoadInstallServer
- (id) init
{
	self = [super init];
	if (self != nil) {
		serverConnection = [[NSConnection alloc] init];
		[serverConnection setRootObject:self];
		if([serverConnection registerName:SLoadServerName] == NO)
			NSLog(@"Register failed");
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
		
		[self startClient];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[serverConnection release];
	[client release];
	[super dealloc];
}

- (oneway void)setClient:(id <SLoadClient>)aClient
{
	if(exiting)
	{
		[aClient exitClient];
		return;
	}
	client = [aClient retain];
	NSLog(@"Got Client");
}

- (void)exitClient
{
	[client exitClient];
	[serverConnection registerName:nil];
	[serverConnection setRootObject:nil];
}

- (void)startClient
{
//	NSString *path = [[NSBundle bundleForClass:[SLoadInstallServer class]] pathForResource:@"InstallHelper" ofType:@""];
//	const char *cpath = [path fileSystemRepresentation];
//	int pid = fork();
//	if(pid == 0)
//	{
//		const char *argv[2] = {cpath, NULL};
//		execve(cpath, argv, NULL);
//	}
}

- (id <SLoadClient>)client
{
	return client;
}

- (void)connectionDidDie:(NSNotification *)note
{
	NSConnection *conn = [note object];
	if([conn rootObject] != self)
		return;
	
	[client release];
	client = nil;
	NSLog(@"Client died");
}
@end
