/*
 * SapphireCustomVirtualDirectoryImporter.m
 * Sapphire
 *
 * Created by mjacobsen on Oct. 2, 2009.
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
#import "SapphireCustomVirtualDirectoryImporter.h"
#import "SapphireCustomVirtualDirectory.h"
#import "SapphireLogging.h"
#include <sys/types.h>
#include <sys/stat.h>

//Types of virtual dirs
#define MOVIE_MATCH_ELEM_QUERY			@"/virtualDirs/movieMatch"
#define TV_SHOW_MATCH_ELEM_QUERY		@"/virtualDirs/episodeMatch"

//Attributes of virtual dir
#define MATCH_NAME_ATTRIB				@"name"
#define MATCH_DESCRIPTION_ATTRIB		@"description"

//Types of matching
#define ELEM_TYPE_ATTRIB				@"type"
#define ELEM_TYPE_ATTRIB_CASE_SENSITIVE @"s"
#define ELEM_TYPE_ATTRIB_REGEX			@"regex"
#define ELEM_VALUE_ATTRIB				@"value"
#define ELEM_VALUE_ATTRIB_GREATER		@"greater"
#define ELEM_VALUE_ATTRIB_EQUAL			@"equal"
#define ELEM_VALUE_ATTRIB_LESS			@"less"
#define ELEM_VALUE_ATTRIB_GREATER_E		@"greaterequal"
#define ELEM_VALUE_ATTRIB_LESS_E		@"lessequal"

//Containers for matches
#define ALL_ELEM						@"all"
#define ANY_ELEM						@"any"
#define NOT_ELEM						@"not"

//Global attributes
// in minutes (db stores in seconds) (at least the value specified)
#define DURATION_ELEM					@"duration" 
// MPEG-2, NTSC, 720x480 (16:9), or DivX 5 (Perian, 448 x352, Millions, etc. 
#define VIDEO_DESCRIPTION_ELEM			@"videodescription" 
// English, Spanish, or MPEG Layer3, Stereo, 44.100 kHz
#define AUDIO_DESCRIPTION_ELEM			@"audiodescription" 
// English, Spanish, etc.
#define SUBTITLES_ELEM					@"subtitles" 

//Movie specific attributes
#define MOVIE_TITLE_ELEM				@"title"
#define MOVIE_PLOT_ELEM					@"plot"
// standard date format (db stores in NSDate format -- must convert)
#define MOVIE_RELEASE_DATE_ELEM			@"releasedate" 
// float 0 - 10 (at least the value specified)
#define MOVIE_IMDB_USER_RATING_ELEM		@"imdbuserrating" 
// int 1 - 250 (at most the value specified)
#define MOVIE_IMDB_TOP_250_ELEM			@"imdbtop250" 
// t, f, y, n, 1, 0
#define MOVIE_WON_OSCARS_ELEM			@"wonoscars" 
// PG, PG-13, R, G
#define MOVIE_MPAA_RATING_ELEM			@"mpaarating" 
#define MOVIE_CAST_ELEM					@"cast"
#define MOVIE_GENRE_ELEM				@"genre"
#define MOVIE_DIRECTOR_ELEM				@"director"

//TVShow specifice attributes
#define TV_SHOW_SEASON_ELEM				@"season"
#define TV_SHOW_SHOW_ELEM				@"showtitle"
#define TV_SHOW_EPISODE_ELEM			@"episode"
#define TV_SHOW_ABS_EPISODE_ELEM		@"episodenumber"
#define TV_SHOW_EPISODE_TITLE_ELEM		@"title"
#define TV_SHOW_EPISODE_DESC_ELEM		@"description"
#define TV_SHOW_AIR_DATE_ELEM			@"airdate"

typedef enum {
	CommandTypeFormatElementString,
	CommandTypeNoFormat,
	CommandTypeFormatIntValue,
	CommandTypeFormatFloatValue,
	CommandTypeFormatFloatValueTimes60,
	CommandTypeFormatBoolValue,
	CommandTypeFormatNSDateValue,
	CommandTypeAnyWrapper,
	CommandTypeAllWrapper,
	CommandTypeNotWrapper,
} CommandType;

typedef enum {
	ValueCompareTypeNone,
	ValueCompareTypeGreater,
	ValueCompareTypeLess,
	ValueCompareTypeGreaterEqual,
	ValueCompareTypeLessEqual,
	ValueCompareTypeEqual,
} ValueCompareType;

@interface SapphireCommandWrapper : NSObject
{
	CommandType			commandType;
	ValueCompareType	compareType;
	NSString			*formatString;
}
+ (id)commandWithType:(CommandType)type defaultValueCompare:(ValueCompareType)compare formatString:(NSString *)format;
+ (id)commandWithType:(CommandType)type formatString:(NSString *)format;
- (id)initWithType:(CommandType)type defaultValueCompare:(ValueCompareType)compare formatString:(NSString *)format;
- (CommandType)commandType;
- (ValueCompareType)defaultValueCompareType;
- (NSString *)formatString;
@end

@implementation SapphireCommandWrapper

+ (id)commandWithType:(CommandType)type defaultValueCompare:(ValueCompareType)compare formatString:(NSString *)format
{
	return [[[SapphireCommandWrapper alloc] initWithType:type defaultValueCompare:compare formatString:format] autorelease];
}

+ (id)commandWithType:(CommandType)type formatString:(NSString *)format
{
	return [[[SapphireCommandWrapper alloc] initWithType:type defaultValueCompare:ValueCompareTypeNone formatString:format] autorelease];
}

- (id)initWithType:(CommandType)type defaultValueCompare:(ValueCompareType)compare formatString:(NSString *)format;
{
	self = [super init];
	if (self != nil) {
		commandType = type;
		formatString = [format retain];
		compareType = compare;
	}
	return self;
}

- (void) dealloc
{
	[formatString release];
	[super dealloc];
}

- (CommandType)commandType
{
	return commandType;
}

- (ValueCompareType)defaultValueCompareType
{
	return compareType;
}

- (NSString *)formatString
{
	return formatString;
}

@end

@interface SapphireCustomVirtualDirectoryImporter ()
- (NSPredicate *)predicateWithElement:(NSXMLElement *)elem;
- (NSPredicate *)allPredicateWithElement:(NSXMLElement *)elem;
- (NSPredicate *)anyPredicateWithElement:(NSXMLElement *)elem;
- (NSPredicate *)notPredicateWithElement:(NSXMLElement *)elem;
- (NSMutableArray *)predicateArrayWithElement:(NSXMLElement *)elem;
- (ValueCompareType)valueCompareTypeInElement:(NSXMLElement *)elem;
- (BOOL)isRegexMatch:(NSXMLElement *)elem;
- (BOOL)isCaseSensitiveMatch:(NSXMLElement *)elem;
@end

@implementation SapphireCustomVirtualDirectoryImporter

- (id) initWithPath:(NSString *)newPath
{
	self = [super init];
	if (self != nil) {
		NSDictionary *commonCommands = [[NSDictionary alloc] initWithObjectsAndKeys:
										[SapphireCommandWrapper commandWithType:CommandTypeAllWrapper formatString:nil], ALL_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeAnyWrapper formatString:nil], ANY_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeNotWrapper formatString:nil], NOT_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatFloatValueTimes60 defaultValueCompare:ValueCompareTypeGreaterEqual formatString:@"duration"], DURATION_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"videoDescription"], VIDEO_DESCRIPTION_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"audioDescription"], AUDIO_DESCRIPTION_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"subtitlesDescription"], SUBTITLES_ELEM,
										nil];
		NSDictionary *movieOnlyCommands = [[NSDictionary alloc] initWithObjectsAndKeys:
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.title"], MOVIE_TITLE_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.plot"], MOVIE_PLOT_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.MPAARating"], MOVIE_MPAA_RATING_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.#cast.name"], MOVIE_CAST_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.genres.name"], MOVIE_GENRE_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.directors.name"], MOVIE_DIRECTOR_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatBoolValue formatString:@"movie.oscarsWon"], MOVIE_WON_OSCARS_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatIntValue defaultValueCompare:ValueCompareTypeLessEqual formatString:@"movie.imdbTop250Ranking > 0 && movie.imdbTop250Ranking"], MOVIE_IMDB_TOP_250_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatFloatValue defaultValueCompare:ValueCompareTypeGreaterEqual formatString:@"movie.imdbRating"], MOVIE_IMDB_USER_RATING_ELEM,
										   [SapphireCommandWrapper commandWithType:CommandTypeFormatNSDateValue defaultValueCompare:ValueCompareTypeGreaterEqual formatString:@"movie.releaseDate"], MOVIE_RELEASE_DATE_ELEM,
										   nil];
		NSDictionary *epOnlyCommands = [[NSDictionary alloc] initWithObjectsAndKeys:
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"tvEpisode.tvShow.name"], TV_SHOW_SHOW_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY tvEpisode.subEpisodes.episodeTitle"], TV_SHOW_EPISODE_TITLE_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY tvEpisode.subEpisodes.episodeDescription"], TV_SHOW_EPISODE_DESC_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatIntValue defaultValueCompare:ValueCompareTypeEqual formatString:@"tvEpisode.season.seasonNumber"], TV_SHOW_SEASON_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatIntValue defaultValueCompare:ValueCompareTypeEqual formatString:@"ANY tvEpisode.subEpisodes.episodeNumber"], TV_SHOW_EPISODE_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatIntValue defaultValueCompare:ValueCompareTypeEqual formatString:@"ANY tvEpisode.subEpisodes.episodeNumber"], TV_SHOW_ABS_EPISODE_ELEM,
										[SapphireCommandWrapper commandWithType:CommandTypeFormatNSDateValue defaultValueCompare:ValueCompareTypeGreaterEqual formatString:@"ANY tvEpisode.subEpisodes.airDate"], TV_SHOW_AIR_DATE_ELEM,
										nil];
		
		NSMutableDictionary *additionalCommands = [commonCommands mutableCopy];
		[additionalCommands addEntriesFromDictionary:movieOnlyCommands];
		movieElementCommands = [[NSDictionary alloc] initWithDictionary:additionalCommands];
		[additionalCommands release];
		[movieOnlyCommands release];
		
		additionalCommands = [commonCommands mutableCopy];
		[additionalCommands addEntriesFromDictionary:epOnlyCommands];
		tvShowElementCommands = [[NSDictionary alloc] initWithDictionary:additionalCommands];
		[additionalCommands release];
		[epOnlyCommands release];
		
		[commonCommands release];
		path = [newPath retain];
	}
	return self;
}

- (void) dealloc
{
	[movieElementCommands release];
	[tvShowElementCommands release];
	[path release];
	[movieVirtualDirectories release];
	[tvShowVirtualDirectories release];
	[super dealloc];
}

- (SapphireCustomVirtualDirectory *)newVirtualDirectoryFromElement:(NSXMLElement *)element basePredicate:(NSPredicate *)basePredicate
{
	/*Create the virtual directory*/
	SapphireCustomVirtualDirectory *virtualDir = [[SapphireCustomVirtualDirectory alloc] init];
	NSXMLNode *tmpNode = [element attributeForName:MATCH_NAME_ATTRIB];
	if (tmpNode)
		[virtualDir setTitle:[tmpNode stringValue]];
	tmpNode = [element attributeForName:MATCH_DESCRIPTION_ATTRIB];
	if (tmpNode)
		[virtualDir setDescription:[tmpNode stringValue]];
	
	/*Build the query recursively (assume every child in the match is grouped in an implicit <all>). */
	NSPredicate *matchPred = [self allPredicateWithElement:element];
	if (matchPred != nil)
	{
		matchPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:basePredicate, matchPred, nil]];
		SapphireLog(SapphireLogTypeImport, SapphireLogLevelInfo, @"Creating virtual directory with filter: %@", matchPred);
		[virtualDir setPredicate:matchPred];
	}
	else
	{
		[virtualDir release];
		virtualDir = nil;
	}
	return virtualDir;
}

