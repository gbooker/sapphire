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


@implementation SapphireMultipleImporter

- (id)initWithImporters:(NSArray *)importerList
{
	self = [super init];
	if(self == nil)
		return nil;
	
	importers = [importerList retain];
	importIndex = 0;
	
	return self;
}

- (void) dealloc
{
	[importers release];
	[super dealloc];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	ImportState ret = resumedState;
	int count = [importers count];
	for(;importIndex < count; importIndex++)
	{
		id <SapphireImporter> importer = [importers objectAtIndex:importIndex];
		ImportState result = [importer importMetaData:metaData path:path];
		switch(result)
		{
			case IMPORT_STATE_NEEDS_SUSPEND:
				resumedState = ret;
				return result;
			case IMPORT_STATE_BACKGROUND:
				ret = result;
				break;
			case IMPORT_STATE_UPDATED:
				if(ret != IMPORT_STATE_BACKGROUND)
					ret = result;
				break;
		}
	}
	
	importIndex = 0;
	resumedState = IMPORT_STATE_NOT_UPDATED;
	return ret;
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[importers makeObjectsPerformSelector:@selector(setImporterDataMenu:) withObject:theDataMenu];
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

- (void)exhumedChooser:(BRLayerController *)chooser withContext:(id)context
{
}

@end
