/*
 * CMPDVDImageAction.m
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 12 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */

#import "CMPDVDImageAction.h"

@interface CMPDVDImageAction ()
- (NSString *)attachImage:(NSString *)irString;
- (BOOL)detachImage:(NSString *)theImagePath;
@end


@implementation CMPDVDImageAction

- (id)initWithPath:(NSString *)thePath
{
	self = [super init];
	if(!self)
		return self;
	
	mountedPath = [thePath retain];
	return self;
}

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	[self autorelease];
	return nil;
}

- (void) dealloc
{
	[mountedPath release];
	[imagePath release];
	[super dealloc];
}

- (NSString *)imagePath {
    return [[imagePath retain] autorelease];
}

- (NSString *)mountedPath {
    return [[mountedPath retain] autorelease];
}

- (BOOL)openWithError:(NSError **)error
{
	NSLog(@"open with error");
	NSString *mountDisc = [self attachImage:mountedPath];
	//NSFileManager *man = [NSFileManager defaultManager];
	if (mountDisc == nil)
		return NO; //don't really know how to do NSError reports properly
	
	[mountedPath release];
	mountedPath = [mountDisc retain];
	NSLog(@"open with error returned path: %@", mountDisc);
	
	return YES;
	
}


- (BOOL)closeWithError:(NSError **)error
{
	return [self detachImage:[self mountedPath]];
}


- (NSString *)attachImage:(NSString *)irString
{
	NSLog(@"attachImage: %@", irString);
	NSTask *irTask = [[NSTask alloc] init];
	NSPipe *hdip = [[NSPipe alloc] init];
    NSFileHandle *hdih = [hdip fileHandleForReading];
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"attach"];
	[irArgs addObject:@"-plist"];
	
	[irArgs addObject:irString];
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
	//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	[irTask waitUntilExit];
	
	NSData *outData;
	outData = [hdih readDataToEndOfFile];
	[hdip release];
	
	NSString *error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData 
											 mutabilityOption:NSPropertyListImmutable
													   format:&format
											 errorDescription:&error];
	if(!plist)
		
	{
		
		NSLog(error);
		
		[error release];
		[irTask release];
		irTask = nil;
		return nil;
	}
	//NSLog(@"plist: %@", plist);
	
	NSArray *plistArray = [plist objectForKey:@"system-entities"];
	
	//int theItem = ([plistArray count] - 1);
	
	NSDictionary *mountDict = [plistArray lastObject];
	
	NSString *mountPath = [mountDict objectForKey:@"mount-point"];
	
	//NSLog(@"Mount Point: %@", mountPath);
	
	
	int rValue = [irTask terminationStatus];
	
	if (rValue == 0)
	{	[irTask release];
		irTask = nil;
		return mountPath;
	}
	
	[irTask release];
	irTask = nil;	
	return nil;
}

- (BOOL)detachImage:(NSString *)theImagePath{
	
	NSTask *diTask = [[NSTask alloc] init];
	NSMutableArray *hdiArgs = [[NSMutableArray alloc] init];
	
	[hdiArgs addObject:@"detach"];
	[hdiArgs addObject:theImagePath];
	[diTask setLaunchPath:@"/usr/bin/hdiutil"];
	[diTask setArguments:hdiArgs];
	[hdiArgs release];
	
	//NSLog(@"hdiutil %@", [[hdiArgs arguments] componentsJoinedByString:@" "]);
	
	[diTask launch];
	[diTask waitUntilExit];
	
		
	
	int rValue = [diTask terminationStatus];
	
	if (rValue == 0)
	{	[diTask release];
		diTask = nil;
		return YES;
	}
	
	[diTask release];
	diTask = nil;	
	return NO;
}



@end
