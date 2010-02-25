/*
 * SapphireTVShowImporter.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 30, 2007.
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

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireTVShowImporter.h"
#import "SapphireFileMetaData.h"
#import "NSString-Extensions.h"
#import "NSFileManager-Extensions.h"
#import "SapphireShowChooser.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireTVTranslation.h"
#import "SapphireEpisode.h"
#import "SapphireSettings.h"
#import "NSImage-Extensions.h"
#import "SapphireTVShow.h"
#import "NSXMLDocument-Extensions.h"
#import "SapphireScraper.h"
#import "SapphireApplianceController.h"
#import "SapphireURLLoader.h"

/* TVRage XPATHS  */
#define TVRAGE_SHOWNAME_XPATH @".//font[@size=2][@color=\"white\"]/b/text()"
#define TVRAGE_EPLIST_XPATH @"//*[@class='b']"
#define TVRAGE_EP_INFO @".//*[@class='b2']/*"
#define TVRAGE_EP_TEXT @".//*[@class='b2']/text()"
#define TVRAGE_SCREEN_CAP_XPATH @".//img[contains(@src, 'screencap')]"
#define TVRAGE_SEARCH_XPATH @"//*[@class='b1']/a"
#define TVRAGE_UNKNOWN_XPATH @"//*[contains(text(), 'Unknown Page')]"
#define TVRAGE_SHOW_FULL_DESC_XPATH @"//div[@id='sft_1']//text()"
#define TVRAGE_SHOW_RAW_DESC_XPATH @"//tr[@id='iconn1']/td/table/tr/td//text()"
#define TVRAGE_SHOW_IMG_XPATH @"//img[contains(@src, 'shows')]"

#define LINK_KEY				@"Link"
#define IMG_URL					@"imgURL"

@interface SapphireTVShowImportStateData : SapphireImportStateData
{
@public
	SapphireSiteTVShowScraper	*siteScraper;
	SapphireTVTranslation		*translation;
	NSString					*showName;
	NSString					*showPath;
	SapphireTVShow				*show;
	int							episode;
	int							secondEp;
	int							season;
	NSString					*episodeTitle;
	NSMutableArray				*episodeInfoArray;
	int							episodesCompleted;
}
- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath scraper:(SapphireSiteTVShowScraper *)siteScaper;
- (void)setTranslation:(SapphireTVTranslation *)translation;
- (void)setShowName:(NSString *)showName;
- (void)setShowPath:(NSString *)showPath;
- (void)setShow:(SapphireTVShow *)show;
- (void)setEpisodeTitle:(NSString *)episodeTitle;
- (void)setEpisodeInfoArray:(NSMutableArray *)episodeInfoArray;
@end

@implementation SapphireTVShowImportStateData

- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath scraper:(SapphireSiteTVShowScraper *)aSiteScaper
{
	self = [super initWithFile:aFile atPath:aPath];
	if(!self)
		return self;
	
	siteScraper = [aSiteScaper retain];
	
	return self;
}

- (void)dealloc
{
	[siteScraper release];
	[translation release];
	[showName release];
	[showPath release];
	[show release];
	[episodeTitle release];
	[episodeInfoArray release];
	[super dealloc];
}

- (void)setTranslation:(SapphireTVTranslation *)aTranslation
{
	[translation autorelease];
	translation = [aTranslation retain];
	NSString *aShowPath = aTranslation.showPath;
	if([aShowPath length])
		[self setShowPath:aShowPath];
}

- (void)setShowName:(NSString *)aShowName
{
	[showName autorelease];
	showName = [aShowName retain];
}

- (void)setShowPath:(NSString *)aShowPath
{
	[showPath autorelease];
	showPath = [aShowPath retain];
}

- (void)setShow:(SapphireTVShow *)aShow
{
	[show autorelease];
	show = [aShow retain];
	NSString *aShowName = aShow.name;
	if([aShowName length])
		[self setShowName:aShowName];
}

- (void)setEpisodeTitle:(NSString *)anEpisodeTitle
{
	[episodeTitle autorelease];
	episodeTitle = [anEpisodeTitle retain];
}

