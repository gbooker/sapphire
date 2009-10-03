/*
 * SapphireMovieCategoryDirectory.m
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

#import "SapphireObjectDirectory.h"
#import "SapphireCategoryDirectory.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "NSManagedObject-Extensions.h"

@implementation SapphireObjectDirectory

- (id)initWithDirectory:(NSManagedObject *)directory andSubDirKey:(NSString *)key
{
	self = [super init];
	if(self == nil)
		return self;
	
	containingDirectory = [directory retain];
	value = [key retain];
	cachedDirs = [[NSArray alloc] init];
	Basic_Directory_Function_Inits

	return self;
}

- (void) dealloc
{
	[containingDirectory release];
	[value release];
	[cachedDirs release];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (NSArray *)files
{
	return [NSArray array];
}

- (NSArray *)directories
{
	if(![cachedDirs count])
		return cachedDirs;

	return [cachedDirs valueForKey:@"name"];
}

- (NSArray *)metaFiles
{
	return [NSArray array];
}

- (NSPredicate *)metaFileFetchPredicate
{
	return nil;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	return nil;
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	if(![cachedDirs count])
		return nil;
	
	NSArray *candidates = [cachedDirs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", directory]];
	if([candidates count])
		return [candidates objectAtIndex:0];
	
	return nil;
}

- (void)reloadDirectoryContents
{
	[cachedDirs release];
	cachedDirs = [[containingDirectory valueForKeyPath:value] retain];
	[delegate directoryContentsChanged];
}

- (NSString *)path
{
	return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [containingDirectory managedObjectContext];
}

- (NSString *)coverArtPath
{
	return nil;
}

- (void)faultAllObjects
{
	[containingDirectory faultOjbectInContext:[containingDirectory managedObjectContext]];
}

- (id <SapphireDirectory>)parentDirectory
{
	return nil;
}

#include "SapphireBasicDirectoryFunctions.h"

@end
