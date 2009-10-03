/*
 * SapphireBasicDirectoryFunctions.h
 * Sapphire
 *
 * Created by Graham Booker on Apr. 9, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

/* This file contains functions which are commonly used for all virtual directories.
   It assumes the definition of a few instance variables, which can be set using defines in SapphireBasicDirectoryFunctionsDefines. */

#ifndef RECURSIVE_FUNCTIONS_ALREADY_DEFINED
- (void)invokeOnAllFiles:(NSInvocation *)fileInv
{
	NSArray *files = [self metaFiles];
	if([files count])
	{
		SapphireFileMetaData *file;
		NSEnumerator *fileEnum = [files objectEnumerator];
		while((file = [fileEnum nextObject]) != nil)
		{
			[fileInv invokeWithTarget:file];
		}
	}
}

- (BOOL)checkPredicate:(NSPredicate *)pred
{
	NSPredicate *fetchPred = [self metaFileFetchPredicate];
	if(fetchPred != nil)
	{
		NSPredicate *final;
		if(pred == nil)
			final = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:fetchPred, filterPredicate, nil]];
		else
			final = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pred, fetchPred, filterPredicate, nil]];
		return entityExists(SapphireFileMetaDataName, [self managedObjectContext], final);	
	}
	
	NSArray *files = [self files];
	int i, count = [files count];
	for(i=0; i<count; i++)
	{
		SapphireFileMetaData *file = [self metaDataForFile:[files objectAtIndex:i]];
		if(file != nil && [pred evaluateWithObject:file])
			return YES;
	}
	
	NSArray *dirs = [self directories];
	count = [files count];
	for(i=0; i<count; i++)
	{
		id <SapphireDirectory> dir = [self metaDataForDirectory:[dirs objectAtIndex:i]];
		if(dir != nil && [dir containsFileMatchingPredicate:pred])
			return YES;
	}
	
	return NO;
}

- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
}

- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip
{
}

- (void)cancelImport
{
}

- (void)resumeImport
{
}

#endif

- (BOOL)containsFileMatchingPredicate:(NSPredicate *)pred
{
	NSString *cacheKey = [SapphireApplianceController keyForFilterPredicate:filterPredicate andCheckPredicate:pred];
	NSNumber *cache = [predicateCache objectForKey:cacheKey];
	if(cache != nil)
		return [cache boolValue];
	
	BOOL ret = [self checkPredicate:pred];
	cache = [NSNumber numberWithBool:ret];
	[predicateCache setObject:cache forKey:cacheKey];
	return ret;
}

- (BOOL)containsFileMatchingFilterPredicate:(NSPredicate *)pred
{
	NSString *cacheKey = [SapphireApplianceController keyForFilterPredicate:pred andCheckPredicate:nil];
	NSNumber *cache = [predicateCache objectForKey:cacheKey];
	if(cache != nil)
		return [cache boolValue];
	

	NSPredicate *tpred = filterPredicate;
	filterPredicate = nil;
	BOOL ret = [self checkPredicate:pred];
	filterPredicate = tpred;
	
	cache = [NSNumber numberWithBool:ret];
	[predicateCache setObject:cache forKey:cacheKey];

	return ret;
}

- (void)clearPredicateCache
{
	id <SapphireDirectory> myParentDir = [self parentDirectory];
	[predicateCache removeAllObjects];
/*	BOOL report = NO;
	if(watchedCache != nil)
	{
		BOOL oldWatched = [watchedCache boolValue];
		[watchedCache release];
		watchedCache = nil;
		BOOL doCheck = [myParentDir watched] != nil;
		if(doCheck && [self watchedValue] != oldWatched)
			report = YES;
	}
	if(favoriteCache != nil)
	{
		BOOL oldFavorite = [favoriteCache boolValue];
		[favoriteCache release];
		favoriteCache = nil;
		BOOL doCheck = !report && [myParentDir watched] != nil;
		if(doCheck && [self favoriteValue] != oldFavorite)
			report = YES;
	}
	if(report)*/
		[myParentDir clearPredicateCache];
}

- (void)setFilterPredicate:(NSPredicate *)predicate
{
	[filterPredicate release];
	filterPredicate = [predicate retain];
}

- (NSPredicate *)filterPredicate
{
	return filterPredicate;
}

- (id <SapphireMetaDataDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate
{
	[newDelegate retain];
	[delegate release];
	delegate = newDelegate;
	if(delegate == nil)
		[self faultAllObjects];
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;
{
	if(order != nil)
		*order = nil;
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[[self path] lastPathComponent], META_TITLE_KEY,
			nil];
}

- (void)setToReimportFromMaskValue:(int)mask
{
	SEL select = @selector(setToReimportFromMask:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[inv setSelector:select];
	NSNumber *num = [NSNumber numberWithInt:mask];
	[inv setArgument:&num atIndex:2];
	[self invokeOnAllFiles:inv];
	[SapphireMetaDataSupport save:[self managedObjectContext]];
}

- (void)setToReimportFromMask:(NSNumber *)mask
{
	[self setToReimportFromMaskValue:[mask intValue]];
}

- (void)clearMetaData
{
	SEL select = @selector(clearMetaData);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[inv setSelector:select];
	[self invokeOnAllFiles:inv];
	[SapphireMetaDataSupport save:[self managedObjectContext]];
}