- (void)setEpisodeInfoArray:(NSMutableArray *)anEpisodeInfoArray
{
	[episodeInfoArray release];
	episodeInfoArray = [anEpisodeInfoArray retain];
}

@end

@interface SapphireSingleTVShowEpisodeImportStateData : NSObject
{
@public
	SapphireTVShowImportStateData	*state;
	int								index;
	SapphireSiteTVShowScraper		*siteScraper;
	int								absEpisode;
	NSString						*epID;
}

- (id)initWithState:(SapphireTVShowImportStateData *)state index:(int)index episodeID:(NSString *)epID;
@end

@implementation SapphireSingleTVShowEpisodeImportStateData

- (id)initWithState:(SapphireTVShowImportStateData *)aState index:(int)anIndex episodeID:(NSString *)anEpID;
{
	self = [super init];
	if(!self)
		return self;
	
	state = [aState retain];
	index = anIndex;
	if(anIndex == 0)
		siteScraper = [aState->siteScraper retain];
	else
		siteScraper = [aState->siteScraper copy];
	epID = [anEpID retain];
	
	return self;
}

- (void)dealloc
{
	[state release];
	[siteScraper release];
	[epID release];
	[super dealloc];
}


@end
 
@interface SapphireTVShowImporter ()
- (void)getTVShowResultsForState:(SapphireTVShowImportStateData *)state;
- (void)getTVShowEpisodeListForState:(SapphireTVShowImportStateData *)state;
- (void)getTVShowEpisodesForState:(SapphireSingleTVShowEpisodeImportStateData *)state atURL:(NSString *)url;
- (void)completeWithState:(SapphireTVShowImportStateData *)state withStatus:(ImportState)status importComplete:(BOOL)importComplete;
- (void)completedEpisode:(NSDictionary *)dict forState:(SapphireTVShowImportStateData *)state atIndex:(int)index;
@end

@implementation SapphireTVShowImporter

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	scraper = [[SapphireScraper scrapperWithName:@"TV Rage"] retain];
	
	/*Initialize the regexes*/
	regcomp(&letterMarking, "[\\. -]?S[0-9]+E[S0-9]+([-E]+[0-9]+)?", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonByEpisode, "[\\. -]?[0-9]+x[S0-9]+(-[0-9]+)?", REG_EXTENDED | REG_ICASE);
	regcomp(&seasonEpisodeTriple, "[\\. -][0-9]{1,3}[S0-9]{2}[\\. -]", REG_EXTENDED | REG_ICASE);	
	return self;
}

- (void)dealloc
{
	[scraper release];
	regfree(&letterMarking);
	regfree(&seasonByEpisode);
	regfree(&seasonEpisodeTriple);
	[super dealloc];
}

- (void)setDelegate:(id <SapphireImporterDelegate>)aDelegate
{
	delegate = aDelegate;
}

- (void)cancelImports
{
	cancelled = YES;
}

- (void)retrievedSearchResuls:(NSXMLDocument *)results forObject:(id)stateObj
{
	SapphireTVShowImportStateData *state = (SapphireTVShowImportStateData *)stateObj;
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	if(results == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	NSXMLElement *root = [results rootElement];
	NSArray *entities = [root elementsForName:@"entity"];
	NSMutableArray *shows = [[NSMutableArray alloc] initWithCapacity:[entities count]];
	NSEnumerator *entityEnum = [entities objectEnumerator];
	NSXMLElement *entity;
	while((entity = [entityEnum nextObject]) != nil)
	{
		NSString *title = stringValueOfChild(entity, @"title");
		NSString *url = stringValueOfChild(entity, @"url");
		if([url length])
		{
			NSURL *trimmer = [NSURL URLWithString:url];
			url = [trimmer path];
		}
		if([title length] && [url length])
			[shows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   title, tvShowTranslationNameKey,
							   url, tvShowTranslationLinkKey,
							   nil]];
	}
	
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Found shows: %@", shows);
	
	/* No need to prompt the user for an empty set */
	if(![shows count])
	{
		/* We tried to import but found nothing - mark this file to be skipped on future imports */
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:YES];
	}
	if([[SapphireSettings sharedSettings] autoSelection])
	{
		SapphireFileMetaData *metaData = state->file;
		NSManagedObjectContext *moc = [metaData managedObjectContext];
		NSString *showPath = [[shows objectAtIndex:0] objectForKey:tvShowTranslationLinkKey];
		SapphireTVTranslation *tran = [SapphireTVTranslation createTVTranslationForName:state->lookupName withPath:showPath inContext:moc];
		[state setTranslation:tran];
		[self getTVShowResultsForState:state];
	}
	else
	{
		/*Bring up the prompt*/
		SapphireShowChooser *chooser = [[SapphireShowChooser alloc] initWithScene:[delegate chooserScene]];
		[chooser setShows:shows];
		[chooser setFileName:[NSString stringByCroppingDirectoryPath:state->path toLength:3]];
		[chooser setListTitle:BRLocalizedString(@"Select Show Title", @"Prompt the user for showname with a file")];
		/*And display prompt*/
		[delegate displayChooser:chooser forImporter:self withContext:state];
		[chooser release];
	}
	[shows release];	
}

