/*
 * SapphireLeopardFileEvents.m
 * Sapphire
 *
 * Created by Graham Booker on Dec. 19, 2007.
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

#import "SapphireLeopardFileEvents.h"
#import "SapphireMetaData.h"

@interface SapphireLeopardFileEvents (private)
- (void)reloadDir:(NSString *)dir;
@end

@implementation SapphireLeopardFileEvents

static void fileStreamCallback(ConstFSEventStreamRef stream, void *context, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
	int i;
	NSArray *paths = (NSArray *)eventPaths;
	for(i=0; i<numEvents; i++)
	{
		[(SapphireLeopardFileEvents *)context reloadDir:[paths objectAtIndex:i]];
	}
}

- (id)initWithCollection:(SapphireMetaDataCollection *)coll
{
	self = [super init];
	if(self == nil)
		return nil;
	
	collection = [coll retain];
	NSArray *paths = [NSArray arrayWithObject:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"]];
	CFAbsoluteTime latency = 3.0; /*Allowed latency in seconds */
	FSEventStreamContext context;
	context.version = 0;
	context.info = (void *)self;
	context.retain = NULL;
	context.release = NULL;
	context.copyDescription = NULL;
	stream = FSEventStreamCreate(NULL, &fileStreamCallback, &context, (CFArrayRef)paths, kFSEventStreamEventIdSinceNow, latency, kFSEventStreamCreateFlagUseCFTypes);
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	
	return self;
}

- (void) dealloc
{
	FSEventStreamStop(stream);
	FSEventStreamInvalidate(stream);
	FSEventStreamRelease(stream);
	[collection retain];
	[super dealloc];
}

- (void)reloadDir:(NSString *)dir
{
	SapphireDirectoryMetaData *directory = [collection directoryForPath:dir];
	[directory reloadDirectoryContents];
	[directory resumeImport];
}
@end
