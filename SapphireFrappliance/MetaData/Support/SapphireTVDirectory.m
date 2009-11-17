/*
 * SapphireTVDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on Nov. 16, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireTVDirectory.h"
#import "SapphireFileMetaData.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireEpisode.h"
#import "SapphireTVShow.h"
#import "SapphireApplianceController.h"
#import "SapphireCustomVirtualDirectoryImporter.h"
#import "SapphireCustomVirtualDirectory.h"
#import "SapphireFilteredFileDirectory.h"

@implementation SapphireTVDirectory

NSArray *showEntityFetch(NSManagedObjectContext *moc, NSPredicate *filterPredicate)
{
	NSPredicate *showPred = nil;
	if(filterPredicate != nil)
	{
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"tvEpisode != nil"];
		NSPredicate *finalPred;
		if(filterPredicate == nil)
			finalPred = fetchPredicate;
		else
			finalPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filterPredicate, fetchPredicate, nil]];
		NSArray *files = doFetchRequest(SapphireFileMetaDataName, moc, finalPred);
		
		NSSet *epIds = [NSSet setWithArray:[files valueForKeyPath:@"tvEpisode.objectID"]];
		NSPredicate *epPred = [NSPredicate predicateWithFormat:@"SELF IN %@", epIds];
		NSArray *episodes = doFetchRequest(SapphireEpisodeName, moc, epPred);
		
		NSSet *showIds = [NSSet setWithArray:[episodes valueForKeyPath:@"tvShow.objectID"]];
		showPred = [NSPredicate predicateWithFormat:@"SELF IN %@", showIds];
	}
	return doFetchRequest(SapphireTVShowName, moc, showPred);
}

- (id)initWithContext:(NSManagedObjectContext *)context
{
	self = [super initWithEntityFetch:showEntityFetch inContext:context];
	if (self != nil) {
		[self setMetaFileFetchPredicate:[NSPredicate predicateWithFormat:@"tvEpisode != nil"]];
	}
	return self;
}

- (void) dealloc
{
	[customDirectories release];
	[customDirectoryNames release];
	[virtualDirs release];
	[super dealloc];
}

- (NSArray *)directories
{
	NSArray *normalEntries = [super directories];
	
	return [normalEntries arrayByAddingObjectsFromArray:customDirectoryNames];
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	id <SapphireDirectory> ret = [super metaDataForDirectory:directory];
	if(ret != nil)
		return ret;
	
	int index = [customDirectoryNames indexOfObject:directory];
	if(index != NSNotFound)
		return [customDirectories objectAtIndex:index];
	
	return nil;
}

- (void)reloadDirectoryContents
{
	/*Import any defined movie virtual directories*/
	NSArray *newVirtualDirs = [[SapphireApplianceController customVirtualDirectoryImporter] tvShowVirtualDirectories];
	if(![virtualDirs isEqualToArray:newVirtualDirs])
	{
		[virtualDirs release];
		[customDirectoryNames release];
		[customDirectories release];
		virtualDirs = [newVirtualDirs retain];
		customDirectoryNames = [[NSMutableArray alloc] init];
		customDirectories = [[NSMutableArray alloc] init];
		
		NSString *tvPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TV" ofType:@"png"];
		NSEnumerator *mvdEnum = [newVirtualDirs objectEnumerator];
		SapphireCustomVirtualDirectory *virtualDir;
		while((virtualDir = [mvdEnum nextObject]) != nil)
		{
			SapphireFilteredFileDirectory *custom = [[SapphireFilteredFileDirectory alloc] initWithPredicate:[virtualDir predicate] Context:moc];
			[customDirectories addObject:custom];
			[customDirectoryNames addObject:[virtualDir title]];
			[custom setPath:[[VIRTUAL_DIR_ROOT_PATH stringByAppendingString:@"/"] stringByAppendingString:[virtualDir description]]];
			[custom setCoverArtPath:tvPath]; // Change this to be part of the XML?
			[custom setFileSorters:[SapphireTVShow sortMethods]];
			[custom release];
		}
	}
	
	[customDirectories makeObjectsPerformSelector:@selector(setFilterPredicate:) withObject:filterPredicate];
	[super reloadDirectoryContents];
}

@end
