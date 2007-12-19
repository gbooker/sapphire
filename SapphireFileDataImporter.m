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
#import "SapphireMetaData.h"
#include <sys/types.h>
#include <sys/stat.h>
#include "SapphireImportHelper.h"

//Single Attributes
#define MEDIA_TVSHOW_XML_QUERY		@"/media[@type='TV Show']/text()"
#define MEDIA_MOVIE_XML_QUERY		@"/media[@type='Movie']/text()"
#define SUMMARY_XML_QUERY			@"/media/summary/text()"
#define DESCRIPTION_XML_QUERY		@"/media/description/text()"
#define	PUBLISHER_XML_QUERY			@"/media/publisher/text()"
#define COPYRIGHT_XML_QUERY			@"/media/copyright/text()"
#define USER_RATING_XML_QUERY		@"/media/userStarRating/text()"
#define	RATING_XML_QUERY			@"/media/rating/text()"
#define SERIES_NAME_XML_QUERY		@"/media/seriesName/text()"
#define BROADCASTER_XML_QUERY		@"/media/broadcaster/text()"
#define EPISODE_NUMBER_XML_QUERY	@"/media/episodeNumber/text()"
#define EPISODE_XML_QUERY			@"/media/episode/text()"
#define SEASON_XML_QUERY			@"/media/season/text()"
#define PUBLISHED_XML_QUERY			@"/media/published/text()"
//Multi Attributes		
#define TITLE_XML_QUERY				@"/media/title/text()"
#define GENRES_XML_QUERY			@"/media/genres/genre/text()"
#define CAST_XML_QUERY				@"/media/cast/name/text()"
#define DIRECTORS_XML_QUERY			@"/media/directors/name/text()"
#define PRODUCERS_XML_QUERY			@"/media/producers/name/text()"

@interface SapphireFileDataImporter (private)
- (void)importXMLFile:(NSString *)xmlFileName forMeta: (SapphireFileMetaData *) fileMeta ;
@end

@implementation SapphireFileDataImporter

/*Information to make the XML import easier*/
static NSDictionary *xmlSingleAttributes = nil;
static NSDictionary *xmlMultiAttributes = nil;

+(void) initialize
{
	xmlSingleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		META_TITLE_KEY,					TITLE_XML_QUERY,
		META_SUMMARY_KEY,				SUMMARY_XML_QUERY,
		META_DESCRIPTION_KEY,			DESCRIPTION_XML_QUERY,
		@"Publisher",					PUBLISHER_XML_QUERY,
		META_COPYRIGHT_KEY,				COPYRIGHT_XML_QUERY,
		META_SHOW_FAVORITE_RATING_KEY,	USER_RATING_XML_QUERY,
		META_SHOW_RATING_KEY,			RATING_XML_QUERY,
		META_SHOW_NAME_KEY,				SERIES_NAME_XML_QUERY,
		META_SHOW_BROADCASTER_KEY,		BROADCASTER_XML_QUERY,
		META_ABSOLUTE_EP_NUMBER_KEY,	EPISODE_NUMBER_XML_QUERY,
		META_EPISODE_NUMBER_KEY,		EPISODE_XML_QUERY,
		META_SEASON_NUMBER_KEY,			SEASON_XML_QUERY,
		META_SHOW_PUBLISHED_DATE_KEY,	PUBLISHED_XML_QUERY,nil] ;
	xmlMultiAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Genres",				GENRES_XML_QUERY,
		@"Cast",				CAST_XML_QUERY,
		@"Producers" ,			PRODUCERS_XML_QUERY,
		@"Directors",			DIRECTORS_XML_QUERY,nil];
}

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
	[dataMenu release];
	[super dealloc];
}


- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[dataMenu release];
	dataMenu = [theDataMenu retain];
}

