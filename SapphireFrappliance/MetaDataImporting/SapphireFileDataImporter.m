/*
 * SapphireFileDataImporter.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 24, 2007.
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

#import "SapphireFileDataImporter.h"
#import "SapphireFileMetaData.h"
#include "SapphireImportHelper.h"

@implementation SapphireFileDataImporter

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	xmlFileCount=0;
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	dataMenu = theDataMenu;
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	/*Import file if necessary*/
	if([metaData needsUpdating])
	{
		[[SapphireImportHelper sharedHelperForContext:[metaData managedObjectContext]] importFileData:metaData inform:dataMenu];
		return IMPORT_STATE_BACKGROUND;
	}
	/*Return whether we imported or not*/
	return IMPORT_STATE_NOT_UPDATED;
}

- (NSString *)completionText
{
	return BRLocalizedString(@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported", @"End text after import of files is complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Populate File Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will populate Sapphire's File data.  This procedure may take a while, but you may cancel at any time.", @"Description of the import processes");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Populating Data", @"Button");
}

- (void)wasExhumed
{
}
@end
