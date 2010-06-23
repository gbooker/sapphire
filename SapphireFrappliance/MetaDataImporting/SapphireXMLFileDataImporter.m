/*
 * SapphireXMLFileDataImporter.h
 * Sapphire
 *
 * Created by pnmerrill on Jan. 21, 2008.
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

#import "SapphireXMLFileDataImporter.h"
#import "SapphireFileMetaData.h"
#import "SapphireMediaPreview.h"
#import "SapphireXMLData.h"
#import "NSImage-Extensions.h"
#include <sys/types.h>
#include <sys/stat.h>

//Single Attributes
#define TITLE_XML_QUERY				@"/media/title/text()"
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
#define SEC_EPISODE_XML_QUERY		@"/media/secondEpisode/text()"
#define SEASON_XML_QUERY			@"/media/season/text()"
#define PUBLISHED_XML_QUERY			@"/media/published/text()"
#define SEARCH_SEASON_XML_QUERY		@"/media/searchSeason/text()"
#define SEARCH_SEC_EPISODE_XML_QUERY	@"/media/searchSecondEpisode/text()"
#define SEARCH_EPISODE_XML_QUERY	@"/media/searchEpisode/text()"
#define SEARCH_IMDB_XML_QUERY		@"/media/searchIMDB/text()"
#define SCREENCAP_XML_QUERY			@"/media/imageTime/text()"
#define MOVIE_SORT_TITLE_XML_QUERY	@"/media/movieSortTitle/text()"

//Multi Attributes		
#define GENRES_XML_QUERY			@"/media/genres/genre/text()"
#define CAST_XML_QUERY				@"/media/cast/name/text()"
#define DIRECTORS_XML_QUERY			@"/media/directors/name/text()"
#define PRODUCERS_XML_QUERY			@"/media/producers/name/text()"

@implementation SapphireXMLFileDataImporter

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
						   META_ABSOLUTE_EP_NUMBER_KEY,		EPISODE_NUMBER_XML_QUERY,
						   META_EPISODE_NUMBER_KEY,			EPISODE_XML_QUERY,
						   META_EPISODE_2_NUMBER_KEY,		SEC_EPISODE_XML_QUERY,
						   META_SEASON_NUMBER_KEY,			SEASON_XML_QUERY,
						   META_SHOW_AIR_DATE,				PUBLISHED_XML_QUERY,
						   META_SEARCH_SEASON_NUMBER_KEY,	SEARCH_SEASON_XML_QUERY,
						   META_SEARCH_EPISODE_NUMBER_KEY,	SEARCH_EPISODE_XML_QUERY,
						   META_SEARCH_EPISODE_2_NUMBER_KEY,SEARCH_SEC_EPISODE_XML_QUERY,
						   META_SEARCH_IMDB_NUMBER_KEY,		SEARCH_IMDB_XML_QUERY,
						   META_MOVIE_SORT_TITLE_KEY,		MOVIE_SORT_TITLE_XML_QUERY,
						   nil] ;
	xmlMultiAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
						  META_MOVIE_GENRES_KEY,			GENRES_XML_QUERY,
						  META_MOVIE_CAST_KEY,				CAST_XML_QUERY,
						  @"Producers",						PRODUCERS_XML_QUERY,
						  META_MOVIE_DIRECTOR_KEY,			DIRECTORS_XML_QUERY,nil];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	/*Get the file*/
	/*Check for XML file*/
	BOOL xmlPathIsDir = NO;
	NSString *extLessPath = path;
	if([metaData fileContainerTypeValue] != FILE_CONTAINER_TYPE_VIDEO_TS)
		extLessPath = [extLessPath stringByDeletingPathExtension];

	NSString *xmlFilePath=[extLessPath stringByAppendingPathExtension:@"xml"];
	SapphireXMLData *xml = [metaData xmlData];
	if(![fm fileExistsAtPath:xmlFilePath isDirectory:&xmlPathIsDir] || xmlPathIsDir)
	{
		if(xml == nil)
			return ImportStateNotUpdated;
		
		[[xml managedObjectContext] deleteObject:xml];
		return ImportStateUpdated;
	}

	/*Check modification date on XML file*/
	struct stat sb;
	memset(&sb, 0, sizeof(struct stat));
	stat([xmlFilePath fileSystemRepresentation], &sb);
	long modTime = sb.st_mtimespec.tv_sec;
	long oldTime = [metaData importedTimeFromSource:IMPORT_TYPE_XML_MASK];
	if(oldTime == modTime)
		return ImportStateNotUpdated;

	/*Read the XML document*/
	NSURL *url = [NSURL fileURLWithPath:xmlFilePath];
	NSError *error = nil;
	NSMutableDictionary *newMetaData=[NSMutableDictionary dictionary];
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error] autorelease];
	NSXMLElement *root = [document rootElement];
	if(!root)
		return ImportStateNotUpdated;
	
	NSString *type = [[root attributeForName:@"type"] stringValue];
	FileClass fclass = FILE_CLASS_UNKNOWN;
	//Need to catch the media type {"TV Show" , "Movie"}
	if(type!=nil)
	{
		if([type isEqualToString:@"TV Show"])
			fclass = FILE_CLASS_TV_SHOW;
		else if([type isEqualToString:@"Movie"])
			fclass = FILE_CLASS_MOVIE;
		
		if(fclass != FILE_CLASS_UNKNOWN)
			[newMetaData setObject:[NSNumber numberWithInt:fclass] forKey:FILE_CLASS_KEY];
	}
		
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
			[newMetaData setObject:[[objects objectAtIndex:0] stringValue] forKey:[xmlSingleAttributes objectForKey:key]] ;
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
		[newMetaData setObject:newData forKey:[xmlMultiAttributes objectForKey:key]] ;
	}
	/*Special cases*/
	/* Screen Cap */
	NSArray *imageCaps = [root objectsForXQuery:SCREENCAP_XML_QUERY error:&error];
	if ( [imageCaps count] && [metaData fileContainerType] == FILE_CONTAINER_TYPE_QT_MOVIE )
	{
		unsigned int hour;
		unsigned int minute;
		unsigned int second;
		
		sscanf( [[[imageCaps objectAtIndex:0] stringValue] cString], "%u:%u:%u", &hour, &minute, &second );
		NSData * image = [NSImage imageFromMovie: [metaData path] atTime: ((60*60*hour) + (60*minute) + second)];
		[image writeToFile:[metaData coverArtPath] atomically:YES];
	}

	/*The air date*/
	NSString *value = [newMetaData objectForKey:META_SHOW_AIR_DATE];
	if(value != nil)
	{
		/*Change date string to a number*/
		[newMetaData removeObjectForKey:META_SHOW_AIR_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[newMetaData setObject:newValue forKey:META_SHOW_AIR_DATE];
	}
	/*The aquired date*/
	value = [newMetaData objectForKey:META_SHOW_AQUIRED_DATE];
	if(value != nil)
	{
		/*Change date sttring to a number*/
		[newMetaData removeObjectForKey:META_SHOW_AQUIRED_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[newMetaData setObject:newValue forKey:META_SHOW_AQUIRED_DATE];
	}
	/*Values which need to be converted to numbers*/
	NSArray *convertToNumbers = [NSArray arrayWithObjects:META_SHOW_FAVORITE_RATING_KEY, META_ABSOLUTE_EP_NUMBER_KEY, META_SEASON_NUMBER_KEY, META_EPISODE_NUMBER_KEY, META_EPISODE_2_NUMBER_KEY, META_SEARCH_SEASON_NUMBER_KEY, META_SEARCH_EPISODE_NUMBER_KEY, META_SEARCH_EPISODE_2_NUMBER_KEY, META_SEARCH_IMDB_NUMBER_KEY, nil];
	NSEnumerator *numEnum = [convertToNumbers objectEnumerator];
	while((key = [numEnum nextObject]) != nil)
	{
		/*Check for presence of value*/
		NSString *value = [newMetaData objectForKey:key];
		if(value != nil)
		{
			/*Convert to a number, either a double or int, depending on value*/
			double newValue = [value doubleValue];
			NSNumber *newNum = [NSNumber numberWithInt:[value intValue]];
			if(newValue != round(newValue))
				newNum = [NSNumber numberWithDouble:newValue];
			[newMetaData setObject:newNum forKey:key];
		}
	}
	/*Import into metadata*/
	if(xml == nil)
	{
		xml = [NSEntityDescription insertNewObjectForEntityForName:SapphireXMLDataName inManagedObjectContext:[metaData managedObjectContext]];
		[metaData setXmlData:xml];
	}
	[xml insertDictionary:newMetaData];
	xml.modified = [NSDate dateWithTimeIntervalSince1970:modTime];
	return ImportStateUpdated;
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
	return BRLocalizedString(@"Start Populating XML Data", @"Button");
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
