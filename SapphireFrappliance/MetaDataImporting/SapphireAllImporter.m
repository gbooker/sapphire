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
#import "SapphireXMLFileDataImporter.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireMovieImporter.h"
#import "SapphireNfoImporter.h"

@implementation SapphireAllImporter

- (id) init
{
	SapphireXMLFileDataImporter *xml = [[SapphireXMLFileDataImporter alloc] init];
	SapphireFileDataImporter *file = [[SapphireFileDataImporter alloc] init];
	SapphireNfoImporter *nfo = [[SapphireNfoImporter alloc] init];
	SapphireTVShowImporter *tv = [[SapphireTVShowImporter alloc] init];
	SapphireMovieImporter *movie = [[SapphireMovieImporter alloc] init];
	NSArray *ourImporters = [[NSArray alloc] initWithObjects:
							 xml,
							 nfo,
							 file,
							 tv,
							 movie,
							 nil];
	self = [super initWithImporters:ourImporters];
	[xml release];
	[file release];
	[nfo release];
	[tv release];
	[movie release];
	[ourImporters release];
	return self;
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
@end
