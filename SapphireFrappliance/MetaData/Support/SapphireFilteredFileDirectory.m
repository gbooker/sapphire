/*
 * SapphireFilteredFileDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 2, 2008.
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

#import "SapphireFilteredFileDirectory.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "SapphireFileSorter.h"
#import "NSManagedObject-Extensions.h"

@implementation SapphireFilteredFileDirectory

- (id)initWithPredicate:(NSPredicate *)pred Context:(NSManagedObjectContext *)context
{
	self = [super init];
	if(self == nil)
		return self;
	
	moc = [context retain];
	fetchPredicate = [pred retain];
	entities = [[NSMutableArray alloc] init];
	entityLookup = [[NSMutableDictionary alloc] init];
	sortMethod = 0;
	Basic_Directory_Function_Inits
	
	return self;
}

- (void) dealloc
{
	[moc release];
	[fetchPredicate release];
	[entities release];
	[entityLookup release];
	[path release];
	[coverArtPath release];
	[sorters release];
	[notificationName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (NSArray *)files
{
	return entities;
}

- (NSArray *)directories
{
	return [NSArray array];
}

- (NSArray *)metaFiles
{
	NSPredicate *myPred;
	if(filterPredicate != nil)
		myPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filterPredicate, fetchPredicate, nil]];
	else
		myPred = fetchPredicate;
	return doFetchRequest(SapphireFileMetaDataName, moc, myPred);
}

- (void)setFileSorters:(NSArray *)sorts
{
	[sorters release];
	sorters = [sorts retain];
}

- (NSArray *)fileSorters
{
	return sorters;
}

- (void)setSortMethodValue:(int)value_
{
	sortMethod = value_;
}

- (int)sortMethodValue
{
	return sortMethod;
}

- (NSPredicate *)metaFileFetchPredicate
{
	return fetchPredicate;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	return [entityLookup objectForKey:file];
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	return nil;
}

- (void)reloadDirectoryContents
{
	[entities removeAllObjects];
	[entityLookup removeAllObjects];
	NSMutableArray *objects = [[self metaFiles] mutableCopy];
	[SapphireFileSorter sortFiles:objects withSorter:sortMethod inAllowedSorts:sorters];
	int i, count = [objects count];
	for(i=0; i<count; i++)
	{
		SapphireFileMetaData *obj = [objects objectAtIndex:i];
		NSString *key = [obj path];
		if(obj != nil)
		{
			[entityLookup setObject:obj forKey:key];
			[entities addObject:key];
		}
	}
	[objects release];
	[delegate directoryContentsChanged];
}

- (void)setPath:(NSString *)newPath
{
	[path release];
	path = [newPath retain];
}

- (NSString *)path
{
	return path;
}

- (void)setNotificationName:(NSString *)notification
{
	[notificationName release];
	notificationName = [notification retain];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	[nc addObserver:self selector:@selector(clearPredicateCache) name:notificationName object:nil];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return moc;
}

- (BOOL)objectIsDeleted
{
	return NO;
}

- (void)setCoverArtPath:(NSString *)newPath
{
	[coverArtPath release];
	coverArtPath = [newPath retain];
}

- (NSString *)coverArtPath
{
	return coverArtPath;
}

- (void)faultAllObjects
{
	NSEnumerator *objEnum;
	NSManagedObject *obj;
	
	objEnum = [entityLookup objectEnumerator];
	while((obj = [objEnum nextObject]) != nil)
	{
		[obj faultOjbectInContext:moc];
	}
}

- (id <SapphireDirectory>)parentDirectory
{
	return nil;
}

#include "SapphireBasicDirectoryFunctions.h"

@end
