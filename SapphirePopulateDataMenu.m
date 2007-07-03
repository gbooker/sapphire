//
//  SapphirePopulateDataMenu.m
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphirePopulateDataMenu.h"
#import "SapphireMetaData.h"
#include <sys/types.h>
#include <sys/stat.h>

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

@interface SapphireImporterDataMenu (private)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)importNextItem:(NSTimer *)timer;
- (void)setCurrentFile:(NSString *)theCurrentFile;
@end


@implementation SapphirePopulateDataMenu

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



- (void)getItems
{
	importItems = [[meta subFileMetas] mutableCopy];
	xmlFileCount=0 ;
}

- (BOOL)doImport
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	return [fileMeta updateMetaData];
}

- (void)setCompletionText
{
	[self setText:@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported"];
}

- (void)importXMLFile:(NSString *)xmlFileName forMeta: (SapphireFileMetaData *) fileMeta
{
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
	NSEnumerator *keyEnum = [xmlSingleAttributes keyEnumerator];
	NSString *key = nil;
	
	while((key = [keyEnum nextObject]) != nil)
	{
		NSArray *objects = [root objectsForXQuery:key error:&error];
		if([objects count])
		{
			[metaData setObject:[[objects objectAtIndex:0] stringValue] forKey:[xmlSingleAttributes objectForKey:key]] ;
		}
    }
	keyEnum = [xmlMultiAttributes keyEnumerator];
	while((key = [keyEnum nextObject]) != nil)
	{
		NSArray *objects = [root objectsForXQuery:key error:&error];
		int count = [objects count];
		NSMutableArray *newData= nil;
		if(!count)
			continue;
		newData = [NSMutableArray arrayWithCapacity:count];
		NSEnumerator *objectsEnum = [objects objectEnumerator];
		NSXMLNode *node = nil;
		while((node = [objectsEnum nextObject]) != nil)
		{
			[newData addObject:[node stringValue]];
		}
		[metaData setObject:newData forKey:[xmlMultiAttributes objectForKey:key]] ;

	}
	//Special cases
	NSString *value = [metaData objectForKey:META_SHOW_AIR_DATE];
	if(value != nil)
	{
		[metaData removeObjectForKey:META_SHOW_AIR_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[metaData setObject:newValue forKey:META_SHOW_AIR_DATE];
	}
	value = [metaData objectForKey:META_SHOW_AQUIRED_DATE];
	if(value != nil)
	{
		[metaData removeObjectForKey:META_SHOW_AQUIRED_DATE];
		NSDate *newValue = [NSDate dateWithNaturalLanguageString:value];
		if([newValue timeIntervalSince1970])
			[metaData setObject:newValue forKey:META_SHOW_AQUIRED_DATE];
	}
	NSArray *convertToNumbers = [NSArray arrayWithObjects:META_SHOW_FAVORITE_RATING_KEY, META_RATING_KEY, META_ABSOLUTE_EP_NUMBER_KEY, META_SEASON_NUMBER_KEY, META_EPISODE_NUMBER_KEY, nil];
	NSEnumerator *numEnum = [convertToNumbers objectEnumerator];
	while((key = [numEnum nextObject]) != nil)
	{
		NSString *value = [metaData objectForKey:key];
		if(value != nil)
		{
			double newValue = [value doubleValue];
			NSNumber *newNum = [NSNumber numberWithInt:[value intValue]];
			if(newValue != round(newValue))
				newNum = [NSNumber numberWithDouble:newValue];
			[metaData setObject:newNum forKey:key];
		}
	}
	struct stat sb;
	memset(&sb, 0, sizeof(struct stat));
	stat([xmlFileName fileSystemRepresentation], &sb);
	long modTime = sb.st_mtimespec.tv_sec;
	[fileMeta importInfo: metaData fromSource:META_XML_IMPORT_KEY withTime:modTime];
}


- (void)importNextItem:(NSTimer *)timer
{
	NSFileManager *fm = [NSFileManager defaultManager];
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	NSString * fileName=[[fileMeta path] lastPathComponent] ;
	NSString * xmlFilePath=[fileMeta path] ;
	xmlPathIsDir = NO;
	xmlFilePath=[[xmlFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
	if([fm fileExistsAtPath:xmlFilePath isDirectory:&xmlPathIsDir] && !xmlPathIsDir)
	{
		[self importXMLFile:xmlFilePath forMeta:fileMeta] ;
		xmlFileCount++ ;
	}
	xmlPathIsDir = NO;
	[self setCurrentFile:[NSString stringWithFormat:@"Current File: %@ XML=%d",fileName,xmlFileCount]];
	[super importNextItem:timer];
}



- (void)resetUIElements
{
	[super resetUIElements];
	[title setTitle: @"Import File Data"];
	[self setText:@"This will populate Sapphire's File data.  This proceedure may take a while, but you may cancel at any time"];
	[button setTitle: @"Import File Data"];
}
@end
