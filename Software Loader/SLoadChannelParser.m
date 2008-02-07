/*
 * SLoadChannelParser.h
 * Software Loader
 *
 * Created by Graham Booker on Jan. 1 2008.
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

#import "SLoadChannelParser.h"
#import "SLoadInstallerProtocol.h"

#define CHANNEL_URL					@"http://appletv.nanopi.net/software.xml"

@implementation SLoadChannelParser

- (id) init
{
	self = [super init];
	if (self == nil)
		return nil;
	
	softwareList = [NSMutableArray new];
	installers = [NSMutableDictionary new];
	
	return self;
}


- (void) dealloc
{
	[xmlDoc release];
	[softwareList release];
	[installers release];
	[super dealloc];
}

NSString *testList = @"<channel>\
	<item>\
		<title>Perian</title>\
		<link>http://perian.cachefly.org/Perian_1.0.dmg</link>\
		<md5>1234567890abcdef1234567890abcdef</md5>\
		<installname>perian</installname>\
		<version>1.0</version>\
		<type>software</type>\
		<installer version=\"1.0\">PerianInstaller</installer>\
	</item>\
	<item>\
		<title>Sapphire</title>\
		<link>http://appletv.nanopi.net/download/8/</link>\
		<md5>777a6bdb96f9d02da3e3b93c052a5d99</md5>\
		<installname>sapphire</installname>\
		<version>1.0b5</version>\
		<type>software</type>\
		<installer version=\"1.0\">FrappInstaller</installer>\
	</item>\
</channel>";

- (void)loadXML
{
/*	NSURL *url = [NSURL URLWithString:CHANNEL_URL];
	xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:nil];*/
	xmlDoc = [[NSXMLDocument alloc] initWithXMLString:testList options:NSXMLDocumentTidyXML error:nil];
}

- (NSDictionary *)parseNode:(NSXMLElement *)node
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	NSArray *objects = [node objectsForXQuery:INSTALL_DISPLAY_NAME_KEY error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_DISPLAY_NAME_KEY];
	
	objects = [node objectsForXQuery:INSTALL_URL_KEY error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_URL_KEY];

	objects = [node objectsForXQuery:INSTALL_MD5_KEY error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_MD5_KEY];
	
	objects = [node objectsForXQuery:INSTALL_NAME_KEY error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_NAME_KEY];
	
	objects = [node objectsForXQuery:INSTALL_VERSION_KEY error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_VERSION_KEY];
	
	objects = [node objectsForXQuery:INSTALL_SOFTWARE_TYPE error:nil];
	if([objects count])
		[ret setObject:[[objects objectAtIndex:0] stringValue] forKey:INSTALL_SOFTWARE_TYPE];
	
	objects = [node objectsForXQuery:INSTALL_INSTALLER_KEY error:nil];
	NSEnumerator *objectEnum = [objects objectEnumerator];
	NSXMLElement *element;
	NSMutableArray *result = [NSMutableArray array];
	while((element = [objectEnum nextObject]) != nil)
	{
		NSString *name = [element stringValue];
		NSString *version = [[element attributeForName:INSTALL_VERSION_KEY] stringValue];
		if(name == nil || version == nil)
			continue;
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   name, INSTALL_NAME_KEY,
						   version, INSTALL_VERSION_KEY,
						   nil]];
	}
	if([result count])
		[ret setObject:result forKey:INSTALL_INSTALLER_KEY];
	
	return ret;
}

- (void)parseXML
{
	[softwareList removeAllObjects];
	[installers removeAllObjects];
	NSXMLElement *root = [xmlDoc rootElement];
	NSArray *items = [root objectsForXQuery:@"item" error:nil];

	NSEnumerator *itemEnum = [items objectEnumerator];
	NSXMLElement *item;
	while((item = [itemEnum nextObject]) != nil)
	{
		NSDictionary *result = [self parseNode:item];
		if([[result objectForKey:INSTALL_SOFTWARE_TYPE] isEqualToString:INSTALL_TYPE_INSTALLER])
		{
			NSString *name = [result objectForKey:INSTALL_NAME_KEY];
			if(name != nil)
				[installers setObject:result forKey:name];
		}
		else if([[result objectForKey:INSTALL_SOFTWARE_TYPE] isEqualToString:INSTALL_TYPE_SOFTWARE])
		{
			NSString *name = [result objectForKey:INSTALL_NAME_KEY];
			if(name != nil)
				[softwareList addObject:result];
		}
	}
}

- (void)loadAndParseXML
{
	if(xmlDoc == nil)
		[self loadXML];
	if([softwareList count] == 0 || [installers count] == 0)
		[self parseXML];
}

- (void)reloadList
{
	[xmlDoc release];
	xmlDoc = nil;
	[softwareList removeAllObjects];
	[installers removeAllObjects];
	[self loadAndParseXML];
}

- (NSArray *)softwareList
{
	[self loadAndParseXML];
	return softwareList;
}

- (NSDictionary *)installers
{
	[self loadAndParseXML];
	return installers;
}


@end
