/*
 * SapphireScraper.h
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

#define SCRAPER_BUFFER_COUNT 20
#define SCRAPER_MATCH_COUNT 10

@interface SapphireScraper : NSObject {
	NSXMLElement		*root;									/*!< @brief The XML document of the scraper*/
	
	NSString			*scraperBuffers[SCRAPER_BUFFER_COUNT];	/*!< @brief The scraper's string buffers for substitution*/
	BOOL				clean[SCRAPER_MATCH_COUNT];				/*!< @brief Indicates wether a buffer must be cleaned (HTML removed and trimmed)*/
	BOOL				trim[SCRAPER_MATCH_COUNT];				/*!< @brief Indicates wether a buffer must have leading and trailing whitespace trimmed*/
	NSMutableDictionary	*settings;								/*!< @brief The current settings for the scraper*/
	NSString			*settingsXML;							/*!< @brief The XML defining the settings*/
	NSString			*storedMatches[SCRAPER_MATCH_COUNT];	/*!< @brief The last matches which were made (\$n store/reads)*/
}

- (id)initWithPath:(NSString *)path error:(NSError * *)error;

- (NSString *)name;
- (NSString *)contentType;
- (NSString *)thumbUrl;
- (NSString *)serverEncoding;

- (NSString *)settingsXML;
- (NSMutableDictionary *)settings;

- (NSString *)searchResultsForURLContent:(NSString *)urlContent;
- (NSString *)functionResultWithArguments:(NSString *)arg1, ...;


@end

@interface SapphireMovieScraper : SapphireScraper {
}

- (NSString *)searchURLForMovieName:(NSString *)movieName year:(NSString *)year;
- (NSString *)movieDetailsForURLContent:(NSString *)urlContent movieID:(NSString *)movieID atURL:(NSString *)url;

@end

@interface SapphireTVShowScraper : SapphireScraper {
}

- (NSString *)searchURLForShowName:(NSString *)showName;
- (NSString *)showDetailsForURLContent:(NSString *)urlContent showID:(NSString *)showID atURL:(NSString *)url;
- (NSString *)episodeListForURLContent:(NSString *)urlContent atURL:(NSString *)url;
- (NSString *)episodeDetailsForURLContent:(NSString *)urlContent episodeID:(NSString *)epID atURL:(NSString *)url;

@end

NSString *stringValueOfChild(NSXMLElement *element, NSString *childName);
NSNumber *intValueOfChild(NSXMLElement *element, NSString *childName);
NSDate *dateValueOfChild(NSXMLElement *element, NSString *childName);
NSArray *arrayStringValueOfChild(NSXMLElement *element, NSString *childName);
NSArray *arrayStringValueOfXPath(NSXMLElement *element, NSString *xpath);