- (BOOL) importMetaData:(id <SapphireFileMetaDataProtocol>)metaData
{
	/*Initialization*/
	BOOL ret = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	/*Get the file*/
	/*Check for XML file*/
	NSString * xmlFilePath=[metaData path] ;
	BOOL xmlPathIsDir = NO;
	xmlFilePath=[[xmlFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
	if([fm fileExistsAtPath:xmlFilePath isDirectory:&xmlPathIsDir] && !xmlPathIsDir)
	{
		/*Check modification date on XML file*/
		struct stat sb;
		memset(&sb, 0, sizeof(struct stat));
		stat([xmlFilePath fileSystemRepresentation], &sb);
		long modTime = sb.st_mtimespec.tv_sec;
		long oldTime = [metaData importedTimeFromSource:META_XML_IMPORT_KEY];
		if(oldTime != modTime)
		{
			/*Import the XML file and update counts*/
			[self importXMLFile:xmlFilePath forMeta:metaData] ;
			xmlFileCount++ ;
			ret = YES;
		}
	}
	/*Import file if necessary*/
	if([metaData needsUpdating])
	{
		[[SapphireImportHelper sharedHelper] importFileData:metaData inform:dataMenu];
		[dataMenu itemImportBackgrounded];
	}
	/*Return whether we imported or not*/
	return ret;
}

- (NSString *)completionText
{
	return BRLocalizedString(@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported", @"End text after import of files is complete");
}

- (void)importXMLFile:(NSString *)xmlFileName forMeta: (SapphireFileMetaData *) fileMeta
{
	/*Read the XML document*/
	NSURL *url = [NSURL fileURLWithPath:xmlFileName];
	NSError *error = nil;
	NSMutableDictionary * metaData=[NSMutableDictionary dictionary];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error];
	NSXMLElement *root = [document rootElement];
	if(!root)
		return;
/*
	NSString *type = [[root attributeForName:@"type"] stringValue];
	//Need to catch the media type {"TV Show" , "Movie"}
	if(type!=nil)metaData
*/
	/*Import single attribute items*/
	NSEnumerator *keyEnum = [xmlSingleAttributes keyEnumerator];
	NSString *key = nil;
	
	while((key = [keyEnum nextObject]) != nil)
	{
		/*Search for the attribute*/
		NSArray *objects = [root objectsForXQuery:key error:&error];
		if([objects count])
		{
			/*Import the attribute*/
			[metaData setObject:[[objects objectAtIndex:0] stringValue] forKey:[xmlSingleAttributes objectForKey:key]] ;
		}
    }
	/*Search for multi attribute items*/
	keyEnum = [xmlMultiAttributes keyEnumerator];
	while((key = [keyEnum nextObject]) != nil)
	{
		/*Search for the attribute*/
		NSArray *objects = [root objectsForXQuery:key error:&error];
		int count = [objects count];
		NSMutableArray *newData= nil;
		if(!count)
			continue;
		/*Itterate through the attribute's values*/
		newData = [NSMutableArray arrayWithCapacity:count];
		NSEnumerator *objectsEnum = [objects objectEnumerator];
		NSXMLNode *node = nil;
		while((node = [objectsEnum nextObject]) != nil)
		{
			/*Add each value*/
			[newData addObject:[node stringValue]];
		}
		/*Import the attribute*/
		[metaData setObject:newData forKey:[xmlMultiAttributes objectForKey:key]] ;
	}
	/*Special cases*/
	/*The air date*/
	NSString *value = [metaData objectForKey:META_SHOW_AIR_DATE];
	if(value != nil)
	{
		/*Change date string to a number*/
		[metaData removeObjectForKey:META_SHOW_AIR_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[metaData setObject:newValue forKey:META_SHOW_AIR_DATE];
	}
	/*The aquired date*/
	value = [metaData objectForKey:META_SHOW_AQUIRED_DATE];
	if(value != nil)
	{
		/*Change date sttring to a number*/
		[metaData removeObjectForKey:META_SHOW_AQUIRED_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[metaData setObject:newValue forKey:META_SHOW_AQUIRED_DATE];
	}
	/*Values which need to be converted to numbers*/
	NSArray *convertToNumbers = [NSArray arrayWithObjects:META_SHOW_FAVORITE_RATING_KEY, META_ABSOLUTE_EP_NUMBER_KEY, META_SEASON_NUMBER_KEY, META_EPISODE_NUMBER_KEY, nil];
	NSEnumerator *numEnum = [convertToNumbers objectEnumerator];
	while((key = [numEnum nextObject]) != nil)
	{
		/*Check for presence of value*/
		NSString *value = [metaData objectForKey:key];
		if(value != nil)
		{
			/*Convert to a number, either a double or int, depending on value*/
			double newValue = [value doubleValue];
			NSNumber *newNum = [NSNumber numberWithInt:[value intValue]];
			if(newValue != round(newValue))
				newNum = [NSNumber numberWithDouble:newValue];
			[metaData setObject:newNum forKey:key];
		}
	}
	/*Update modification date*/
	struct stat sb;
	memset(&sb, 0, sizeof(struct stat));
	stat([xmlFileName fileSystemRepresentation], &sb);
	long modTime = sb.st_mtimespec.tv_sec;
	/*Import into metadata*/
	[fileMeta importInfo: metaData fromSource:META_XML_IMPORT_KEY withTime:modTime];
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Populate File Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will populate Sapphire's File data.  This proceedure may take a while, but you may cancel at any time.", @"Description of the import processes");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Populating Data", @"Button");
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
}
@end
