/*
 * SapphireMetaDataScanner.m
 * Sapphire
 *
 * Created by Graham Booker on Jul. 6, 2007.
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

#import "SapphireMetaDataScanner.h"
#import "SapphireApplianceController.h"
#import "SapphireDirectoryMetaData.h"

@implementation SapphireMetaDataScanner

- (id)initWithDirectoryMetaData:(SapphireDirectoryMetaData *)meta delegate:(id <SapphireMetaDataScannerDelegate>)newDelegate
{
	self = [super init];
	if (self != nil) {
		metaDir = [meta retain];
		remaining = nil;
		results = nil;
		delegate = [newDelegate retain];
		dirs = files = symDirs = symFiles = nil;
		dirsComp = filesComp = symDirsComp = symFilesComp = nil;
		subScanners = [[NSMutableDictionary alloc] init];
		depth = [[[meta path] pathComponents] count];
	}
	return self;
}

- (void) dealloc {
	[nextFileTimer invalidate];
	[metaDir release];
	[remaining release];
	[results release];
	[skipDirectories release];
	[delegate release];
	[dirs release];
	[files release];
	[symDirs release];
	[symFiles release];
	[subScanners release];
	[dirsComp release];
	[filesComp release];
	[symDirsComp release];
	[symFilesComp release];
	[super dealloc];
}

- (void)setSkipDirectories:(NSMutableSet *)skip
{
	skipDirectories = [skip retain];
	[delegate scanningDir:[metaDir path]];
	int i;
	for(i = [remaining count]-1; i>=0; i--)
	{
		/*Remove any in our remaining that are to be skipped*/
		NSString *checkPath = [[remaining objectAtIndex:i] path];
		if([skipDirectories containsObject:checkPath])
			[remaining removeObjectAtIndex:i];
		else
			/*Make sure they are not processed later*/
			[skipDirectories addObject:checkPath];
	}
}

- (void)setSubDirs:(NSArray *)subDirs components:(NSArray *)components
{
	dirs = [subDirs mutableCopy];
	dirsComp = [components mutableCopy];
}

- (void)setSubFiles:(NSArray *)subFiles components:(NSArray *)components
{
	files = [subFiles mutableCopy];
	filesComp = [components mutableCopy];
}

- (void)setSubSymDirs:(NSArray *)subSymDirs components:(NSArray *)components
{
	symDirs = [subSymDirs mutableCopy];
	symDirsComp = [components mutableCopy];
}

- (void)setSubSymFiles:(NSArray *)subSymFiles components:(NSArray *)components
{
	symFiles = [subSymFiles mutableCopy];
	symFilesComp = [components mutableCopy];
}

typedef void (*subLoopCallback)(SapphireMetaDataScanner *scan, NSString *lastName, NSArray *compArray, NSArray *objArray, int startIndex, int endIndex, int newDepth);

static void subLoop(SapphireMetaDataScanner *scan, NSArray *compArray, NSArray *objArray, int currentDepth, subLoopCallback callback)
{
	int i, lastStart = 0;
	int endIndex = [objArray count];
	NSString *current = nil;
	int newDepth = currentDepth + 1;
	for(i=0; i<=endIndex; i++)
	{
		NSArray *components;
		NSString *subDirName;
		if(i == endIndex)
		{
			if(i == 0)
				return;
		}
		else
		{
			components = [compArray objectAtIndex:i];
			subDirName = [components objectAtIndex:currentDepth];
			if([current isEqualToString:subDirName])
				continue;			
		}
		
		if(i != lastStart)
		{
			callback(scan, current, compArray, objArray, lastStart, i, newDepth);
			lastStart = i;			
		}
		current = subDirName;
	}	
}

static void subDirCallback(SapphireMetaDataScanner *scan, NSString *lastName, NSArray *compArray, NSArray *objArray, int startIndex, int endIndex, int newDepth)
{
	SapphireDirectoryMetaData *subDir = [objArray objectAtIndex:startIndex];
	
	/*	The / character isn't always first in sorted order, so make sure this isn't a case of:
	 *	dirName
	 *	dirName With More info
	 *	dirName/subDirName
	 */
	SapphireMetaDataScanner *sub = [scan->subScanners objectForKey:lastName];
	BOOL created = NO;
	if(sub == nil)
	{
		sub = [[SapphireMetaDataScanner alloc] initWithDirectoryMetaData:subDir delegate:scan];
		startIndex++;
		created = YES;
	}
	if(startIndex != endIndex)
	{
		NSRange range = NSMakeRange(startIndex, endIndex-startIndex);
		[sub setSubDirs:[objArray subarrayWithRange:range] components:[compArray subarrayWithRange:range]];
	}
	if(created)
	{
		[scan->dirs addObject:subDir];
		[scan->subScanners setObject:sub forKey:lastName];
		[sub release];		
	}
}

static void subFileCallback(SapphireMetaDataScanner *scan, NSString *lastName, NSArray *compArray, NSArray *objArray, int startIndex, int endIndex, int newDepth)
{
	SapphireMetaDataScanner *sub = [scan->subScanners objectForKey:lastName];
	if(sub == nil)
	{
		if([[compArray objectAtIndex:startIndex] count] == newDepth)
			//This was really a file
			[scan->files addObject:[objArray objectAtIndex:startIndex]];
		return;
	}
	if(startIndex != endIndex)
	{
		NSRange range = NSMakeRange(startIndex, endIndex-startIndex);
		[sub setSubFiles:[objArray subarrayWithRange:range] components:[compArray subarrayWithRange:range]];
	}
}

