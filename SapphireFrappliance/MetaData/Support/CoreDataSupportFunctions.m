/*
 * SapphireBasicDirectoryFunctions.m
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

#import "CoreDataSupportFunctions.h"

NSArray *doFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate)
{
	return doSortedFetchRequest(entityName, context, predicate, nil);
}

NSManagedObject *doSingleFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate)
{
	NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:description];
	[request setFetchLimit:1];
	
	if(predicate != nil)
		[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error != nil)
		SapphireLog(SapphireLogTypeMetadataStore, SapphireLogLevelError, @"Single Fetch error: %@", error);
	[request release];
	
	if([array count])
		return [array objectAtIndex:0];
	
	return nil;
}

NSArray *doSortedFetchRequest(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate, NSSortDescriptor *sort)
{
	NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:description];
	
	if(predicate != nil)
		[request setPredicate:predicate];
	
	if(sort != nil)
		[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error != nil)
		SapphireLog(SapphireLogTypeMetadataStore, SapphireLogLevelError, @"Sorted Fetch error: %@", error);
	[request release];
	
	return array;
}

BOOL entityExists(NSString *entityName, NSManagedObjectContext *context, NSPredicate *predicate)
{
	NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:description];
	[request setFetchLimit:1];
	
	if(predicate != nil)
		[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error != nil)
		SapphireLog(SapphireLogTypeMetadataStore, SapphireLogLevelError, @"Exist error: %@", error);
	[request release];
	
	if([array count])
		return YES;
	
	return NO;
}
