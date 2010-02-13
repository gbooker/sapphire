//
//  CMPDVDImageAction.m
//  CommonMediaPlayer
//
//  Created by blunt on 2/12/10.
//  Copyright 2010 nito, LLC. All rights reserved.
//

#import "CMPDVDImageAction.h"


@implementation CMPDVDImageAction

- (id)initWithPlayer:(id <CMPPlayer>)thePlayer andPath:(NSString *)thePath
{
	self = [super init];
	if(!self)
		return self;
	
	mountedPath = thePath;
	player = thePlayer;
	return self;
}

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	return [super init];
	
}


- (NSString *)imagePath {
    return [[imagePath retain] autorelease];
}

- (void)setImagePath:(NSString *)value {
    if (imagePath != value) {
        [imagePath release];
        imagePath = [value copy];
    }
}

- (NSString *)mountedPath {
    return [[mountedPath retain] autorelease];
}

- (void)setMountedPath:(NSString *)value {
    if (mountedPath != value) {
        [mountedPath release];
        mountedPath = [value copy];
    }
}



- (BOOL)openWithError:(NSError **)error
{
	NSLog(@"open with error");
	NSString *mountDisc = [self attachImage:mountedPath];
	//NSFileManager *man = [NSFileManager defaultManager];
	if (mountDisc == nil)
		return NO; //don't really know how to do NSError reports properly
	
	[self setMountedPath:mountDisc];
	NSLog(@"open with error returned path: %@", mountDisc);
	
	//if ([man fileExistsAtPath:[mountDisc stringByAppendingPathComponent:@"VIDEO_TS"]])
	
	[player setMountedPath:mountDisc];
	
	
	return YES;
	
}


- (BOOL)closeWithError:(NSError **)error
{

	return [self detachImage:[self mountedPath]];
	
	//return [screenRelease closeWithError:error];
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
