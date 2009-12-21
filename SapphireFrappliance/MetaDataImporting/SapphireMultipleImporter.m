/*
 * SapphireMultipleImporter.m
 * Sapphire
 *
 * Created by Graham Booker on Aug. 29, 2007.
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

#import "SapphireMultipleImporter.h"

@interface SapphireMultipleImporterState : NSObject
{
@public
	int						completedMask;
	int						currentImportIndex;
	BOOL					updated;
	SapphireFileMetaData	*file;
}
- (id)initWithFile:(SapphireFileMetaData *)file;
@end

@implementation SapphireMultipleImporterState

- (id)initWithFile:(SapphireFileMetaData *)aFile
{
	self = [super init];
	if(!self)
		return self;
	
	file = [aFile retain];
	
	return self;
}

- (void) dealloc
{
	[file release];
	[super dealloc];
}

@end


@implementation SapphireMultipleImporter

- (id)initWithImporters:(NSArray *)importerList
{
	self = [super init];
	if(self == nil)
		return nil;
	
	importers = [importerList retain];
	[importerList makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
	pendingImports = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void) dealloc
{
	[importers makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
	[importers release];
	[pendingImports release];
	[super dealloc];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	int count = [importers count];
	SapphireMultipleImporterState *state = [pendingImports objectForKey:path];
	if(state == nil)
	{
		state = [[SapphireMultipleImporterState alloc] initWithFile:metaData];
		[pendingImports setObject:state forKey:path];
		[state release];		
	}
	ImportState ret = ImportStateNotUpdated;
	int importIndex;
	for(importIndex = state->currentImportIndex;importIndex < count; importIndex++)
	{
		id <SapphireImporter> importer = [importers objectAtIndex:importIndex];
		ImportState result = [importer importMetaData:metaData path:path];
		switch(result)
		{
			case ImportStateMultipleSuspend:
				state->currentImportIndex = importIndex;
				return result;
			case ImportStateBackground:
				ret = result;
				break;
			case ImportStateUpdated:
				if(ret != ImportStateBackground)
					ret = result;
				state->updated = YES;
			case ImportStateNotUpdated:
				state->completedMask |= 1 << importIndex;
		}
	}
	
	if(state->completedMask == (1 << count) -1)
		[pendingImports removeObjectForKey:path];
	else
		state->currentImportIndex = count;
	return ret;
}

- (void)setDelegate:(id <SapphireImporterDelegate>)aDelegate
{
	delegate = aDelegate;
}

- (void)cancelImports
{
	[importers makeObjectsPerformSelector:@selector(cancelImports)];
}

- (NSString *)completionText
{
	return @"";
}

- (NSString *)initialText
{
	return @"";
}

- (NSString *)informativeText
{
	return @"";
}

- (NSString *)buttonTitle
{
	return @"";
}

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	//No choosers displayed
	return NO;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
}

- (void)backgroundImporter:(id <SapphireImporter>)importer completedImportOnPath:(NSString *)path withState:(ImportState)status
{
	SapphireMultipleImporterState *state = [pendingImports objectForKey:path];
	if(!state)
		//Don't know what to do with you!
		return;
	
	int index = [importers indexOfObject:importer];
	if(index == NSNotFound)
		//Don't know what to do with you!
		return;
	
	state->completedMask |= 1 << index;
	if(status == ImportStateUpdated)
		state->updated = YES;
	
	if(status == ImportStateUserSkipped)
	{
		if(state->updated)
			status = ImportStateUpdated;
		[delegate backgroundImporter:self completedImportOnPath:path withState:status];
		return;
	}
	
	if(state->currentImportIndex == index)
	{
		state->currentImportIndex++;
		[self importMetaData:state->file path:path];
	}
	else if(state->completedMask == (1 << [importers count]) - 1)
	{	
		if(state->updated)
			status = ImportStateUpdated;
		[delegate backgroundImporter:self completedImportOnPath:path withState:status];
		[pendingImports removeObjectForKey:path];
	}
}

- (void)resumeWithPath:(NSString *)path
{
	[delegate resumeWithPath:path];
}

- (BOOL)canDisplayChooser
{
	return [delegate canDisplayChooser];
}

- (id)chooserScene
{
	return [delegate chooserScene];
}

- (void)displayChooser:(BRLayerController <SapphireChooser> *)chooser forImporter:(id <SapphireImporter>)importer withContext:(id)context
{
	[delegate displayChooser:chooser forImporter:importer withContext:context];
}


@end
