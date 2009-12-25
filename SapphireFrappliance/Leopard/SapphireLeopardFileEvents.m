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
#import "SapphireCollectionDirectory.h"
#import "SapphireDirectoryMetaData.h"

@interface SapphireLeopardFileEvents ()
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

- (id)initWithContext:(NSManagedObjectContext *)context
{
	self = [super init];
	if(self == nil)
		return nil;
	
	moc = [context retain];
	NSArray *collections = [SapphireCollectionDirectory availableCollectionDirectoriesInContext:moc includeHiddenOverSkipped:YES];
	NSArray *paths = [collections valueForKeyPath:@"directory.path"];
	CFAbsoluteTime latency = 3.0; /*Allowed latency in seconds */
	FSEventStreamContext fcontext;
	fcontext.version = 0;
	fcontext.info = (void *)self;
	fcontext.retain = NULL;
	fcontext.release = NULL;
	fcontext.copyDescription = NULL;
	stream = FSEventStreamCreate(NULL, &fileStreamCallback, &fcontext, (CFArrayRef)paths, kFSEventStreamEventIdSinceNow, latency, kFSEventStreamCreateFlagUseCFTypes);
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	
	return self;
}

- (void) dealloc
{
	FSEventStreamStop(stream);
	FSEventStreamInvalidate(stream);
	FSEventStreamRelease(stream);
	[moc release];
	[super dealloc];
}

- (void)reloadDir:(NSString *)dir
{
	dir = [dir stringByStandardizingPath];
	SapphireDirectoryMetaData *directory = [SapphireDirectoryMetaData directoryWithPath:dir inContext:moc];
	[directory reloadDirectoryContents];
	[directory resumeImport];
}
@end
