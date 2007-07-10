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

/*!
 * @brief Create a new scanner on a directory
 *
 * @param meta The meta data's directory to scan
 * @param newDelegate The delegate to ask and tell about the scan
 * @return The scanner
 */
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

/*!
 * @brief Sets a list of directories to skip.
 *
 * @param skip The set of directories to skip.  Note, this set *is* modified
 */
- (void)setSkipDirectories:(NSMutableSet *)skip
{
	skipDirectories = [skip retain];
	int i;
	for(i = [remaining count]-1; i>=0; i--)
	{
		/*Remove any in our remaining that are to be skipped*/
		NSString *checkPath = [[metaDir metaDataForDirectory:[remaining objectAtIndex:i]] path];
		if([skipDirectories containsObject:checkPath])
			[remaining removeObjectAtIndex:i];
		else
			/*Make sure they are not processed later*/
			[skipDirectories addObject:checkPath];
	}
}

/*!
 * @brief Sets whether we care for the results or just want a rescan.  This starts the scan
 *
 * @param givesResults YES if the delegate wants results, NO otherwise
 */
- (void)setGivesResults:(BOOL)givesResults
{
	if(givesResults)
		results = [NSMutableArray new];
	/*Start the scan*/
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

/*!
 * @brief Send the results to the delegate
 */
- (void)sendResults
{
	/*Include the files in this dir*/
	NSEnumerator *fileEnum = [[metaDir files] objectEnumerator];
	NSString *file = nil;
	while((file = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *fileMeta = [metaDir metaDataForFile:file];
		if(fileMeta != nil)
			[results addObject:fileMeta];
	}
	/*Send results*/
	[delegate gotSubFiles:results];
}

/*!
 * @brief Delegate method from our helpers in sub dirs
 *
 * @param subs The results found by others
 */
- (void)gotSubFiles:(NSArray *)subs
{
	/*Add the results*/
	[results addObjectsFromArray:subs];
	/*Resume*/
	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

/*!
 * @brief Delegate method from our helpres in sub dirs
 *
 * @return YES if we should cancel the scan, NO otherwise
 */
- (BOOL)getSubFilesCanceled
{
	/*Ask our delegate since that is our answer*/
	return [delegate getSubFilesCanceled];
}

/*!
 * @brief Go to the next file
 *
 * @param timer The timer that triggered this
 */
- (void)nextFile:(NSTimer *)timer
{
	/*Check for cancel and completion*/
	if(![delegate getSubFilesCanceled] && [remaining count])
	{
		/*Scan the next directory*/
		SapphireDirectoryMetaData *next = [metaDir metaDataForDirectory:[remaining objectAtIndex:0]];
		/*State whether we care for results*/
		if(results != nil)
			[next getSubFileMetasWithDelegate:self skipDirectories:skipDirectories];
		else
			[next scanForNewFilesWithDelegate:self skipDirectories:skipDirectories];
		/*remove this item*/
		[remaining removeObjectAtIndex:0];
	}
	else
		/*We are done, send results and quit*/
		[self sendResults];
}

@end