- (void)getTVShowResultsForState:(SapphireTVShowImportStateData *)state
{
	SapphireTVShow *show = [state->translation tvShow];
	BOOL fetchShowData = NO;
	if(show == nil)
		fetchShowData = YES;
	else if(![[show showDescription] length])
		fetchShowData = YES;
	
	if(!fetchShowData)
	{
		NSString *coverArtPath = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"@TV/%@/cover.jpg", [show name]]];
		if(![[NSFileManager defaultManager] fileExistsAtPath:coverArtPath])
			fetchShowData = YES;
	}
	if(fetchShowData)
	{
		SapphireSiteTVShowScraper *siteScraper = state->siteScraper;
		[siteScraper setObject:state];
		NSString *fullURL = [@"http://www.tvrage.com" stringByAppendingString:state->showPath];
		[siteScraper getShowDetailsAtURL:fullURL forShowID:state->showPath];
	}
	else
	{
		[state setShow:show];
		[self getTVShowEpisodeListForState:state];
	}
}

- (void)retrievedShowDetails:(NSXMLDocument *)details forObject:(id)stateObj
{
	SapphireTVShowImportStateData *state = (SapphireTVShowImportStateData *)stateObj;
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	if(details == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	NSXMLElement *root = [details rootElement];
	NSString *plot = stringValueOfChild(root, @"plot");
	NSString *thumb = stringValueOfChild(root, @"thumb");
	
	/*Check for series info*/
	NSManagedObjectContext *moc = [state->file managedObjectContext];
	SapphireTVShow *show = state->show;
	if(!show)
	{
		SapphireTVTranslation *tran = state->translation;
		show = tran.tvShow;
		if(!show)
		{
			NSString *title = stringValueOfChild(root, @"title");
			if(![title length])
			{
				//We can't import anymore.  Importer or site broken; abort.
				[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
				return;
			}
			show = [SapphireTVShow show:title withPath:state->showPath inContext:moc];
			tran.tvShow = show;
		}
		[state setShow:show];
	}
	if([thumb length])
	{
		NSString *coverArtPath = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"@TV/%@/cover.jpg", [show name]]];
		[[SapphireApplianceController urlLoader] saveDataAtURL:thumb toFile:coverArtPath];
	}
	if([plot length])
		show.showDescription = plot;
	
	[self getTVShowEpisodeListForState:state];
}

- (void)getTVShowEpisodeListForState:(SapphireTVShowImportStateData *)state
{
	SapphireSiteTVShowScraper *siteScraper = state->siteScraper;
	[siteScraper setObject:state];
	NSString *fullURL = [NSString stringWithFormat:@"http://www.tvrage.com%@/episode_list/all", state->showPath];
	[siteScraper getEpisodeListAtURL:fullURL];
}

