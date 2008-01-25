/*
 * SLoadInstallClient.m
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
#import "SLoadInstallServer.h"
#import "SLoadInstaller.h"

@implementation SLoadInstallClient
- (id) init
{
	self = [super init];
	if (self != nil) {
		realClient = [[SLoadInstaller alloc] init];
		keepRunning = YES;
	}
	return self;
}

- (void) dealloc
{
	[realClient release];
	[server release];
	[super dealloc];
}

- (oneway void)setDelegate:(id <SLoadDelegateProtocol>)aDelegate
{
	[realClient setDelegate:aDelegate];
}

- (oneway void)cancel
{
	[realClient cancel];
}

- (oneway void)installSoftware:(NSDictionary *)software withInstaller:(NSString *)installer
{
	[realClient installSoftware:software withInstaller:installer];
}

- (oneway void)installInstaller:(NSString *)installer
{
	[realClient installInstaller:installer];
}

- (oneway void)exitClient
{
	keepRunning = NO;
}

- (void)startChild
{
	@try {
		NSConnection *connection = [NSConnection connectionWithRegisteredName:SLoadServerName host:nil];
		id serverobj = [[connection rootProxy] retain];
		[serverobj setProtocolForProxy:@protocol(SLoadServer)];
		[serverobj setClient:self];
		server = serverobj;
		if(server == nil)
		{
			keepRunning = NO;
			return;
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
	}
	@catch (NSException * e) {
		keepRunning = NO;
	}
}

- (void)connectionDidDie:(NSNotification *)note
{
	[self exitClient];
}

- (BOOL)keepRunning
{
	return keepRunning;
}
@end
