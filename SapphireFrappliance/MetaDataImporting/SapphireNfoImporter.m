/*
 * SapphireNfoImporter.m
 * Sapphire
 *
 * Created by Graham Booker on Dec. 26, 2009.
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

#import "SapphireNfoImporter.h"
#import "SapphireFileMetaData.h"
#import "SapphireScraper.h"

@implementation SapphireNfoImporter

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	scraperNames = [[SapphireScraper allScrapperNames] retain];
	
	return self;
}

- (void)dealloc
{
	[scraperNames release];
	[super dealloc];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	/*Get the file*/
	/*Check for NFO file*/
	BOOL nfoPathIsDir = NO;
	NSString *extLessPath = path;
	if([metaData fileContainerTypeValue] != FILE_CONTAINER_TYPE_VIDEO_TS)
		extLessPath = [extLessPath stringByDeletingPathExtension];
	
	NSString *nfoFilePath=[extLessPath stringByAppendingPathExtension:@"nfo"];
	if(![fm fileExistsAtPath:nfoFilePath isDirectory:&nfoPathIsDir] || nfoPathIsDir)
		return ImportStateNotUpdated;
	
	if([metaData fileClassValue] != FILE_CLASS_UNKNOWN)
		return ImportStateNotUpdated;
	
	NSString *nfoContent = [NSString stringWithContentsOfFile:nfoFilePath];
	NSEnumerator *scraperNameEnum = [scraperNames objectEnumerator];
	NSString *scraperName;
	BOOL match = NO;
	while((scraperName = [scraperNameEnum nextObject]) != nil)
	{
		SapphireScraper *scraper = [SapphireScraper scrapperWithName:scraperName];
		
		if(!scraper)
			continue;
		
		if([[scraper searchResultsForNfoContent:nfoContent] length])
		{
			//Match!!!!
			if([[scraper contentType] isEqualToString:@"tvshows"])
			{
				[metaData setFileClassValue:FILE_CLASS_TV_SHOW];
				match = YES;
			}
			else if([[scraper contentType] isEqualToString:@"movies"])
			{
				[metaData setFileClassValue:FILE_CLASS_MOVIE];
				match = YES;
			}
			if(match)
				return ImportStateUpdated;
		}
	}
	
	return ImportStateNotUpdated;
}

- (void)setDelegate:(id <SapphireImporterDelegate>)delegate
{
	//No backgrounding here, so we don't need to tell the delegate anything
}

- (void)cancelImports
{
	//No backgrounding here, so nothing to do
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
	return BRLocalizedString(@"Start Populating NFO Data", @"Button");
}

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	//No choosers displayed
	return NO;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
}

@end
