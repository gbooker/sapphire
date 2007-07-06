//
//  SapphireMetaDataScanner.m
//  Sapphire
//
//  Created by Graham Booker on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
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
	[delegate release];
	[super dealloc];
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
	[self autorelease];
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
			[next getSubFileMetasWithDelegate:self];
		else
			[next scanForNewFilesWithDelegate:self];
		[remaining removeLastObject];
	}
	else
		[self sendResults];
}

@end