- (void)readVirtualDirectories;
{
	/*Check for XML file*/
	SapphireLog(SapphireLogTypeImport, SapphireLogLevelDetail, @"Looking for file: %@", path);
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL xmlPathIsDir = NO;
	if(![fm fileExistsAtPath:path isDirectory:&xmlPathIsDir] || xmlPathIsDir)
	{	
		[movieVirtualDirectories release];
		movieVirtualDirectories = nil;
		[tvShowVirtualDirectories release];
		tvShowVirtualDirectories = nil;
		return;
	}
	
	//Check modification time
	struct stat sb;
	memset(&sb, 0, sizeof(struct stat));
	stat([path fileSystemRepresentation], &sb);
	long modTime = sb.st_mtimespec.tv_sec;
	if(lastReadTime == modTime)
		return;
	
	/*Read the XML document*/
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error] autorelease];
	NSXMLElement *root = [document rootElement];
	if(root == nil)
	{	
		[movieVirtualDirectories release];
		movieVirtualDirectories = nil;
		[tvShowVirtualDirectories release];
		tvShowVirtualDirectories = nil;
		return;
	}
	
	NSMutableArray *virtualDirs;
	NSArray *movieMatchNodes = [root nodesForXPath:MOVIE_MATCH_ELEM_QUERY error:&error];
	virtualDirs = [[NSMutableArray alloc] initWithCapacity:[movieMatchNodes count]];
	NSEnumerator *nodeEnum = [movieMatchNodes objectEnumerator];
	NSXMLElement *matchElem;
	NSPredicate *moviePred = [NSPredicate predicateWithFormat:@"movie != nil"];
	elementCommands = movieElementCommands;
	while((matchElem = [nodeEnum nextObject]) != nil)
	{
		SapphireCustomVirtualDirectory *virtualDir = [self newVirtualDirectoryFromElement:matchElem basePredicate:moviePred];
		if(virtualDir != nil)
			[virtualDirs addObject:virtualDir];
		[virtualDir release];
	}
	[movieVirtualDirectories release];
	movieVirtualDirectories = [[NSArray alloc] initWithArray:virtualDirs];
	[virtualDirs release];
	
	NSArray *episodeMatchNodes = [root nodesForXPath:TV_SHOW_MATCH_ELEM_QUERY error:&error];
	nodeEnum = [episodeMatchNodes objectEnumerator];
	virtualDirs = [[NSMutableArray alloc] initWithCapacity:[episodeMatchNodes count]];
	NSPredicate *episodePred = [NSPredicate predicateWithFormat:@"tvEpisode != nil"];
	elementCommands = tvShowElementCommands;
	while((matchElem = [nodeEnum nextObject]) != nil)
	{
		SapphireCustomVirtualDirectory *virtualDir = [self newVirtualDirectoryFromElement:matchElem basePredicate:episodePred];
		if(virtualDir != nil)
			[virtualDirs addObject:virtualDir];
		[virtualDir release];
	}
	[tvShowVirtualDirectories release];
	tvShowVirtualDirectories = [[NSArray alloc] initWithArray:virtualDirs];
	[virtualDirs release];
}