- (void)getEpisode:(int)episode withSeason:(int)season title:(NSString *)episodeTitle state:(SapphireTVShowImportStateData *)state inList:(NSXMLDocument *)episodeList index:(int)index
{
	NSString *xquery;
	if(episode)
		xquery = [NSString stringWithFormat:@"//episode[number(season)=%d and number(epnum)=%d]/url", season, episode];
	else
	{
		NSString *escapedTitle = [[episodeTitle lowercaseString] stringByReplacingAllOccurancesOf:@"'" withString:@"\\'"];
		xquery = [NSString stringWithFormat:@"//episode[number(season)=%d and lower-case(title)='%@']/url", season, escapedTitle];
	}
	NSArray *epElements = [episodeList objectsForXQuery:xquery error:nil];
	if([epElements count])
	{
		NSXMLElement *epURLElement = [epElements objectAtIndex:0];
		NSXMLElement *episodeElement = (NSXMLElement *)[epURLElement parent];
		NSNumber *absoluteNumber = intValueOfChild(episodeElement, @"absoluteEp");
		NSString *epID = stringValueOfChild(episodeElement, @"id");
		int absNumber = [absoluteNumber intValue];
		SapphireSingleTVShowEpisodeImportStateData *epState = [[SapphireSingleTVShowEpisodeImportStateData alloc] initWithState:state index:index episodeID:epID];
		epState->absEpisode = absNumber;
		[self getTVShowEpisodesForState:epState atURL:[epURLElement stringValue]];
		[epState release];
	}
	else
		[self completedEpisode:nil forState:state atIndex:index];
}

- (void)retrievedEpisodeList:(NSXMLDocument *)episodeList forObject:(id)stateObj
{
	SapphireTVShowImportStateData *state = (SapphireTVShowImportStateData *)stateObj;
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	if(episodeList == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	NSMutableArray *infoArray;
	int secondEp = state->secondEp;
	if(secondEp)
		infoArray = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], nil];
	else
		infoArray = [[NSMutableArray alloc] initWithObjects:[NSNull null], nil];
	[state setEpisodeInfoArray:infoArray];
	[infoArray release];
	
	[self getEpisode:state->episode withSeason:state->season title:state->episodeTitle state:state inList:episodeList index:0];
	if(secondEp)
		[self getEpisode:secondEp withSeason:state->season title:nil state:state inList:episodeList index:1];
}

- (void)getTVShowEpisodesForState:(SapphireSingleTVShowEpisodeImportStateData *)epState atURL:(NSString *)url
{
	SapphireSiteTVShowScraper *siteScraper = epState->siteScraper;
	[siteScraper setObject:epState];
	[siteScraper getEpisodeDetailsAtURL:url forEpisodeID:epState->epID];
}

