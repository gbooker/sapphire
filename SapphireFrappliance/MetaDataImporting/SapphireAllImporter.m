/*
 * SapphireAllImporter.m
 * Sapphire
 *
 * Created by Graham Booker on Aug. 6, 2007.
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

#import "SapphireAllImporter.h"


@implementation SapphireAllImporter

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	return [super importMetaData:metaData path:path];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[super setImporterDataMenu:theDataMenu];
}

- (NSString *)completionText
{
	return BRLocalizedString(@"All available metadata has been imported", @"The group metadata import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Import All Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will import all the metadata it can find.  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of all meta import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Importing Data", @"Button");
}

- (void)wasExhumed
{
	[super wasExhumed];
}

@end
