//
//  SapphireVirtualDirectory.m
//  Sapphire
//
//  Created by Graham Booker on 11/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireVirtualDirectory.h"


@interface SapphireDirectoryMetaData (privateFunctions)
- (id)initWithDictionary:(NSDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath;
@end

@implementation SapphireVirtualDirectory
- (id)initWithParent:(SapphireVirtualDirectory *)myParent path:(NSString *)myPath
{
	self = [super initWithDictionary:nil parent:myParent path:myPath];
	if(self == nil)
		return nil;
	
	directory = [[NSMutableDictionary alloc] init];
	reloadTimer = nil;
	scannedDirectory = YES;
	
	return self;
}

- (void) dealloc
{
	[directory release];
	[reloadTimer invalidate];
	[super dealloc];
}

- (void)reloadDirectoryContents
{
	[files removeAllObjects];
	[directories removeAllObjects];
	[metaFiles removeAllObjects];
	[metaDirs removeAllObjects];
	[cachedMetaFiles removeAllObjects];
	[cachedMetaDirs removeAllObjects];
	[reloadTimer invalidate];
	reloadTimer = nil;
}

- (void)setReloadTimer
{
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reloadDirectoryContents) userInfo:nil repeats:NO];
}

- (void)processFile:(SapphireFileMetaData *)file
{
}

- (void)removeFile:(SapphireFileMetaData *)file
{
}

- (void)childDisplayChanged
{
	/*The way the timings work out, if the timer exists already, it is more efficient to leave it set rather than set a new one*/
	if(reloadTimer == nil)
		[self setReloadTimer];
}

- (NSMutableDictionary *)directoryEntries
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	NSEnumerator *pathEnum = [directory keyEnumerator];
	NSString *subPath = nil;
	while((subPath = [pathEnum nextObject]) != nil)
	{
		SapphireMetaData *data = [directory objectForKey:subPath];
		if([data isKindOfClass:[SapphireVirtualDirectory class]])
			[ret setObject:[(SapphireVirtualDirectory *)data directoryEntries] forKey:subPath];
		else
			[ret setObject:[data path] forKey:subPath];
	}
	return ret;
}

- (void)writeToFile:(NSString *)filePath
{
	NSMutableDictionary *fileData = [self directoryEntries];
	[fileData writeToFile:filePath	atomically:YES];
}

- (BOOL)isDisplayEmpty
{
	return [files count] == 0 && [directories count] == 0;
}

- (BOOL)isEmpty
{
	return [directory count] == 0;
}

@end