- (void)retrievedEpisodeDetails:(NSXMLDocument *)details forObject:(id)stateObj
{
	SapphireSingleTVShowEpisodeImportStateData *state = (SapphireSingleTVShowEpisodeImportStateData *)stateObj;
	SapphireTVShowImportStateData *tvState = state->state;
	[state->siteScraper setObject:nil];	//Avoid retain loop
	if(cancelled)
		return;
	
	if(details == nil)
	{
		/*Failed to get data, network likely, don't mark this as imported*/
		[self completeWithState:tvState withStatus:ImportStateNotUpdated importComplete:NO];
		return;
	}
	int index = state->index;
	NSXMLElement *root = [details rootElement];
	NSString *epTitle = stringValueOfChild(root, @"title");
	int ep = tvState->episode;
	if(index != 0)
		ep = tvState->secondEp;
	if(ep == 0 && ![epTitle length])
	{
		//No episode number or title; something is seriously wrong here
		[self completedEpisode:nil forState:tvState atIndex:state->index];
		return;
	}
	
	NSMutableDictionary *epDict = [NSMutableDictionary dictionary];
	/*Add info*/
	[epDict setObject:tvState->show.name forKey:META_SHOW_NAME_KEY];
	if(ep != 0)
		[epDict setObject:[NSNumber numberWithInt:ep] forKey:META_EPISODE_NUMBER_KEY];
	[epDict setObject:[NSNumber numberWithInt:tvState->season] forKey:META_SEASON_NUMBER_KEY];

	if(epTitle != nil)
		[epDict setObject:epTitle forKey:META_TITLE_KEY];
	[epDict setObject:tvState->showPath forKey:META_SHOW_IDENTIFIER_KEY];
	NSString *summary = stringValueOfChild(root, @"plot");
	if(summary != nil)
		[epDict setObject:summary forKey:META_DESCRIPTION_KEY];
	if(state->absEpisode)
		[epDict setObject:[NSNumber numberWithInt:state->absEpisode] forKey:META_ABSOLUTE_EP_NUMBER_KEY];
	NSDate *airDate = dateValueOfChild(root, @"aired");
	if(airDate != nil)
		[epDict setObject:airDate forKey:META_SHOW_AIR_DATE];
	NSString *imgURL = stringValueOfChild(root, @"thumb");
	if([imgURL length])
	{
		NSString *previewArtPath = [NSFileManager previewArtPathForTV:tvState->show.name season:tvState->season];
		NSString *newPath = nil;
		if(ep != 0)
			newPath = [previewArtPath stringByAppendingFormat:@"/Episode %d", ep];
		else
			newPath = [previewArtPath stringByAppendingPathComponent:epTitle];
		NSString *imageDestination = [newPath stringByAppendingPathExtension:@"jpg"];
		BOOL isDir = NO;
		BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imageDestination isDirectory:&isDir] && !isDir;
		if(imgURL && !imageExists)
		{
			/*Download the screen cap*/
			[[SapphireApplianceController urlLoader] saveDataAtURL:imgURL toFile:imageDestination];
		}
		else if(!imageExists)
		{
			//QTMovie is broken on ATV, don't fetch images there
			SapphireFileMetaData *metaData = tvState->file;
			if ([SapphireFrontRowCompat usingLeopard] && [metaData fileContainerTypeValue] == FILE_CONTAINER_TYPE_QT_MOVIE)
			{
				// NSImage-Extensions
				[[NSImage imageFromMovie:tvState->path] writeToFile:imageDestination atomically:YES];
			}
		}		
	}
	[self completedEpisode:epDict forState:tvState atIndex:index];
}

- (void)completedEpisode:(NSDictionary *)dict forState:(SapphireTVShowImportStateData *)state atIndex:(int)index
{
	state->episodesCompleted++;
	NSMutableArray *infoArray = state->episodeInfoArray;
	if(dict == nil)
		dict = [NSMutableDictionary dictionary];
	[infoArray replaceObjectAtIndex:index withObject:dict];
	if(state->episodesCompleted == [infoArray count])
	{
		int i;
		for(i=0; i<[infoArray count]; i++)
		{
			if(![[infoArray objectAtIndex:i] count])
			{
				[infoArray removeObjectAtIndex:i];
				i--;
			}
		}
		if([infoArray count])
		{
			SapphireFileMetaData *file = state->file;
			SapphireEpisode *ep = [SapphireEpisode episodeWithDictionaries:infoArray inContext:[file managedObjectContext]];
			file.tvEpisode = ep;
			[self completeWithState:state withStatus:ImportStateUpdated importComplete:YES];
		}
		else
			[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:YES];
	}
}

- (void)completeWithState:(SapphireTVShowImportStateData *)state withStatus:(ImportState)status importComplete:(BOOL)importComplete;
{
	SapphireFileMetaData *currentData = state->file;
	if(importComplete)
	{
		[currentData didImportType:IMPORT_TYPE_TVSHOW_MASK];
		if (status == ImportStateNotUpdated && [currentData fileClassValue] != FILE_CLASS_MOVIE)
			[currentData setFileClassValue:FILE_CLASS_UNKNOWN];
	}
	[delegate backgroundImporter:self completedImportOnPath:state->path withState:status];
}

