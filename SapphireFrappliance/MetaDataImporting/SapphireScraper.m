/*
 * SapphireScraper.m
 * Sapphire
 *
 * Created by Graham Booker on Dec. 19, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireScraper.h"
#include "pcre.h"

@interface SapphireScraper ()
- (void)parseSettings;
- (void)setBuffer:(int)index toString:(NSString *)str;
- (void)clearBuffers;
- (void)setStoredMatch:(int)index toString:(NSString *)str;
- (void)clearStorchMatches;
- (NSString *)parseFunction:(NSString *)function;
@end

@implementation SapphireScraper

- (id)initWithPath:(NSString *)path error:(NSError * *)error
{
	self = [super init];
	if (self != nil) {
		NSURL *url = [NSURL fileURLWithPath:path];
		NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:error];
		root = [[doc rootElement] retain];
		[doc release];
		if(root == nil)
		{
			[self autorelease];
			return nil;
		}
		
		NSArray *includes;
		while([(includes = [root elementsForName:@"include"]) count])
		{
			NSXMLElement *include;
			NSEnumerator *includeEnum = [includes objectEnumerator];
			NSString *myDir = [path stringByDeletingLastPathComponent];
			while((include = [includeEnum nextObject]) != nil)
			{
				NSString *includePath = [myDir stringByAppendingPathComponent:[include stringValue]];
				NSXMLDocument *includeDoc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:includePath] options:0 error:nil];
				if(includeDoc)
				{
					NSArray *children = [[includeDoc rootElement] children];
					NSXMLElement *child;
					NSEnumerator *childEnum = [children objectEnumerator];
					while((child = [childEnum nextObject]) != nil)
					{
						[child detach];
						[root addChild:child];
					}
				}
				[include detach];
				[includeDoc release];
			}
		}
		
		settings = [[NSMutableDictionary alloc] init];
		[self parseSettings];
	}
	return self;
}

- (void) dealloc
{
	[root release];
	[settings release];
	[settingsXML release];
	[self clearBuffers];
	[self clearStorchMatches];
	[super dealloc];
}

- (NSString *)name
{
	return [[root attributeForName:@"name"] stringValue];
}

- (NSString *)contentType
{
	return [[root attributeForName:@"content"] stringValue];
}

- (NSString *)thumbUrl
{
	return [[root attributeForName:@"content"] stringValue];
}

- (NSString *)serverEncoding
{
	return [[root attributeForName:@"thumb"] stringValue];
}

- (NSString *)settingsXML
{
	return settingsXML;
}

- (NSMutableDictionary *)settings
{
	return settings;
}

- (NSString *)searchResultsForURLContent:(NSString *)urlContent
{
	[self setBuffer:0 toString:urlContent];
	return [self parseFunction:@"GetSearchResults"];
}

- (NSString *)functionResultWithArguments:(NSString *)function, ...
{
	va_list argList;
	va_start(argList, function);
	NSString *argument;
	int index = 0;
	while((argument = va_arg(argList, id)) != nil)
	{
		[self setBuffer:index toString:argument];
		index++;
	}
	return [self parseFunction:function];
}

- (void)setBuffer:(int)index toString:(NSString *)str
{
	[scraperBuffers[index] release];
	scraperBuffers[index] = [str retain];
}

- (void)clearBuffers
{
	for(int i=0; i<SCRAPER_BUFFER_COUNT; i++)
	{	
		[scraperBuffers[i] release];
		scraperBuffers[i] = nil;
	}
}

- (void)setStoredMatch:(int)index toString:(NSString *)str
{
	[storedMatches[index] release];
	storedMatches[index] = [str retain];
}

- (void)clearStorchMatches
{
	for(int i=0; i<SCRAPER_MATCH_COUNT; i++)
	{
		[storedMatches[i] release];
		storedMatches[i] = nil;
	}
}

- (void)parseSetting:(NSXMLElement *)setting
{
	NSString *type = [[setting attributeForName:@"type"] stringValue];
	if([type isEqualToString:@"sep"])
		return;
	NSString *settingID = [[setting attributeForName:@"id"] stringValue];
	if(![settingID length] || ![type length])
		return;
	
	NSString *defaultValue = [[setting attributeForName:@"default"] stringValue];
	if(![defaultValue length])
		defaultValue = @"";
	
	if([type isEqualToString:@"bool"])
	{
		if([defaultValue isEqualToString:@"true"])
			[settings setObject:[NSNumber numberWithBool:YES] forKey:settingID];
		else
			[settings setObject:[NSNumber numberWithBool:NO] forKey:settingID];
	}
	else if([type isEqualToString:@"text"])
		[settings setObject:defaultValue forKey:settingID];
	else if([type isEqualToString:@"labelenum"])
		[settings setObject:defaultValue forKey:settingID];
}

- (void)parseSettings
{
	settingsXML = [[self parseFunction:@"GetSettings"] retain];
	if(![settingsXML length])
		return;
	
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:settingsXML options:0 error:nil];
	NSXMLElement *rootSetting = [doc rootElement];
	NSArray *settingDescs = [rootSetting elementsForName:@"setting"];
	
	int count = [settingDescs count];
	for(int i=0; i<count; i++)
	{
		[self parseSetting:[settingDescs objectAtIndex:i]];
	}
	
	[doc release];
}

NSString *trimmedString(NSString *str)
{
	NSCharacterSet *whitespace = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"\n\r%C \t", 0x85]];
	
	int i, length = [str length];
	for(i=0; i<length; i++)
		if(![whitespace characterIsMember:[str characterAtIndex:i]])
			break;
	int offset = i;
	for(i=length-1; i>offset; i--)
		if(![whitespace characterIsMember:[str characterAtIndex:i]])
			break;
	
	if(offset > i)
		return @"";
	return [str substringWithRange:NSMakeRange(offset, i+1-offset)];
}

NSString *cleanedString(NSString *str)
{
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:str options:NSXMLDocumentTidyHTML error:nil];
	if(doc)
	{
		str = (NSString *)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)[doc stringValue], NULL);
		[str autorelease];
		[doc release];
	}
	return trimmedString(str);
}

void bufferBooleanAttributeWithDefault(NSXMLElement *element, NSString *attributeName, BOOL defaultValue, BOOL *values)
{
	if(defaultValue)
		for(int i=0; i<SCRAPER_MATCH_COUNT; i++)
			values[i] = YES;
	else
		memset(values, 0, sizeof(BOOL)*SCRAPER_MATCH_COUNT);
	
	NSString *attr = [[element attributeForName:attributeName] stringValue];
	if(attr)
	{
		NSArray *valueStrings = [attr componentsSeparatedByString:@","];
		int count = [valueStrings count];
		for(int i=0; i<count; i++)
		{
			int index = [[valueStrings objectAtIndex:i] intValue];
			if(index > 0 && index <= SCRAPER_MATCH_COUNT)
				values[index] = !defaultValue;
		}
	}
}

BOOL booleanAttributeWithDefault(NSXMLElement *element, NSString *attributeName, BOOL defaultValue)
{
	NSString *attr = [[element attributeForName:attributeName] stringValue];
	if(attr)
	{
		NSString *checkValue;
		if(defaultValue)
			checkValue = @"no";
		else
			checkValue = @"yes";
		if(![attr isEqualToString:checkValue])
			return defaultValue;
		else
			return !defaultValue;
	}
	return defaultValue;
}

int integerAttributeWithDefault(NSXMLElement *element, NSString *attributeName, int defaultValue)
{
	NSString *attr = [[element attributeForName:attributeName] stringValue];
	if(attr)
	{
		int ret = [attr intValue];
		if(ret)
			return ret;
	}
	return defaultValue;
}

- (NSString *)substituteBuffersIntoInput:(NSString *)input
{
	NSMutableString *mutStr = [input mutableCopy];
	
	NSRange range;
	while((range = [mutStr rangeOfString:@"$$"]).location != NSNotFound)
	{
		int index = [[mutStr substringFromIndex:range.location + 2] intValue];
		NSString *replacement;
		if(index > 0 && index <= SCRAPER_BUFFER_COUNT)
		{
			if(index > 9)
				range.length += 2;
			else
				range.length ++;
			
			replacement = scraperBuffers[index - 1];
			if(replacement == nil)
				replacement = @"";
		}
		else
			replacement = @"";
		[mutStr replaceCharactersInRange:range withString:replacement];
	}
	while((range = [mutStr rangeOfString:@"$INFO["]).location != NSNotFound)
	{
		int offset = range.location + 6;
		NSRange endRange = [mutStr rangeOfString:@"]" options:0 range:NSMakeRange(offset, [mutStr length] - offset)];
		NSString *replacement;
		if(endRange.location != NSNotFound)
		{
			range.length = endRange.location - range.location + 1;
			NSString *setting = [mutStr substringWithRange:NSMakeRange(offset, range.length - 7)];
			replacement = [settings objectForKey:setting];
			if(![replacement length])
				replacement = @"";
		}
		else
		{
			replacement = @"";
		}
		[mutStr replaceCharactersInRange:range withString:replacement];
	}
	NSString *ret = [NSString stringWithString:mutStr];
	[mutStr release];
	return ret;
}

- (NSString *)replacementStrForOutput:(NSString *)output inputStr:(const char *)input matches:(int *)matches count:(int)matchCount
{
	NSMutableString *mutStr = [output mutableCopy];
	
	NSRange range = NSMakeRange(0, [mutStr length]);
	while((range = [mutStr rangeOfString:@"\\" options:0 range:range]).location != NSNotFound)
	{
		BOOL storedMatch = ([mutStr characterAtIndex:range.location + 1] == '$');
		int index = [[mutStr substringFromIndex:range.location + 1 + storedMatch] intValue];
		NSString *replacement;
		if(index > 0 && index < matchCount)
			range.length++;
		range.length += storedMatch;
		
		int start = matches[index<<1];
		int end = matches[(index<<1) + 1];
		if(range.length > 1 && start != -1)
		{
			replacement = [[[NSString alloc] initWithBytes:input+start length:end-start encoding:NSUTF8StringEncoding] autorelease];
			if(storedMatch)
				[self setStoredMatch:index toString:replacement];
			if(clean[index])
				replacement = cleanedString(replacement);
			else if(trim[index])
				replacement = trimmedString(replacement);
		}
		else if(range.length > 1 && storedMatch)
			replacement = storedMatches[index];
		else
			replacement = @"";
		[mutStr replaceCharactersInRange:range withString:replacement];
		range.location += [replacement length];
		range.length = [mutStr length] - range.location;
	}
	
	NSString *ret = [NSString stringWithString:mutStr];
	[mutStr release];
	return ret;
}

- (void)parseExpression:(NSXMLElement *)element withInput:(NSString *)input intoDest:(int)dest andAppend:(BOOL)append
{
	NSString *output = [self substituteBuffersIntoInput:[[element attributeForName:@"output"] stringValue]];
	NSArray *expressions = [element elementsForName:@"expression"];
	NSString *expression = nil;
	NSXMLElement *expressionElement = nil;
	if([expressions count])
	{
		expressionElement = [expressions objectAtIndex:0];
		expression = [[expressionElement childAtIndex:0] stringValue];
	}
	if(![expression length])
		expression = @"(.*)";
	
	const char *errMsg = NULL;
	int errOffset = 0;
	pcre *reg = pcre_compile([expression UTF8String], PCRE_DOTALL, &errMsg, &errOffset, NULL);
	if(!reg)
		return;
	
	//AAA optional, compare;
	
	if(booleanAttributeWithDefault(expressionElement, @"clear", NO))
		[self setBuffer:dest-1 toString:nil];
	
	BOOL repeat = booleanAttributeWithDefault(expressionElement, @"repeat", NO);
	
	bufferBooleanAttributeWithDefault(expressionElement, @"noclean", YES, clean);
	
	bufferBooleanAttributeWithDefault(expressionElement, @"trim", NO, trim);
	
	NSString *result = @"";
	int match[30];
	int offset = 0;
	const char *inputStr = [input UTF8String];
	int inputLen = strlen(inputStr);
	int matchCount = 0;
	[self clearStorchMatches];
	while((matchCount = pcre_exec(reg, NULL, inputStr, inputLen, offset, 0, match, 30)) >= 0)
	{
		BOOL addToResult = YES;
		NSString *replacementString = [self replacementStrForOutput:output inputStr:inputStr matches:match count:matchCount];
		int compare = integerAttributeWithDefault(expressionElement, @"compare", -1);
		if(compare != -1)
		{
			NSString *searchStr = nil;
			if(compare > 0 && compare <= 20)
				searchStr = scraperBuffers[compare -1];
			if([searchStr length] && [[replacementString lowercaseString] rangeOfString:searchStr].location == NSNotFound)
				addToResult = NO;
		}
		if(addToResult)
			result = [result stringByAppendingString:replacementString];
		if(!repeat)
			break;
		offset = match[1];
	}
	
	pcre_free(reg);
	
	if(append)
	{	
		NSString *orig = scraperBuffers[dest - 1];
		if(orig != nil)
			result = [orig stringByAppendingString:result];
	}
	if([result length])
		[self setBuffer:dest-1 toString:result];
}

- (BOOL)checkCondition:(NSString *)condition
{
	BOOL inverse = NO;
	if([condition characterAtIndex:0] == '!')
	{
		inverse = YES;
		condition = [condition substringFromIndex:1];
	}
	
	id value = [settings objectForKey:condition];
	BOOL ret = [value boolValue];
	if(inverse)
		ret = !ret;
	
	return ret;
}

- (int)parseElement:(NSXMLElement *)element
{
	NSArray *regexChildren = nil;
	NSString *value = nil;
	NSString *conditional = nil;
	regexChildren = [element elementsForName:@"RegExp"];
	int count = [regexChildren count];
	if(count)
	{
		for(int i=0; i<count; i++)
			[self parseElement:[regexChildren objectAtIndex:i]];
	}
	
	int result = 1;
	value = [[element attributeForName:@"dest"] stringValue];
	if(value != nil)
		result = [value intValue];
	BOOL append = NO;
	if([value length] > 1 && [value characterAtIndex:1] == '+')
		append = YES;
	
	conditional = [[element attributeForName:@"conditional"] stringValue];
	if([conditional length] && ![self checkCondition:conditional])
		return result;
	
	NSString *input = [[element attributeForName:@"input"] stringValue];
	if(input)
		input = [self substituteBuffersIntoInput:input];
	else
		input = scraperBuffers[0];
	
	[self parseExpression:element withInput:input intoDest:result andAppend:append];
	
	return result;
}

- (NSString *)parseFunction:(NSString *)function
{
	NSArray *elements = [root elementsForName:function];
	if(![elements count])
		return nil;
	
	NSXMLElement *functionElement = [elements objectAtIndex:0];
	elements = [functionElement elementsForName:@"RegExp"];
	int count = [elements count];
	for(int i=0; i<count; i++)
	{
		[self parseElement:[elements objectAtIndex:i]];
	}
	int dest = integerAttributeWithDefault(functionElement, @"dest", 1);
	NSString *ret = scraperBuffers[dest - 1];
	if(booleanAttributeWithDefault(functionElement, @"clearbuffers", YES))
		[self clearBuffers];
	
	return ret;	
}

@end

@implementation SapphireMovieScraper

- (id)initWithPath:(NSString *)path error:(NSError * *)error;
{
	self = [super initWithPath:path error:error];
	if (self != nil) {
		if(![[self contentType] isEqualToString:@"movies"])
		{
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (NSString *)searchURLForMovieName:(NSString *)movieName year:(NSString *)year
{
	[self setBuffer:0 toString:[movieName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self setBuffer:1 toString:[year stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return [self parseFunction:@"CreateSearchUrl"];
}

- (NSString *)movieDetailsForURLContent:(NSString *)urlContent movieID:(NSString *)movieID atURL:(NSString *)url
{
	[self setBuffer:0 toString:urlContent];
	[self setBuffer:1 toString:movieID];
	[self setBuffer:2 toString:url];
	return [self parseFunction:@"GetDetails"];
}

@end

@implementation SapphireTVShowScraper

- (id)initWithPath:(NSString *)path error:(NSError * *)error;
{
	self = [super initWithPath:path error:error];
	if (self != nil) {
		if(![[self contentType] isEqualToString:@"tvshows"])
		{
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (NSString *)searchURLForShowName:(NSString *)showName;
{
	[self setBuffer:0 toString:[showName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return [self parseFunction:@"CreateSearchUrl"];
}

- (NSString *)showDetailsForURLContent:(NSString *)urlContent showID:(NSString *)showID atURL:(NSString *)url;
{
	[self setBuffer:0 toString:urlContent];
	[self setBuffer:1 toString:showID];
	[self setBuffer:2 toString:url];
	return [self parseFunction:@"GetDetails"];
}

- (NSString *)episodeListForURLContent:(NSString *)urlContent atURL:(NSString *)url;
{
	[self setBuffer:0 toString:urlContent];
	[self setBuffer:1 toString:url];
	return [self parseFunction:@"GetEpisodeList"];
}

- (NSString *)episodeDetailsForURLContent:(NSString *)urlContent episodeID:(NSString *)epID atURL:(NSString *)url;
{
	[self setBuffer:0 toString:urlContent];
	[self setBuffer:1 toString:epID];
	[self setBuffer:2 toString:url];
	return [self parseFunction:@"GetEpisodeDetails"];
}

@end

NSString *stringValueOfChild(NSXMLElement *element, NSString *childName)
{
	NSArray *children = [element elementsForName:childName];
	if(![children count])
		return nil;
	
	return [[children lastObject] stringValue];
}

NSNumber *intValueOfChild(NSXMLElement *element, NSString *childName)
{
	NSArray *children = [element elementsForName:childName];
	if(![children count])
		return nil;
	
	NSString *str = [[children lastObject] stringValue];
	return [NSNumber numberWithInt:[str intValue]];
}

NSDate *dateValueOfChild(NSXMLElement *element, NSString *childName)
{
	NSArray *children = [element elementsForName:childName];
	if(![children count])
		return nil;
	
	NSString *str = [[children lastObject] stringValue];
	return [NSDate dateWithNaturalLanguageString:str];
}

NSArray *arrayStringValueOfChild(NSXMLElement *element, NSString *childName)
{
	NSArray *children = [element elementsForName:childName];
	if(![children count])
		return nil;
	
	return [children valueForKey:@"stringValue"];
}

NSArray *arrayStringValueOfXPath(NSXMLElement *element, NSString *xpath)
{
	NSError *error = nil;
	NSArray *children = [element objectsForXQuery:xpath error:&error];
	if(![children count])
		return nil;
	
	return [children valueForKey:@"stringValue"];
}