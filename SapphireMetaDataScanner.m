//
//  SapphireMetaDataScanner.m
//  Sapphire
//
//  Created by Graham Booker on 7/6/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMetaDataScanner.h"
#import "SapphireMetaData.h"

@implementation SapphireMetaDataScanner

- (id)initWithDirectoryMetaData:(SapphireDirectoryMetaData *)meta delegate:(id <SapphireMetaDataScannerDelegate>)newDelegate
{
	self = [super init];
	if (self != nil) {
		metaDir = [meta retain];
		remaining = [[meta directories] mutableCopy];
		results = [NSMutableArray new];
		delegate = [newDelegate retain];
	}
	return self;
}

- (void) dealloc {
	[metaDir release];
	[remaining release];
	[results release];
	[skipDirectories release];
	[delegate release];
	[super dealloc];
}

- (void)setSkipDirectories:(NSMutableSet *)skip
{
	skipDirectories = [skip retain];
	int i;
	for(i = [remaining count]-1; i>=0; i++)
	{
		NSString *checkPath = [[metaDir metaDataForDirectory:[remaining objectAtIndex:i]] path];
		if([skipDirectories containsObject:checkPath])
			[remaining removeObjectAtIndex:i];
		else
			[skipDirectories addObject:checkPath];
	}
}

- (void)setGivesResults:(BOOL)givesResults
{
	if(givesResults)
		results = [NSMutableArray new];
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

- (void)sendResults
{
	NSEnumerator *fileEnum = [[metaDir files] objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *fileMeta = [metaDir metaDataForFile:file];
		if(fileMeta != nil)
			[results addObject:fileMeta];
	}
	[delegate gotSubFiles:results];
}

- (void)gotSubFiles:(NSArray *)subs
{
	[results addObjectsFromArray:subs];
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

- (BOOL)getSubFilesCanceled
{
	return [delegate getSubFilesCanceled];
}

- (void)nextFile:(NSTimer *)timer
{
	if(![delegate getSubFilesCanceled] && [remaining count])
	{
		SapphireDirectoryMetaData *next = [metaDir metaDataForDirectory:[remaining lastObject]];
		if(results != nil)
			[next getSubFileMetasWithDelegate:self skipDirectories:skipDirectories];
		else
			[next scanForNewFilesWithDelegate:self skipDirectories:skipDirectories];
		[remaining removeLastObject];
	}
	else
		[self sendResults];
}

@end
