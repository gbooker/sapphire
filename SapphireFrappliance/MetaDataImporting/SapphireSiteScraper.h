/*
 * SapphireSiteScraper.h
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

@class SapphireMovieScraper, SapphireTVShowScraper, SapphireURLLoader, SapphireScraper;

@protocol SapphireSiteScraperDelegate <NSObject>
- (void)retrievedSearchResuls:(NSXMLDocument *)results forObject:(id)object;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
@end

@protocol SapphireSiteMovieScraperDelegate <SapphireSiteScraperDelegate>
- (void)retrievedMovieDetails:(NSXMLDocument *)details forObject:(id)object;
@end

@protocol SapphireSiteTVShowScraperDelegate <SapphireSiteScraperDelegate>
- (void)retrievedShowDetails:(NSXMLDocument *)details forObject:(id)object;
- (void)retrievedEpisodeList:(NSXMLDocument *)episodeList forObject:(id)object;
- (void)retrievedEpisodeDetails:(NSXMLDocument *)details forObject:(id)object;
@end


@interface SapphireSiteScraper : NSObject <NSCopying>{
	id <SapphireSiteScraperDelegate>	delegate;
	id									referenceObject;
	SapphireURLLoader					*loader;
	NSInvocation						*finishedInvokation;
	NSMutableSet						*pendingUrlElements;
}

- (id)initWithDelegate:(id <SapphireSiteScraperDelegate>)aDelegate loader:(SapphireURLLoader *)loader;
- (SapphireScraper *)scraper;
- (void)setObject:(id)object;
- (void)scanForURLs:(NSXMLDocument *)document;

@end

@interface SapphireSiteMovieScraper : SapphireSiteScraper {
	SapphireMovieScraper	*scraper;
	NSString				*movieID;
}

- (id)initWithMovieScraper:(SapphireMovieScraper *)scraper delegate:(id <SapphireSiteMovieScraperDelegate>)delegate loader:(SapphireURLLoader *)loader;
- (SapphireMovieScraper *)scraper;
- (void)searchForMovieName:(NSString *)name year:(NSString *)year;
- (void)getMovieDetailsAtURL:(NSString *)url forMovieID:(NSString *)movieID;

@end

@interface SapphireSiteTVShowScraper : SapphireSiteScraper {
	SapphireTVShowScraper	*scraper;
	NSString				*showID;
	NSString				*epID;
}

- (id)initWithTVShowScraper:(SapphireTVShowScraper *)scraper delegate:(id <SapphireSiteTVShowScraperDelegate>)delegate loader:(SapphireURLLoader *)loader;
- (SapphireTVShowScraper *)scraper;
- (void)searchForShowNamed:(NSString *)name;
- (void)getShowDetailsAtURL:(NSString *)url forShowID:(NSString *)showID;
- (void)getEpisodeListAtURL:(NSString *)url;
- (void)getEpisodeDetailsAtURL:(NSString *)url forEpisodeID:(NSString *)epID;
@end
