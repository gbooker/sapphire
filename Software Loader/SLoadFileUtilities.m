/*
 * SLoadFileUtilities.h
 * Software Loader
 *
 * Created by Graham Booker on Dec. 30 2007.
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

#import "SLoadFileUtilities.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>

@implementation SLoadFileUtilities

+ (SLoadFileUtilities *)sharedInstance
{
	static SLoadFileUtilities *shared = nil;
	if(shared == nil)
		shared = [[SLoadFileUtilities alloc] init];
	
	return shared;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		filemanager = [NSFileManager defaultManager];
	}
	return self;
}

- (void) dealloc
{
	[error release];
	[super dealloc];
}

- (void)setError:(NSString *)format, ...
{
	va_list ap;
	va_start(ap, format);
	
	[error release];
	error = [[NSString alloc] initWithFormat:format arguments:ap];
	
	va_end(ap);
}

- (NSString *)error
{
	return error;
}

- (BOOL)extract:(NSString *)src inDir:(NSString *)dest
{
	NSTask *extractTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/ditto" arguments:[NSArray arrayWithObjects:@"-x", @"-k", @"--rsrc", src, dest, nil]];
	[extractTask waitUntilExit];
	return [extractTask terminationStatus] == 0;
}

- (BOOL)copy:(NSString *)src toDir:(NSString *)dest withReplacement:(BOOL)replace
{
	NSString *finalPath = [dest stringByAppendingPathComponent:[src lastPathComponent]];
	BOOL exists = [filemanager fileExistsAtPath:finalPath];
	if(exists && !replace)
		return YES;
	
	BOOL ret = YES;
	if(exists)
	{
		if(!(ret = [filemanager removeFileAtPath:finalPath handler:nil]))
			[self setError:@"Could not remove %@ which is in the way", dest];
	}
	if(ret)
	{
		if(!(ret = [filemanager copyPath:src toPath:finalPath handler:nil]))
			[self setError:@"Could not copy %@ to %@", src, dest];
	}
	return ret;
}

- (BOOL)move:(NSString *)src toDir:(NSString *)dest withReplacement:(BOOL)replace
{
	NSString *finalPath = [dest stringByAppendingPathComponent:[src lastPathComponent]];
	BOOL exists = [filemanager fileExistsAtPath:finalPath];
	if(exists && !replace)
		return YES;
	
	BOOL ret = YES;
	if(exists)
	{
		if(!(ret = [filemanager removeFileAtPath:finalPath handler:nil]))
			[self setError:@"Could not remove %@ which is in the way", dest];
	}
	if(ret)
	{
		if(!(ret = [filemanager movePath:src toPath:finalPath handler:nil]))
			[self setError:@"Could not move %@ to %@", src, dest];
	}
	return ret;
}

- (NSURLDownload *)downloadURL:(NSString *)urlString withDelegate:(SLoadDownloadDelegate *)downloadDelegate
{
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
	NSURLDownload *downloader = [[NSURLDownload alloc] initWithRequest:request delegate:downloadDelegate];
	[request release];
	return downloader;
}

- (NSArray *)mountDiskImage:(NSString *)path
{
	NSTask *mountTask = [[NSTask alloc] init];
	NSPipe *communication = [NSPipe pipe];
	NSFileHandle *readHandle = [communication fileHandleForReading];
	[mountTask setStandardOutput:communication];
	[mountTask setLaunchPath:@"/usr/bin/hdiutil"];
	[mountTask setArguments:[NSArray arrayWithObjects:@"attach", @"-plist", path, nil]];
	[mountTask launch];
	NSData *readData = [readHandle readDataToEndOfFile];
	[mountTask release];
	NSDictionary *result = [NSPropertyListSerialization propertyListFromData:readData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
	NSMutableArray *mounts = [NSMutableArray array];
	if([result count])
	{
		NSArray *entities = [result objectForKey:@"system-entities"];
		NSEnumerator *entityEnum = [entities objectEnumerator];
		NSDictionary *entity;
		while((entity = [entityEnum nextObject]) != nil)
		{
			NSString *mountPoint = [entity objectForKey:@"mount-point"];
			if(mountPoint != nil)
				[mounts addObject:mountPoint];
		}
	}
	return mounts;
}

- (void)unmountDiskImage:(NSArray *)mounts
{
	NSEnumerator *mountEnum = [mounts objectEnumerator];
	NSString *mount;
	while((mount = [mountEnum nextObject]) != nil)
	{
		NSString *command = [NSString stringWithFormat:@"/usr/bin/hdiutil detach \"%@\"", mount];
		FILE *fp = popen([command UTF8String], "r");
		if(fp)
		{
			char buffer[1024];
			int amountRead;
			
			while((amountRead = fread(buffer, sizeof(char), 1024, fp)) != 0)
				;
		}
	}
}

- (void)remountReadWrite
{
	struct statfs stats;
	if(statfs("/", &stats) == 0)
	{
		wasReadOnly = (stats.f_flags & MNT_RDONLY) ? YES : NO;
		if(wasReadOnly)
			[NSTask launchedTaskWithLaunchPath:@"/sbin/mount" arguments:[NSArray arrayWithObjects:@"-uw", @"/", nil]];
	}
	
}

- (void)remountReadOnly
{
	if(wasReadOnly)
		[NSTask launchedTaskWithLaunchPath:@"/sbin/mount" arguments:[NSArray arrayWithObjects:@"-ur", @"/", nil]];
}

@end