static void subSymDirCallback(SapphireMetaDataScanner *scan, NSString *lastName, NSArray *compArray, NSArray *objArray, int startIndex, int endIndex, int newDepth)
{
	SapphireMetaDataScanner *sub = [scan->subScanners objectForKey:lastName];
	if(sub == nil)
	{
		if([[compArray objectAtIndex:startIndex] count] == newDepth)
			//This was really a file
			[scan->symDirs addObject:[objArray objectAtIndex:startIndex]];
		return;
	}
	if(startIndex != endIndex)
	{
		NSRange range = NSMakeRange(startIndex, endIndex-startIndex);
		[sub setSubSymDirs:[objArray subarrayWithRange:range] components:[compArray subarrayWithRange:range]];
	}
}

static void subSymFileCallback(SapphireMetaDataScanner *scan, NSString *lastName, NSArray *compArray, NSArray *objArray, int startIndex, int endIndex, int newDepth)
{
	SapphireMetaDataScanner *sub = [scan->subScanners objectForKey:lastName];
	if(sub == nil)
	{
		if([[compArray objectAtIndex:startIndex] count] == newDepth)
			//This was really a file
			[scan->symFiles addObject:[objArray objectAtIndex:startIndex]];
		return;
	}
	if(startIndex != endIndex)
	{
		NSRange range = NSMakeRange(startIndex, endIndex-startIndex);
		[sub setSubSymFiles:[objArray subarrayWithRange:range] components:[compArray subarrayWithRange:range]];
	}
}

- (void)separateSubDirFiles
{
	NSArray *subArray = dirs;
	dirs = [[NSMutableArray alloc] init];
	subLoop(self, dirsComp, subArray, depth, subDirCallback);
	[subArray release];
	
	subArray = files;
	files = [[NSMutableArray alloc] init];
	subLoop(self, filesComp, subArray, depth, subFileCallback);
	[subArray release];
	
	subArray = symDirs;
	symDirs = [[NSMutableArray alloc] init];
	subLoop(self, symDirsComp, subArray, depth, subSymDirCallback);
	[subArray release];
	
	subArray = symFiles;
	symFiles = [[NSMutableArray alloc] init];
	subLoop(self, symFilesComp, subArray, depth, subSymFileCallback);
	[subArray release];
	
	[metaDir rescanDirWithExistingDirs:dirs files:files symDirs:symDirs symFiles:symFiles];
	remaining = [dirs mutableCopy];
	[remaining addObjectsFromArray:[symDirs valueForKey:@"directory"]];
}

- (void)setSubDirs:(NSArray *)subDirs files:(NSArray *)subFiles symDirs:(NSArray *)subSymDirs symFiles:(NSArray *)subSymFiles
{
	NSString *pathKey = @"path.pathComponents";
	dirs = [subDirs mutableCopy];
	dirsComp = [[subDirs valueForKeyPath:pathKey] mutableCopy];
	files = [subFiles mutableCopy];
	filesComp = [[subFiles valueForKeyPath:pathKey] mutableCopy];
	symDirs = [subSymDirs mutableCopy];
	symDirsComp = [[subSymDirs valueForKeyPath:pathKey] mutableCopy];
	symFiles = [subSymFiles mutableCopy];
	symFilesComp = [[subSymFiles valueForKeyPath:pathKey] mutableCopy];
	[self separateSubDirFiles];
}

- (void)setGivesResults:(BOOL)givesResults
{
	if(givesResults)
		results = [NSMutableArray new];
	/*Start the scan*/
	[self retain];
	nextFileTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

/*!
 * @brief Send the results to the delegate
 */
- (void)sendResults
{
	/*Include the files in this dir*/
	if(results != nil)
	{
		[results addObjectsFromArray:files];
		[results addObjectsFromArray:symFiles];
	}
	/*Send results*/
	[delegate gotSubFiles:results];
	[delegate release];
	delegate = nil;
	[self autorelease];
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
	nextFileTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(nextFile:) userInfo:nil repeats:NO];
}

/*!
 * @brief Lets the delegate know it is scanning a directory
 *
 * @param dir The directory it is scanning
 */
- (void)scanningDir:(NSString *)dir
{
	[delegate scanningDir:dir];
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
	@try
	{
		nextFileTimer = nil;
		/*Check for cancel and completion*/
		if(![delegate getSubFilesCanceled] && [remaining count])
		{
			/*Scan the next directory*/
			SapphireDirectoryMetaData *next = [remaining objectAtIndex:0];
			SapphireMetaDataScanner *scan = nil;
			if([next parent] == metaDir)
				scan = [subScanners objectForKey:[[next path] lastPathComponent]];
			if(scan)
			{
				[skipDirectories addObject:[next path]];
				[scan separateSubDirFiles];
				[scan setSkipDirectories:skipDirectories];
				[scan setGivesResults:results != nil];
			}
			else
			{
				/*State whether we care for results*/
				if(results != nil)
					[next getSubFileMetasWithDelegate:self skipDirectories:skipDirectories];
				else
					[next scanForNewFilesWithDelegate:self skipDirectories:skipDirectories];				
			}
			/*remove this item*/
			[remaining removeObjectAtIndex:0];
		}
		else
			/*We are done, send results and quit*/
			[self sendResults];
	}
	@catch(NSException *e)
	{
		[SapphireApplianceController logException:e];
	}
}

@end