- (NSString *)showPathFromNfoFilePath:(NSString *)filepath
{
	NSString *nfoContent = [NSString stringWithContentsOfFile:filepath];

	if(![nfoContent length])
		return nil;
	
	NSString *results = [scraper searchResultsForNfoContent:nfoContent];
	if(![results length])
		return nil;
	
	NSString *fullResults = [NSString stringWithFormat:@"<results>%@</results>", results];
	NSError *error = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:fullResults options:0 error:&error] autorelease];
	if(!doc)
		return nil;
	
	NSXMLElement *root = [doc rootElement];
	NSString *urlStr = stringValueOfChild(root, @"url");
	if(![urlStr length])
		return nil;
	
	NSURL *url = [NSURL URLWithString:urlStr];
	if(!url)
		return nil;
	
	return [url path];
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	cancelled = NO;
	/*Check to see if it is already imported*/
	if([metaData importTypeValue] & IMPORT_TYPE_TVSHOW_MASK)
		return ImportStateNotUpdated;
	//	NSArray *pathComponents = [path pathComponents];
	NSString *extLessPath = path;
	if([metaData fileContainerTypeValue] != FILE_CONTAINER_TYPE_VIDEO_TS)
		extLessPath = [extLessPath stringByDeletingPathExtension];

	NSString *fileName = [path lastPathComponent];
	
	/*Check regexes to see if this is a tv show*/
	int index = NSNotFound;
	int secondEp = -1;
	regmatch_t matches[3];
	const char *theFileName = [fileName fileSystemRepresentation];
	NSString *scanString = nil;
	if(!regexec(&letterMarking, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
		secondEp = matches[1].rm_so;
	}
	else if(!regexec(&seasonByEpisode, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		scanString = [fileName substringFromIndex:index];
		secondEp = matches[1].rm_so;
	}
	else if(!regexec(&seasonEpisodeTriple, theFileName, 3, matches, 0))
	{
		index = matches[0].rm_so;
		/*Insert an artificial season/ep seperator so things are easier later*/
		NSMutableString *tempStr = [fileName mutableCopy];
		//		if(index > [tempStr length] || index <= 0 )return NO;
		[tempStr deleteCharactersInRange:NSMakeRange(0, index+1)];
		[tempStr insertString:@"x" atIndex:matches[0].rm_eo - index - 4];
		scanString = [tempStr autorelease];
	}
	
	/*See if we found a match*/
	if(index == NSNotFound)
	{	
		[metaData didImportType:IMPORT_TYPE_TVSHOW_MASK];
		return ImportStateNotUpdated;
	}
	
	int season = 0;
	int ep = 0;
	/*Get the season*/
	NSScanner *scanner = [NSScanner scannerWithString:scanString];
	NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
	[scanner scanUpToCharactersFromSet:digits intoString:nil];
	[scanner scanInt:&season];
	/*Get the episode number*/
	NSString *skipped = nil;
	[scanner scanUpToCharactersFromSet:digits intoString:&skipped];
	[scanner scanInt:&ep];
	/*Was there an S before the episode number?*/
	if([skipped hasSuffix:@"S"] || [skipped hasSuffix:@"s"])
		ep = 0;
	
	int overriddenSeason = [metaData searchSeasonNumber];
	if(overriddenSeason != -1)
		season = overriddenSeason;
	
	int overriddenEpisode = [metaData searchEpisodeNumber];
	if(overriddenEpisode != -1)
		ep = overriddenEpisode;
	
	/*No season, no info*/
	if(season == 0)
	{	
		[metaData didImportType:IMPORT_TYPE_TVSHOW_MASK];
		return ImportStateNotUpdated;
	}
	
	int otherEp = 0;
	if(secondEp != -1)
	{
		[scanner setScanLocation:secondEp - index];
		[scanner scanUpToCharactersFromSet:digits intoString:nil];
		[scanner scanInt:&otherEp];
	}
	
	overriddenEpisode = [metaData searchLastEpisodeNumber];
	if(overriddenEpisode != -1)
		otherEp = overriddenEpisode;
	
	/*Get the show title*/
	NSString *searchStr = [fileName substringToIndex:index];
	NSString *searchShowName = [metaData searchShowName];
	if(searchShowName != nil)
		searchStr = searchShowName;
	searchStr = [searchStr lowercaseString];
	SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"%@ matched regex; checking show name %@", fileName, searchStr);
	/*Check to see if we know this title*/
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	SapphireTVTranslation *tran = [SapphireTVTranslation tvTranslationForName:searchStr inContext:moc];
	SapphireSiteTVShowScraper *siteScraper = [[SapphireSiteTVShowScraper alloc] initWithTVShowScraper:scraper delegate:self loader:[SapphireApplianceController urlLoader]];
	SapphireTVShowImportStateData *state = [[[SapphireTVShowImportStateData alloc] initWithFile:metaData atPath:path scraper:siteScraper] autorelease];
	[siteScraper release];
	
	[state setLookupName:searchStr];
	[state setTranslation:tran];
	SapphireTVShow *show = tran.tvShow;
	[state setShow:show];
	state->episode = ep;
	state->season = season;
	state->secondEp = otherEp;
	if(ep == 0)
	{
		NSString *epTitle = nil;
		[scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:nil];
		if([scanner scanUpToString:@"." intoString:&epTitle])
			[state setEpisodeTitle:epTitle];
	}
	if([tran showPath] == nil)
	{
		BOOL nfoPathIsDir = NO;
		NSString *nfoFilePath=[extLessPath stringByAppendingPathExtension:@"nfo"];
		NSString *showPath = nil;
		if([[NSFileManager defaultManager] fileExistsAtPath:nfoFilePath isDirectory:&nfoPathIsDir] && !nfoPathIsDir)
			showPath = [self showPathFromNfoFilePath:nfoFilePath];
		
		if([showPath length])
		{
			[tran setShowPath:showPath];
			[state setShowPath:showPath];
		}
		else
		{
			SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DEBUG, @"Conducting search");
			if(![delegate canDisplayChooser])
			/*There is no data menu, background import. So we can't ask user, skip*/
				return ImportStateNotUpdated;
			/*Ask the user what show this is*/
			[siteScraper setObject:state];
			[siteScraper searchForShowNamed:searchStr];
			return ImportStateMultipleSuspend;
		}
	}
	
	[self getTVShowResultsForState:state];
	return ImportStateMultipleSuspend;
}

