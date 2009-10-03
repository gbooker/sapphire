/*
 * main_rescanDir.m
 * Sapphire
 *
 * Created by Graham Booker on Nov. 30, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#include "../SapphireCompatibilityClasses/Sapphire_Prefix.pch"
#import "FRAppliance/SapphireApplianceController.h"

int main(int argc, char *argv[])
{
	if(argc < 1)
	{
		printf("Usage: %s directory", argv[0]);
		return 1;
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i, ret = 0;
	NSFileManager *fm = [NSFileManager defaultManager];
	for(i=1; i<argc; i++)
	{
		NSString *path = [fm stringWithFileSystemRepresentation:argv[i] length:strlen(argv[i])];
		path = [path stringByStandardizingPath];
		if(![path isAbsolutePath])
			path = [[fm currentDirectoryPath] stringByAppendingPathComponent:path];
		BOOL isDir = NO;
		if([fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
		{
			NSPort *sendPort = [[NSSocketPort alloc] initRemoteWithTCPPort:DISTRIBUTED_MESSAGES_PORT host:@"127.0.0.1"];
			NSConnection *conn = [[NSConnection alloc] initWithReceivePort:[NSSocketPort port] sendPort:sendPort];
			[sendPort release];
			id proxy = [conn rootProxy];
			[proxy setProtocolForProxy:@protocol(SapphireDistributedMessagesProtocol)];
			[(id <SapphireDistributedMessagesProtocol>)proxy rescanDirectory:path];
			[conn release];
		}
		else
		{	
			printf("%s is not a directory", argv[i]);
			ret = 1;
		}
	}
	[pool release];
	return ret;
}