- (NSArray *)movieVirtualDirectories
{
	[self readVirtualDirectories];
	return movieVirtualDirectories;
}

- (NSArray *)tvShowVirtualDirectories
{
	[self readVirtualDirectories];
	return tvShowVirtualDirectories;
}

- (NSString *)compareStringForType:(ValueCompareType)compareType
{
	switch (compareType) {
		case ValueCompareTypeLess:
			return @"<";
		case ValueCompareTypeLessEqual:
			return @"<=";
		case ValueCompareTypeEqual:
			return @"==";
		case ValueCompareTypeGreater:
			return @">";
		case ValueCompareTypeGreaterEqual:
			return @">=";
		case ValueCompareTypeNone:
			return @"";
	}
	return nil;
}

- (NSString *)formatStringForCommand:(SapphireCommandWrapper *)command element:(NSXMLElement *)elem
{
	ValueCompareType compareType = [self valueCompareTypeInElement:elem];
	if(compareType == ValueCompareTypeNone)
		compareType = [command defaultValueCompareType];
	NSString *compareStr = [self compareStringForType:compareType];

	switch ([command commandType]) {
		case CommandTypeFormatIntValue:
			return [NSString stringWithFormat:@"%@ %@ %%d", [command formatString], compareStr];
			break;
		case CommandTypeFormatFloatValue:
		case CommandTypeFormatFloatValueTimes60:
			return [NSString stringWithFormat:@"%@ %@ %%f", [command formatString], compareStr];
			break;
		case CommandTypeFormatNSDateValue:
			return [NSString stringWithFormat:@"%@ %@ %%@", [command formatString], compareStr];
		default:
			break;
	}
	return nil;
}