/*!
 * @brief Write our setings out
 */
- (void)writeSettingsForContext:(NSManagedObjectContext *)moc
{
	[SapphireMetaDataSupport save:moc];
}

/*- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	[showInfoClearTimer invalidate];
	showInfoClearTimer = nil;
	ImportState ret = [self doRealImportMetaData:metaData path:path];
	showInfoClearTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(clearCache) userInfo:nil repeats:NO];
	return ret;
}*/

- (NSString *)completionText
{
	return BRLocalizedString(@"All available TV Show data has been imported", @"The TV Show import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Fetch TV Show Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will attempt to fetch information about your TV shows files from the Internet (TVRage).  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of the movie import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Fetching Data", @"Button");
}

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	SapphireTVShowImportStateData *state = (SapphireTVShowImportStateData *)context;
	/*Check for a match done earlier*/
	NSManagedObjectContext *moc = [state->file managedObjectContext];
	SapphireTVTranslation *tran = [SapphireTVTranslation tvTranslationForName:state->lookupName inContext:moc];
	if([tran showPath])
	{
		[state setTranslation:tran];
		[self getTVShowResultsForState:state];
		return NO;
	}
	return YES;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)aChooser withContext:(id)context
{
	SapphireTVShowImportStateData *state = (SapphireTVShowImportStateData *)context;
	if(![aChooser isKindOfClass:[SapphireShowChooser class]])
		return;
	SapphireShowChooser *chooser = (SapphireShowChooser *)aChooser;
	SapphireFileMetaData *currentData = state->file;
	
	/*Get the user's selection*/
	int selection = [chooser selection];
	if(selection == SapphireChooserChoiceCancel)
		/*They aborted, skip*/
		[self completeWithState:state withStatus:ImportStateUserSkipped importComplete:NO];
	else if(selection == SapphireChooserChoiceNotType)
		/*They said it is not a show, so put in empty data so they are not asked again*/
		[self completeWithState:state withStatus:ImportStateNotUpdated importComplete:YES];
	else
	{
		/*They selected a show, save the translation and write it*/
		NSDictionary *show = [[chooser shows] objectAtIndex:selection];
		NSManagedObjectContext *moc = [currentData managedObjectContext];
		SapphireTVTranslation *tran = [SapphireTVTranslation createTVTranslationForName:state->lookupName withPath:[show objectForKey:tvShowTranslationLinkKey] inContext:moc];
		[state setTranslation:tran];
		[self writeSettingsForContext:moc];
		[self getTVShowResultsForState:state];
	}
}

@end
