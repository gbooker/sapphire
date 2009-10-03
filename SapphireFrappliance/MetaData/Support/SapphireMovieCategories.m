/*
 * SapphireMovieCategories.m
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

#import "SapphireMovieCategories.h"
#import "SapphireMovie.h"
#import "SapphireObjectDirectory.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "NSManagedObject-Extensions.h"

@implementation SapphireMovieCategories

- (id)initWithMovie:(SapphireMovie *)mov
{
	self = [super init];
	if(self == nil)
		return self;
	
	movie = [mov retain];
	
	SapphireObjectDirectory *cast = [[SapphireObjectDirectory alloc] initWithDirectory:movie andSubDirKey:@"orderedCast"];
	SapphireObjectDirectory *directors = [[SapphireObjectDirectory alloc] initWithDirectory:movie andSubDirKey:@"orderedDirectors"];
	SapphireObjectDirectory *genres = [[SapphireObjectDirectory alloc] initWithDirectory:movie andSubDirKey:@"orderedGenres"];
	
	categories = [NSDictionary dictionaryWithObjectsAndKeys:
				  cast, @"Cast",
				  directors, @"Directors",
				  genres, @"Genres",
				  nil];
	
	[cast release];
	[directors release];
	[genres release];
	Basic_Directory_Function_Inits

	return self;
}

- (void) dealloc
{
	[movie release];
	[categories release];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (NSArray *)files
{
	return [NSArray array];
}

- (NSArray *)directories
{
	return [[categories allKeys] sortedArrayUsingSelector:@selector(nameCompare:)];
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
	return [categories objectForKey:directory];
}

- (void)reloadDirectoryContents
{
}

- (NSString *)path
{
	return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [movie managedObjectContext];
}

- (NSString *)coverArtPath
{
	return nil;
}

- (void)faultAllObjects
{
	[movie faultOjbectInContext:[movie managedObjectContext]];
}

- (id <SapphireDirectory>)parentDirectory
{
	return nil;
}


#include "SapphireBasicDirectoryFunctions.h"

@end
