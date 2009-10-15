/*
 * SapphireMovieVirtualDirectoryImporter.m
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
#import "SapphireMovieVirtualDirectoryImporter.h"
#import "SapphireMovieVirtualDirectory.h"
#import "SapphireLogging.h"

//Attributes
#define MOVIE_MATCH_ELEM_QUERY			@"/virtualDirs/movieMatch"
#define MOVIE_MATCH_NAME_ATTRIB			@"name"
#define MOVIE_MATCH_DESCRIPTION_ATTRIB	@"description"
#define ELEM_TYPE_ATTRIB				@"type"
#define ELEM_TYPE_ATTRIB_CASE_SENSITIVE @"s"
#define ELEM_TYPE_ATTRIB_REGEX			@"regex"
#define ALL_ELEM						@"all"
#define ANY_ELEM						@"any"
// in minutes (db stores in seconds) (at least the value specified)
#define DURATION_ELEM					@"duration" 
// t, f, y, n, 1, 0
#define WATCHED_ELEM					@"watched" 
// MPEG-2, NTSC, 720x480 (16:9), or DivX 5 (Perian, 448 x352, Millions, etc. 
#define VIDEO_DESCRIPTION_ELEM			@"videodescription" 
// English, Spanish, or MPEG Layer3, Stereo, 44.100 kHz
#define AUDIO_DESCRIPTION_ELEM			@"audiodescription" 
// English, Spanish, etc.
#define SUBTITLES_ELEM					@"subtitles" 
#define TITLE_ELEM						@"title"
#define PLOT_ELEM						@"plot"
// standard data format (db stores in unknown int format -- must convert)
#define RELEASE_DATE_ELEM				@"releasedate" 
// float 0 - 10 (at least the value specified)
#define IMDB_USER_RATING_ELEM			@"imdbuserrating" 
// int 1 - 250 (at most the value specified)
#define IMDB_TOP_250_ELEM				@"imdbtop250" 
// t, f, y, n, 1, 0
#define WON_OSCARS_ELEM					@"wonoscars" 
// PG, PG-13, R, G
#define MPAA_RATING_ELEM				@"mpaarating" 
#define CAST_ELEM						@"cast"
#define GENRE_ELEM						@"genre"
#define DIRECTOR_ELEM					@"director"
#define NOT_ELEM						@"not"

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

@interface SapphireCommandWrapper : NSObject
{
	CommandType		commandType;
	NSString		*formatString;
}
+ (id)commandWithType:(CommandType)type formatString:(NSString *)format;
- (id)initWithType:(CommandType)type formatString:(NSString *)format;
- (CommandType)commandType;
- (NSString *)formatString;
@end

@implementation SapphireCommandWrapper

+ (id)commandWithType:(CommandType)type formatString:(NSString *)format
{
	return [[[SapphireCommandWrapper alloc] initWithType:type formatString:format] autorelease];
}
- (id)initWithType:(CommandType)type formatString:(NSString *)format;
{
	self = [super init];
	if (self != nil) {
		commandType = type;
		formatString = [format retain];
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

- (NSString *)formatString
{
	return formatString;
}

@end


@implementation SapphireMovieVirtualDirectoryImporter

- (id) initWithPath:(NSString *)newPath
{
	self = [super init];
	if (self != nil) {
		elementCommands = [[NSDictionary alloc] initWithObjectsAndKeys:
						   [SapphireCommandWrapper commandWithType:CommandTypeAllWrapper formatString:nil], ALL_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeAnyWrapper formatString:nil], ANY_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeNotWrapper formatString:nil], NOT_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.title"], TITLE_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.plot"], PLOT_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.videoDescription"], VIDEO_DESCRIPTION_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.audioDescription"], AUDIO_DESCRIPTION_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.MPAARating"], MPAA_RATING_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"movie.subtitlesDescription"], SUBTITLES_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.#cast.name"], CAST_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.genres.name"], GENRE_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatElementString formatString:@"ANY movie.directors.name"], DIRECTOR_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatBoolValue formatString:@"movie.oscarsWon"], WON_OSCARS_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatBoolValue formatString:@"watched"], WATCHED_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatIntValue formatString:@"movie.imdbTop250Ranking > 0 && movie.imdbTop250Ranking <= %f"], IMDB_TOP_250_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatFloatValue formatString:@"movie.imdbRating >= %f"], IMDB_USER_RATING_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatFloatValueTimes60 formatString:@"movie.duration >= %f"], DURATION_ELEM,
						   [SapphireCommandWrapper commandWithType:CommandTypeFormatNSDateValue formatString:@"movie.releaseDate >= %@"], RELEASE_DATE_ELEM,
						   nil];
		path = [newPath retain];
	}
	return self;
}

- (void) dealloc
{
	[elementCommands release];
	[path release];
	[super dealloc];
}

- (NSArray *)virtualDirectories
{
	/*Check for XML file*/
	SapphireLog(SAPPHIRE_LOG_ALL, SAPPHIRE_LOG_LEVEL_DETAIL, @"Looking for file: %@", path);
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL xmlPathIsDir = NO;
	if(![fm fileExistsAtPath:path isDirectory:&xmlPathIsDir] || xmlPathIsDir)
		return nil;
	
	/*Read the XML document*/
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error] autorelease];
	NSXMLElement *root = [document rootElement];
	if(!root)
		return nil;
	
	NSMutableArray *virtualDirs = [NSMutableArray array];
	/*For each movie virtual directory*/
	NSArray *movieMatchNodes = [root nodesForXPath:MOVIE_MATCH_ELEM_QUERY error:&error];
	NSEnumerator *nodeEnum = [movieMatchNodes objectEnumerator];
	NSXMLElement *matchElem;
	NSXMLNode *tmpNode;
	while((matchElem = [nodeEnum nextObject]) != nil)
	{
		/*Create the virtual directory*/
		SapphireMovieVirtualDirectory *virtualDir = [[SapphireMovieVirtualDirectory alloc] init];
		tmpNode = [matchElem attributeForName:MOVIE_MATCH_NAME_ATTRIB];
		if (tmpNode)
			[virtualDir setTitle:[tmpNode stringValue]];
		tmpNode = [matchElem attributeForName:MOVIE_MATCH_DESCRIPTION_ATTRIB];
		if (tmpNode)
			[virtualDir setDescription:[tmpNode stringValue]];
		
		/*Build the query recursively (assume every child in the <movieMatch> is grouped in an implicit <all>). */
		NSPredicate *matchPred = [self allPredicateWithElement:matchElem];
		if (matchPred != nil) 
		{
			NSPredicate *moviePred = [NSPredicate predicateWithFormat:@"movie != nil"];
			matchPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:moviePred, matchPred, nil]];
			SapphireLog(SAPPHIRE_LOG_ALL, SAPPHIRE_LOG_LEVEL_INFO, @"Creating virtual directory with filter: %@", matchPred);
			[virtualDir setPredicate:matchPred];
			[virtualDirs addObject:virtualDir];
		}
		[virtualDir release];
	}
	return virtualDirs;
}

- (NSPredicate *)predicateWithElement:(NSXMLElement *)elem
{
	NSString *key = [[elem name] lowercaseString];
	SapphireCommandWrapper *command = [elementCommands objectForKey:key];
	if(command != nil)
	{
		switch ([command commandType]) {
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
				return [NSPredicate predicateWithFormat:[command formatString], [[elem stringValue] intValue]];
				break;
			case CommandTypeFormatFloatValue:
				return [NSPredicate predicateWithFormat:[command formatString], [[elem stringValue] floatValue]];
				break;
			case CommandTypeFormatFloatValueTimes60:
				return [NSPredicate predicateWithFormat:[command formatString], [[elem stringValue] floatValue] * 60];
				break;
			case CommandTypeFormatBoolValue:
				if([[elem stringValue] intValue])
					return [NSPredicate predicateWithFormat:@"%K != 0", [command formatString]];
				return [NSPredicate predicateWithFormat:@"%K == 0", [command formatString]];
				break;
			case CommandTypeFormatNSDateValue:
				return [NSPredicate predicateWithFormat:[command formatString], [NSDate dateWithNaturalLanguageString:[elem stringValue]]];
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