- (NSPredicate *)predicateWithElement:(NSXMLElement *)elem
{
	NSString *key = [[elem name] lowercaseString];
	SapphireCommandWrapper *command = [elementCommands objectForKey:key];
	if(command != nil)
	{
		CommandType commandType = [command commandType];
		NSString *formatStr = [self formatStringForCommand:command element:elem];
		switch (commandType) {
			case CommandTypeFormatElementString:
			{
				NSString *predFormat = nil;
				/*NOTE: regex MATCHES operators are not officially supported against core data objects -- though
				 * some have posted success when using regex MATCHES with simple (non-many-to-one) relationships.
				 * We'll leave it commented out for now.*/
				/*if([self isRegexMatch:elem])
					predFormat = [NSString stringWithFormat:@"%@ matches %%@", [command formatString]];
				else*/ if([self isCaseSensitiveMatch:elem])
					predFormat = [NSString stringWithFormat:@"%@ like %%@", [command formatString]];
				else
					predFormat = [NSString stringWithFormat:@"%@ like[cd] %%@", [command formatString]];
				return [NSPredicate predicateWithFormat:predFormat, [elem stringValue]];
			}
				break;
			case CommandTypeNoFormat:
				return [NSPredicate predicateWithFormat:[command formatString]];
				break;
			case CommandTypeFormatIntValue:
				return [NSPredicate predicateWithFormat:formatStr, [[elem stringValue] intValue]];
				break;
			case CommandTypeFormatFloatValue:
				return [NSPredicate predicateWithFormat:formatStr, [[elem stringValue] floatValue]];
				break;
			case CommandTypeFormatFloatValueTimes60:
				return [NSPredicate predicateWithFormat:formatStr, [[elem stringValue] floatValue]];
				break;
			case CommandTypeFormatBoolValue:
				if([[elem stringValue] intValue])
					return [NSPredicate predicateWithFormat:@"%K != 0", [command formatString]];
				return [NSPredicate predicateWithFormat:@"%K == 0", [command formatString]];
				break;
			case CommandTypeFormatNSDateValue:
				return [NSPredicate predicateWithFormat:formatStr, [NSDate dateWithNaturalLanguageString:[elem stringValue]]];
				break;
			case CommandTypeAnyWrapper:
				return [self anyPredicateWithElement:elem];
				break;
			case CommandTypeAllWrapper:
				return [self allPredicateWithElement:elem];
				break;
			case CommandTypeNotWrapper:
				return [self notPredicateWithElement:elem];
				break;
			default:
				break;
		}
	}
	return nil;
}

