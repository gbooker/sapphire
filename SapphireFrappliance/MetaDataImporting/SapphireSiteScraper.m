/*
 * SapphireSiteScraper.m
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

#import "SapphireSiteScraper.h"
#import "SapphireURLLoader.h"
#import "SapphireScraper.h"

@implementation SapphireSiteScraper

- (id)initWithDelegate:(id <SapphireSiteScraperDelegate>)aDelegate loader:(SapphireURLLoader *)aLoader
{
	self = [super init];
	if(!self)
		return self;
	
	delegate = [aDelegate retain];
	loader = [aLoader retain];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	SapphireSiteScraper *myCopy = [[[self class] allocWithZone:zone] init];
	
	if(!myCopy)
		return myCopy;
	
	myCopy->delegate = [delegate retain];
	myCopy->referenceObject = [referenceObject retain];
	myCopy->loader = [loader retain];
	myCopy->finishedInvokation = [finishedInvokation retain];
	myCopy->pendingUrlElements = [pendingUrlElements retain];
	
	return myCopy;
}

- (void) dealloc
{
	[delegate release];
	[referenceObject release];
	[loader release];
	[pendingUrlElements release];
	[finishedInvokation release];
	[super dealloc];
}

- (void)setObject:(id)object
{
	[referenceObject autorelease];
	referenceObject = [object retain];
}

- (SapphireScraper *)scraper
{
	return nil;
}

- (void)addURLData:(NSString *)data forElement:(NSXMLElement *)element
{
	NSString *function = [[element attributeForName:@"function"] stringValue];
	NSXMLElement *parent = (NSXMLElement *)[element parent];
	if(function != nil)
	{
		NSString *result = [[self scraper] functionResultWithArguments:function, data, nil];
		NSError *error = nil;
		if([result length])
		{
			NSXMLDocument *resultDoc = [[NSXMLDocument alloc] initWithXMLString:result options:0 error:&error];
			NSXMLElement *rootElement = [resultDoc rootElement];
			NSXMLElement *elementToAdd;
			NSEnumerator *elementEnum = [[rootElement children] objectEnumerator];
			while((elementToAdd = [elementEnum nextObject]) != nil)
			{
				[elementToAdd detach];
				[parent addChild:elementToAdd];
			}
			[resultDoc release];
		}
	}
	[element detach];
	
	[pendingUrlElements removeObject:element];
	if(![pendingUrlElements count])
	{
		[pendingUrlElements release];
		pendingUrlElements = nil;
		[self scanForURLs:[parent rootDocument]];
	}
}

- (void)scanForURLs:(NSXMLDocument *)document
{
	NSArray *urlsToFetch = [[document rootElement] elementsForName:@"url"];
	
	if([urlsToFetch count] == 0)
	{
		[finishedInvokation invoke];
		[finishedInvokation release];
		finishedInvokation = nil;
	}
	else
	{
		[pendingUrlElements release];
		pendingUrlElements = [[NSMutableSet alloc] initWithArray:urlsToFetch];
		
		NSXMLElement *url;
		NSEnumerator *urlEnum = [urlsToFetch objectEnumerator];
		while((url = [urlEnum nextObject]) != nil)
		{
			NSString *urlLocation = [url stringValue];
			[loader loadStringURL:urlLocation withTarget:self selector:@selector(addURLData:forElement:) object:url];
		}
	}
}

- (void)callDelegateSelector:(SEL)selector forConent:(NSString *)xmlResults
{
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString:xmlResults options:0 error:&error];
	
	[finishedInvokation release];
	finishedInvokation = [[NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:selector]] retain];
	[finishedInvokation retainArguments];
	[finishedInvokation setTarget:delegate];
	[finishedInvokation setSelector:selector];
	[finishedInvokation setArgument:&document atIndex:2];
	[finishedInvokation setArgument:&referenceObject atIndex:3];
	
	[self scanForURLs:document];
	
	[document release];
}

@end

@implementation SapphireSiteMovieScraper

- (id)initWithMovieScraper:(SapphireMovieScraper *)aScraper delegate:(id <SapphireSiteMovieScraperDelegate>)aDelegate loader:(SapphireURLLoader *)aLoader
{
	self = [super initWithDelegate:aDelegate loader:aLoader];
	if(!self)
		return self;
	
	scraper = [aScraper retain];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	SapphireSiteMovieScraper *myCopy = [[[self class] allocWithZone:zone] init];
	
	if(!myCopy)
		return myCopy;
	
	myCopy->scraper = [scraper retain];
	myCopy->movieID = [movieID retain];
	
	return myCopy;
}

- (void)dealloc
{
	[scraper release];
	[movieID release];
	[super dealloc];
}

- (SapphireScraper *)scraper
{
	return scraper;
}

- (void)foundSearchResults:(NSString *)results
{
	NSString *xmlResults = [scraper searchResultsForURLContent:results];
	
	[self callDelegateSelector:@selector(retrievedSearchResuls:forObject:) forConent:xmlResults];
}

- (void)searchForMovieName:(NSString *)name year:(NSString *)year
{
	NSString *searchURLXmlString = [scraper searchURLForMovieName:name year:year];
	
	NSError *error = nil;
	NSXMLDocument *searchURLXml = [[NSXMLDocument alloc] initWithXMLString:searchURLXmlString options:0 error:&error];
	
	NSXMLElement *urlElement = [searchURLXml rootElement];
	NSString *url = nil;
	if([[urlElement name] isEqualToString:@"url"])
		url = [urlElement stringValue];
	
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(foundSearchResults:) object:nil];
	else
		[self foundSearchResults:nil];
	[searchURLXml release];
}

- (void)gotMovieDetails:(NSString *)details atURL:(NSString *)url
{
	NSString *xmlDetails = [scraper movieDetailsForURLContent:details movieID:movieID atURL:url];
	
	[self callDelegateSelector:@selector(retrievedMovieDetails:forObject:) forConent:xmlDetails];
}

- (void)getMovieDetailsAtURL:(NSString *)url forMovieID:(NSString *)aMovieID
{
	[movieID release];
	movieID = [aMovieID retain];
	
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(gotMovieDetails:atURL:) object:url];
	else
		[self gotMovieDetails:nil atURL:url];
}

@end

@implementation SapphireSiteTVShowScraper

- (id)initWithTVShowScraper:(SapphireTVShowScraper *)aScraper delegate:(id <SapphireSiteTVShowScraperDelegate>)aDelegate loader:(SapphireURLLoader *)aLoader
{
	self = [super initWithDelegate:aDelegate loader:aLoader];
	if(!self)
		return self;
	
	scraper = [aScraper retain];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	SapphireSiteTVShowScraper *myCopy = [super copyWithZone:zone];
	
	if(!myCopy)
		return myCopy;
	
	myCopy->scraper = [scraper retain];
	
	return myCopy;
}

- (void)dealloc
{
	[scraper release];
	[super dealloc];
}

- (SapphireScraper *)scraper
{
	return scraper;
}

- (void)foundSearchResults:(NSString *)results
{
	NSString *xmlResults = [scraper searchResultsForURLContent:results];
	
	[self callDelegateSelector:@selector(retrievedSearchResuls:forObject:) forConent:xmlResults];
}

- (void)searchForShowNamed:(NSString *)name;
{
	NSString *searchURLXmlString = [scraper searchURLForShowName:name];
	
	NSError *error = nil;
	NSXMLDocument *searchURLXml = [[NSXMLDocument alloc] initWithXMLString:searchURLXmlString options:0 error:&error];
	
	NSXMLElement *urlElement = [searchURLXml rootElement];
	NSString *url = nil;
	if([[urlElement name] isEqualToString:@"url"])
		url = [urlElement stringValue];
	
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(foundSearchResults:) object:nil];
	else
		[self foundSearchResults:nil];
	[searchURLXml release];
}

- (void)gotShowDetails:(NSString *)details atURL:(NSString *)url
{
	NSString *xmlDetails = [scraper showDetailsForURLContent:details atURL:url];
	
	[self callDelegateSelector:@selector(retrievedShowDetails:forObject:) forConent:xmlDetails];
}

- (void)getShowDetailsAtURL:(NSString *)url
{
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(gotShowDetails:atURL:) object:url];
	else
		[self gotShowDetails:nil atURL:url];
}

- (void)gotEpisodeList:(NSString *)details atURL:(NSString *)url
{
	NSString *xmlDetails = [scraper episodeListForURLContent:details atURL:url];
	
	[self callDelegateSelector:@selector(retrievedEpisodeList:forObject:) forConent:xmlDetails];
}

- (void)getEpisodeListAtURL:(NSString *)url
{
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(gotEpisodeList:atURL:) object:url];
	else
		[self gotEpisodeList:nil atURL:url];
}

- (void)gotEpisodeDetails:(NSString *)details atURL:(NSString *)url
{
	NSString *xmlDetails = [scraper episodeDetailsForURLContent:details atURL:url];
	
	[self callDelegateSelector:@selector(retrievedEpisodeDetails:forObject:) forConent:xmlDetails];
}

- (void)getEpisodeDetailsAtURL:(NSString *)url
{
	if([url length])
		[loader loadStringURL:url withTarget:self selector:@selector(gotEpisodeDetails:atURL:) object:url];
	else
		[self gotEpisodeDetails:nil atURL:url];
}

@end