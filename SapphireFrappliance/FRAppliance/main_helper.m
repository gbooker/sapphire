/*
 * main_helper.c
 * Sapphire
 *
 * Created by Graham Booker on Dec. 8, 2007.
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

#import "SapphireImportHelper.h"
#import <CoreData/CoreData.h>
#import "SapphireLogging.h"

@interface NSObject (SapphireApplianceControllerAPI)
+ (NSManagedObjectContext *)newManagedObjectContextForFile:(NSString *)storeFile withOptions:(NSDictionary *)options;
@end


static void gracefulClose(int i)
{
	exit(-1);
}

int main(int argc, char *argv[])
{
	/*Install custom handler so we close without user intervention*/
	signal(SIGKILL, gracefulClose);	/* illegal instruction */
	signal(SIGTRAP, gracefulClose);	/* trace trap */
	signal(SIGEMT, gracefulClose);	/* EMT instruction */
	signal(SIGFPE, gracefulClose);	/* floating point exception */
	signal(SIGBUS, gracefulClose);	/* bus error */
	signal(SIGSEGV, gracefulClose);	/* seg fault */
	signal(SIGSYS, gracefulClose);	/* bad argument to sys call */
	signal(SIGXCPU, gracefulClose);	/* over CPU limit */
	signal(SIGXFSZ, gracefulClose);	/* over file size limit */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[0] length:strlen(argv[0])];
	
	path = [[[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];

	NSBundle *bundle = [NSBundle bundleWithPath:path];
	[bundle load];
	
	[NSClassFromString(@"SapphireLogging") setLogLevel:SapphireLogLevelError forType:SapphireLogTypeAll];
	[NSClassFromString(@"SapphireLogging") setLogLevel:SapphireLogLevelDebug forType:SapphireLogTypeMetadataStore];
	
	SapphireImportHelperClient *help = [[NSClassFromString(@"SapphireImportHelperClient") alloc] init];
	[help startChild];
	
	[innerPool drain];

	NSRunLoop *currentRL = [NSRunLoop currentRunLoop];
	while([help keepRunning] && [currentRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
		;
	
	[help release];
	[pool drain];
	
	return 0;
}