- (NSPredicate *)allPredicateWithElement:(NSXMLElement *)elem
{
	NSMutableArray *preds = [self predicateArrayWithElement:elem];
	
	/*Now set the returned predicates to an AND predicate*/
	if ([preds count])
		return [NSCompoundPredicate andPredicateWithSubpredicates:preds];
	else
		return nil;
}

- (NSPredicate *)anyPredicateWithElement:(NSXMLElement *)elem
{
	NSMutableArray *preds = [self predicateArrayWithElement:elem];
	
	/*Now set the returned predicates to an ANY predicate*/
	if ([preds count])
		return [NSCompoundPredicate orPredicateWithSubpredicates:preds];
	else
		return nil;	
}

- (NSPredicate *)notPredicateWithElement:(NSXMLElement *)elem
{
	NSMutableArray *preds = [self predicateArrayWithElement:elem];
	
	/*Now set the returned predicate to a NOT predicate*/
	if ([preds count])
		return [NSCompoundPredicate notPredicateWithSubpredicate:(NSPredicate *)[preds objectAtIndex:0]];
	else
		return nil;	
}

- (NSMutableArray *)predicateArrayWithElement:(NSXMLElement *)elem
{
	NSMutableArray *preds = [NSMutableArray array];
	NSEnumerator *nodeEnum = [[elem children] objectEnumerator];
	NSXMLNode *node;
	while((node = [nodeEnum nextObject]) != nil)
	{
		/*Check for type of node*/
		if ([node kind] == NSXMLElementKind)
		{
			/*Create a predicate and add it our array*/
			NSPredicate *pred = [self predicateWithElement:(NSXMLElement *)node];
			if (pred != nil)
				[preds addObject:pred];
		}
	}
	return preds;	
}

