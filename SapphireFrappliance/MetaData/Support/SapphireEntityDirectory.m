/*
 * SapphireEntityDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on May 26, 2008.
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

#import "SapphireEntityDirectory.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "NSManagedObject-Extensions.h"

@implementation SapphireEntityDirectory

- (id)initWithEntityFetch:(EntityFetchFunction)fetch inContext:(NSManagedObjectContext *)context;
{
	self = [super init];
	if(self == nil)
		return self;
	
	fetchFunction = fetch;
	moc = [context retain];
	nameKey = [@"name" retain];
	Basic_Directory_Function_Inits
	
	return self;
}

- (void) dealloc
{
	[moc release];
	[entities release];
	[nameKey release];
	[fetchPredicate release];
	[path release];
	[coverArtPath release];
	[notificationName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (void)setNameKey:(NSString *)key
{
	[nameKey release];
	nameKey = [key retain];
}

- (NSArray *)files
{
	return [NSArray array];
}

- (NSArray *)directories
{
	return [[entities allKeys] sortedArrayUsingSelector:@selector(nameCompare:)];
}

- (NSArray *)metaFiles
{
	NSArray *entityList = fetchFunction(moc, filterPredicate);;
	NSArray *entityIDs = [entityList valueForKeyPath:@"@distinctUnionOfSets.movies.objectID"];
	if([entityIDs count])
	{
		NSPredicate *entPred = [NSPredicate predicateWithFormat:@"movie IN %@", entityIDs];
		return doFetchRequest(SapphireFileMetaDataName, moc, entPred);
	}
	return [NSArray array];
}

- (NSPredicate *)metaFileFetchPredicate
{
	return fetchPredicate;
}

- (void)setMetaFileFetchPredicate:(NSPredicate *)predicate
{
	[fetchPredicate release];
	fetchPredicate = [predicate retain];
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	return nil;
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	id <SapphireDirectory> ret = [entities objectForKey:directory];
	[ret setFilterPredicate:filterPredicate];
	return ret;
}

- (void)reloadDirectoryContents
{
	NSArray *objects = fetchFunction(moc, filterPredicate);
	int i, count = [objects count];
	NSMutableDictionary *newData = [[NSMutableDictionary alloc] init];
	for(i=0; i<count; i++)
	{
		id obj = [objects objectAtIndex:i];
		NSString *key = [obj valueForKey:nameKey];
		if(key != nil)
			[newData setObject:obj forKey:key];
	}
	[entities release];
	entities = [[NSDictionary alloc] initWithDictionary:newData];
	[newData release];
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
	
	objEnum = [entities objectEnumerator];
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