- (ValueCompareType)valueCompareTypeInElement:(NSXMLElement *)elem
{
	NSString *type = [[elem attributeForName:ELEM_VALUE_ATTRIB] stringValue];
	if(type != nil)
	{
		if([type caseInsensitiveCompare:ELEM_VALUE_ATTRIB_GREATER] == NSOrderedSame)
			return ValueCompareTypeGreater;
		if([type caseInsensitiveCompare:ELEM_VALUE_ATTRIB_LESS] == NSOrderedSame)
			return ValueCompareTypeLess;
		if([type caseInsensitiveCompare:ELEM_VALUE_ATTRIB_GREATER_E] == NSOrderedSame)
			return ValueCompareTypeGreaterEqual;
		if([type caseInsensitiveCompare:ELEM_VALUE_ATTRIB_LESS_E] == NSOrderedSame)
			return ValueCompareTypeLessEqual;
		if([type caseInsensitiveCompare:ELEM_VALUE_ATTRIB_EQUAL] == NSOrderedSame)
			return ValueCompareTypeEqual;
	}
	return ValueCompareTypeNone;
}

- (BOOL)isRegexMatch:(NSXMLElement *)elem 
{
	/* Need to check if this is a regex match. Default to wildcard (NO).
	 * Only return YES if attribute type="regex" exists. */
	NSString *type = [[elem attributeForName:ELEM_TYPE_ATTRIB] stringValue];
	if(type!=nil)
		return ([type caseInsensitiveCompare:ELEM_TYPE_ATTRIB_REGEX] == NSOrderedSame);
	return NO;
}

- (BOOL)isCaseSensitiveMatch:(NSXMLElement *)elem 
{
	/* Need to check if this is a case sensitive match. Default to case insensitive (NO).
	 * Only return YES if attribute type="s" exists. */
	NSString *type = [[elem attributeForName:ELEM_TYPE_ATTRIB] stringValue];
	if(type!=nil)
		return ([type caseInsensitiveCompare:ELEM_TYPE_ATTRIB_CASE_SENSITIVE] == NSOrderedSame);
	return NO;
}

@end