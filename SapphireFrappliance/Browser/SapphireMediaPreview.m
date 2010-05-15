/*
 * SapphireMediaPreview.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 26, 2007.
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

#import "SapphireMediaPreview.h"
#import "SapphireFileMetaData.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireMedia.h"
#import "SapphireSettings.h"
#import <objc/objc-class.h>
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

NSString *META_EPISODE_AND_SEASON_KEY =		@"S/E";
NSString *META_MOVIE_IMDB_STATS_KEY =		@"IMDB";
NSString *AUDIO_DESC_LABEL_KEY =			@"Audio";
NSString *VIDEO_DESC_LABEL_KEY =			@"Video";
NSString *AUDIO2_DESC_LABEL_KEY =			@"Audio2";
NSString *VIDEO2_DESC_LABEL_KEY =			@"Video2";
NSString *SUBTITLE_LABEL_KEY =     			@"Subtitles";

/*These interfaces are to access variables not available*/
@interface BRMetadataLayer (protectedAccess)
- (NSArray *)gimmieMetadataObjs;
@end

@implementation BRMetadataLayer (protectedAccess)
- (NSArray *)gimmieMetadataObjs
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass,"_metadataLabels");
	
	return *(NSArray * *)(((char *)self)+ret->ivar_offset);
}
@end

/* There is no BRMetadataLayer class in ATV2.0 anymore, it seems to be BRMetadataControl now*/
/* So just do the same stuff as above, but for BRMetadataControl*/
@interface BRMetadataControl : NSObject
@end

@implementation BRMetadataControl (protectedAccess)
- (NSArray *)gimmieMetadataObjs {
	Class klass = [self class];
	Ivar ret = class_getInstanceVariable(klass, "_metadataObjs");
	return *(NSArray * *)(((char *)self)+ret->ivar_offset);
}
@end


@interface BRMetadataPreviewController (compat)
- (void)_updateMetadataLayer;
@end

@interface BRMetadataPreviewController (protectedAccess)
- (BRMetadataLayer *)gimmieMetadataLayer;
@end

@implementation BRMetadataPreviewController (protectedAccess)
- (BRMetadataLayer *)gimmieMetadataLayer
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass,"_metadataLayer");
	
	return *(BRMetadataLayer * *)(((char *)self)+ret->ivar_offset);
}
@end

@interface SapphireMediaPreview ()
- (void)doPopulation;
- (NSString *)coverArtForPath;
- (NSString *)keyForDisplay:(NSString *)key;
@end

@implementation SapphireMediaPreview

/*List of extensions to look for cover art*/
static NSSet *coverArtExtentions = nil;

+ (void)initialize
{
	/*Initialize the set of cover art extensions*/
	coverArtExtentions = [[NSSet alloc] initWithObjects:
		@"jpg",
		@"jpeg",
		@"tif",
		@"tiff",
		@"png",
		@"gif",
		nil];
}

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMetadataPreviewController class] instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	else
		return [super init];
}

- (void)dealloc
{
	[meta release];
	[dirMeta release];
	[super dealloc];
}

- (void)setImageOnly:(BOOL)newImageOnly
{
	imageOnly = newImageOnly;
}

- (void)setUtilityData:(NSMutableDictionary *)newMeta
{
	[meta release];
	meta=[newMeta retain];
	SapphireMedia *asset  = [[SapphireMedia alloc] init];
	[asset setImagePath:[[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultPreview" ofType:@"png"]];
	[self setAsset:asset];
	[asset release];
}

- (void)setMetaData:(id <SapphireMetaData>)newMeta inMetaData:(id <SapphireDirectory>)dir
{
	[meta release];
	NSString *path = [newMeta path];
	if(path == nil)
	{
		meta = nil;
		return;
	}
	meta = [newMeta retain];
	[dirMeta release];
	dirMeta = [dir retain];
	/*Now that we know the file, set the asset*/
	NSURL *url = [NSURL fileURLWithPath:[meta path]];
	SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
	[asset setImagePath:[self coverArtForPath]];
	[self setAsset:asset];
	[asset release];
}

/*!
 * @brief Search for cover art for the current metadata
 *
 * @return The path to the found cover art
 */
- (NSString *)coverArtForPath
{
	/*See if this is a directory*/
	if([meta conformsToProtocol:@protocol(SapphireDirectory)])
	{
		NSString *ret = [(id <SapphireDirectory>)meta coverArtPath];
		if(ret != nil)
			return ret;
	} else {
		NSString *ret = [(SapphireFileMetaData *)meta coverArtPath];
		if(ret != nil)
			return ret;
		else if ((ret = [dirMeta coverArtPath]) != nil)
			return ret;
	}
	/*Fallback to default*/
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultPreview" ofType:@"png"];
}

/*!
 * @brief Override the loading of the cover art method
 */
- (void)_loadCoverArt
{
	[super _loadCoverArt];
	
	/*See if it loaded something*/
	if([_coverArtLayer texture] != nil)
		return;
	
	/*Get our cover art*/
	NSString *path = [self coverArtForPath];
	NSURL *url = [NSURL fileURLWithPath:path];
	/*Create an image source*/;
    CGImageSourceRef  sourceRef;
	CGImageRef        imageRef = NULL;
	sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	if(sourceRef) {
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
	if(imageRef)
	{
		[_coverArtLayer setImage:imageRef];
		CFRelease(imageRef);
	}	
}

/*!
 * @brief populate metadata for TV Shows
 */
- (void) populateTVShowMetadataWith:(NSMutableDictionary*)allMeta
{
	NSString *value = [allMeta objectForKey:META_TITLE_KEY];
	BRMetadataLayer *metaLayer = [self gimmieMetadataLayer];
	if(value != nil)
	{
		/*If there is an air date, put it in the title*/
		NSDate *airDate = [allMeta objectForKey:META_SHOW_AIR_DATE];
		if(airDate != nil)
		{
			NSDateFormatter *format = [[NSDateFormatter alloc] init];
			[format setDateStyle:NSDateFormatterShortStyle];
			[format setTimeZone:NSDateFormatterNoStyle];
			value = [[format stringFromDate:airDate]stringByAppendingFormat:@" - %@", value];
			[format release];
		}
		[metaLayer setTitle:value];
	}
	
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	BOOL displayOnlyPlot = [settings displayOnlyPlot];
	/*Get the rating*/
	value = [allMeta objectForKey:META_RATING_KEY];
	if(value != nil && !displayOnlyPlot)
		[metaLayer setRating:value];
	
	/*Get the description*/
	value = [allMeta objectForKey:META_DESCRIPTION_KEY];
	if(value != nil)
		if([settings displaySpoilers] || displayOnlyPlot)
			[metaLayer setSummary:value];
	
	/*Get the copyright*/
	value = [allMeta objectForKey:META_COPYRIGHT_KEY];
	if(value != nil && !displayOnlyPlot)
		[metaLayer setCopyright:value];
	
	/*Get the season and episodes*/
	value = [allMeta objectForKey:META_EPISODE_AND_SEASON_KEY];
	if(value != nil)
	{
		/*Remove the individuals so we don't display them*/
		[allMeta removeObjectForKey:META_EPISODE_NUMBER_KEY];
		[allMeta removeObjectForKey:META_EPISODE_2_NUMBER_KEY];
		[allMeta removeObjectForKey:META_SEASON_NUMBER_KEY];
	}
}

/*!
 * @brief populate metadata for Movies
 */
- (void) populateMovieMetadataWith:(NSMutableDictionary*)allMeta
{
	/* Get the movie title */
	NSString *value=nil;
	value = [allMeta objectForKey:META_MOVIE_TITLE_KEY];
	BRMetadataLayer *metaLayer = [self gimmieMetadataLayer];

	/*Get the release date*/
	NSDate *releaseDate = [allMeta objectForKey:META_MOVIE_RELEASE_DATE_KEY];
	if(releaseDate != nil)
	{
		NSDateFormatter *format = [[NSDateFormatter alloc] init];
		[format setDateStyle:NSDateFormatterLongStyle];
		[format setTimeZone:NSDateFormatterNoStyle];
		value = [NSString stringWithFormat:@"Premiered: %@",[format stringFromDate:releaseDate]];
		[format release];
		[allMeta removeObjectForKey:META_MOVIE_RELEASE_DATE_KEY];
		[allMeta removeObjectForKey:META_MOVIE_TITLE_KEY];
	}
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	BOOL displayOnlyPlot = [settings displayOnlyPlot];
	/* No release date, sub in the movie title */
	[metaLayer setTitle:value];

	/*Get the rating*/
	value=nil;
	value = [allMeta objectForKey:META_MOVIE_MPAA_RATING_KEY];
	if(value != nil && !displayOnlyPlot)
		[metaLayer setRating:value];
	/*Get the movie plot*/
	value=nil;
	value = [allMeta objectForKey:META_MOVIE_PLOT_KEY];
	if(value != nil)
		if([settings displaySpoilers] || displayOnlyPlot)
			[metaLayer setSummary:value];
	
	NSArray *values=nil;
	/* Get genres */
	values=[allMeta objectForKey:META_MOVIE_GENRES_KEY];
	if(values!=nil)
	{
		value = [(NSArray *)values componentsJoinedByString:@", "];
		/* sub the array for a formatted string */
		[allMeta setObject:value forKey:META_MOVIE_GENRES_KEY];
	}
	/* Get directors */
	values=nil;
	values=[allMeta objectForKey:META_MOVIE_DIRECTOR_KEY];
	if(values!=nil)
	{
		value = [(NSArray *)values componentsJoinedByString:@", "];
		/* sub the array for a formatted string */
		[allMeta setObject:value forKey:META_MOVIE_DIRECTOR_KEY];
	}
	/* Get cast */
	values=nil;
	values=[allMeta objectForKey:META_MOVIE_CAST_KEY];
	if(values!=nil)
	{
		NSArray *subCast = (NSArray *)values;
		if([subCast count] > 3)
			subCast = [(NSArray *)values subarrayWithRange:NSMakeRange(0, 3)];
		value = [subCast componentsJoinedByString:@", "];
		[allMeta setObject:value forKey:META_MOVIE_CAST_KEY];
	}
	/* Get IMDB Stats */
	value=nil ;
	value=[allMeta objectForKey:META_MOVIE_IMDB_RATING_KEY];
	if(value!=nil)
	{
		value=[NSString stringWithFormat:@"%1.1f/10",[value floatValue]];
		NSString *top250=nil;
		top250=[allMeta objectForKey:META_MOVIE_IMDB_250_KEY];
		if(top250!=nil)
			value=[NSString stringWithFormat:@"#%@ on Top 250 (%@)",top250,value];
		else
			value=[NSString stringWithFormat:@"User Rated %@",value];
		[allMeta removeObjectForKey:META_MOVIE_IMDB_RATING_KEY];
		[allMeta removeObjectForKey:META_MOVIE_IMDB_250_KEY];
		[allMeta setObject:value forKey:META_MOVIE_IMDB_STATS_KEY];
	}
}

/*!
 * @brief populate utility data
 */
- (void)populateUtilityDataWith:(NSMutableDictionary *)allMeta
{
	BRMetadataLayer *metaLayer = [self gimmieMetadataLayer];
	/* Get the setting name */
	NSString *value = [allMeta objectForKey:META_TITLE_KEY];
	if(value != nil)
		[metaLayer setTitle:value];
	/*Get the setting description*/
	value = [allMeta objectForKey:META_DESCRIPTION_KEY];
	if(value != nil)
			[metaLayer setSummary:value];
}

/*!
 * @brief populate generic file data
 */
- (void)populateGenericMetadataWith:(NSMutableDictionary *)allMeta
{
	NSString *value = [allMeta objectForKey:META_TITLE_KEY];
	BRMetadataLayer *metaLayer = [self gimmieMetadataLayer];
	if(value != nil)
		[metaLayer setTitle:value];
	
	/*Get the rating*/
	value = [allMeta objectForKey:META_RATING_KEY];
	if(value != nil)
		[metaLayer setRating:value];
	
	/*Get the description*/
	value = [allMeta objectForKey:META_DESCRIPTION_KEY];
	if(value != nil)
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[metaLayer setSummary:value];
	
	/*Get the copyright*/
	value = [allMeta objectForKey:META_COPYRIGHT_KEY];
	if(value != nil)
		[metaLayer setCopyright:value];
	
	/*Get the rating*/
	value=nil;
	value = [allMeta objectForKey:META_MOVIE_MPAA_RATING_KEY];
	if(value != nil)
		[metaLayer setRating:value];
	/*Get the movie plot*/
	value=nil;
	value = [allMeta objectForKey:META_MOVIE_PLOT_KEY];
	if(value != nil)
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[metaLayer setSummary:value];
	
	NSArray *values=nil;
	/* Get genres */
	values=[allMeta objectForKey:META_MOVIE_GENRES_KEY];
	value=[NSString string];
	if(values!=nil)
	{
		NSEnumerator *valuesEnum = [values objectEnumerator] ;
		NSString *aValue=nil;
		while((aValue = [valuesEnum nextObject]) !=nil)
		{
			value=[value stringByAppendingString:[NSString stringWithFormat:@"%@, ",aValue]];
		}
		/* get rid of the extra comma */
		value=[value substringToIndex:[value length]-2];
		/* sub the array for a formatted string */
		[allMeta setObject:value forKey:META_MOVIE_GENRES_KEY];
	}
	/* Get directors */
	values=nil;
	values=[allMeta objectForKey:META_MOVIE_DIRECTOR_KEY];
	value=[NSString string];
	if(values!=nil)
	{
		NSEnumerator *valuesEnum = [values objectEnumerator] ;
		NSString *aValue=nil;
		while((aValue = [valuesEnum nextObject]) !=nil)
		{
			value=[value stringByAppendingString:[NSString stringWithFormat:@"%@, ",aValue]];
		}
		/* get rid of the extra comma */
		value=[value substringToIndex:[value length]-2];
		/* sub the array for a formatted string */
		[allMeta setObject:value forKey:META_MOVIE_DIRECTOR_KEY];
	}
	/* Get cast */
	values=nil;
	values=[allMeta objectForKey:META_MOVIE_CAST_KEY];
	value=[NSString string];
	if(values!=nil)
	{
		NSEnumerator *valuesEnum = [values objectEnumerator] ;
		NSString *aValue=nil;
		NSString *lastToAdd = nil;
		if([values count]>2)
			lastToAdd=[values objectAtIndex:2] ;
		while((aValue = [valuesEnum nextObject]) !=nil)
		{
			value=[value stringByAppendingString:[NSString stringWithFormat:@"%@, ",aValue]];
			if([aValue isEqualToString:lastToAdd])break;
		}
		/* get rid of the extra comma */
		value=[value substringToIndex:[value length]-2];
		/* sub the array for a formatted string */
		[allMeta setObject:value forKey:META_MOVIE_CAST_KEY];
	}	
}

/*!
 * @brief populate metadata for media files
 */
- (void)_populateMetadata
{
	[super _populateMetadata];
	[self doPopulation];
}

/*!
 * @brief populate metadata for media files
 */
- (void)_updateMetadataLayer
{
	[super _updateMetadataLayer];
	/*See if it loaded anything*/
	if(![SapphireFrontRowCompat usingLeopardOrATypeOfTakeTwo])
		return;
	
	[self doPopulation];
}

- (NSString *)keyForDisplay:(NSString *)key
{
	static NSDictionary *keyTranslations = nil;
	if(keyTranslations == nil)
	{
		keyTranslations = [[NSDictionary alloc] initWithObjectsAndKeys:
						   //File Info
						   BRLocalizedString( @"Audio",     @"First audio track details" ),  AUDIO_DESC_LABEL_KEY,
						   BRLocalizedString( @"Audio2",    @"Second audio track details" ), AUDIO2_DESC_LABEL_KEY,
						   BRLocalizedString( @"Duration",  @"Track duration" ),             META_FILE_DURATION_KEY,
						   BRLocalizedString( @"Size",      @"Track size" ),                 META_FILE_SIZE_KEY,
						   BRLocalizedString( @"Subtitles", @"Track subtitles" ),            SUBTITLE_LABEL_KEY,
						   BRLocalizedString( @"Video",     @"First video track details" ),  VIDEO_DESC_LABEL_KEY,
						   BRLocalizedString( @"Video2",    @"Second video track details" ), VIDEO2_DESC_LABEL_KEY,
						   //Movie Info
						   BRLocalizedString( @"Cast",      @"Movie cast" ),                 META_MOVIE_CAST_KEY,
						   BRLocalizedString( @"Director",  @"Director" ),                   META_MOVIE_DIRECTOR_KEY,
						   BRLocalizedString( @"Genres",    @"Movie genres" ),               META_MOVIE_GENRES_KEY,
						   BRLocalizedString( @"IMDB",      @"IMDb rating" ),                META_MOVIE_IMDB_STATS_KEY,
						   nil];
	}

	NSString *translation = [keyTranslations objectForKey:key];
	if(translation)
		return translation;
	
	//Nothing found, return the original
	return key;
}

- (void)doPopulation
{
	/*Get our data then*/
	NSArray *order = nil;
	NSMutableDictionary *allMeta = nil;
	FileClass fileClass=FILE_CLASS_UNKNOWN ;
	if([meta respondsToSelector:@selector(getDisplayedMetaDataInOrder:)])
	{
		allMeta=[(id)meta getDisplayedMetaDataInOrder:&order];
		if([meta conformsToProtocol:@protocol(SapphireDirectory)])
			fileClass=FILE_CLASS_NOT_FILE;
		else
			fileClass=(FileClass)[(SapphireFileMetaData *) meta fileClassValue];
	}
	if(!allMeta)
		fileClass=FILE_CLASS_UTILITY;
	if(imageOnly)
	{	
		fileClass = FILE_CLASS_NOT_FILE;
		[allMeta removeAllObjects];
	}
		
	BRMetadataLayer *metaLayer = [self gimmieMetadataLayer];
	/* TV Show Preview Handeling */
	if(fileClass==FILE_CLASS_TV_SHOW)
	{
		[self  populateTVShowMetadataWith:allMeta];
	}
	/* Movie Preview Handeling */
	else if(fileClass==FILE_CLASS_MOVIE)
	{
		[self populateMovieMetadataWith:allMeta];
	}
	/* Utility Preview Handeling */
	else if(fileClass == FILE_CLASS_UTILITY)
	{
		[self populateUtilityDataWith:(NSMutableDictionary *)meta];
	}
	else if(fileClass != FILE_CLASS_NOT_FILE)
	{
		[self populateGenericMetadataWith:allMeta];
	}
	/* Directory Preview Handeling */
	else
	{
		NSString *value = [allMeta objectForKey:META_TITLE_KEY];
		if(value != nil)
			[metaLayer setTitle:value];
	}
	
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	BOOL displayOnlyPlot = [settings displayOnlyPlot];
	/* Show / Hide perian info */
	if(![settings displayAudio] || displayOnlyPlot)
	{
		[allMeta removeObjectForKey:AUDIO_DESC_LABEL_KEY];
		[allMeta removeObjectForKey:AUDIO2_DESC_LABEL_KEY];
		[allMeta removeObjectForKey:SUBTITLE_LABEL_KEY];        
	}
	if(![settings displayVideo] || displayOnlyPlot)
	{
		[allMeta removeObjectForKey:VIDEO_DESC_LABEL_KEY];
		[allMeta removeObjectForKey:VIDEO2_DESC_LABEL_KEY];
	}
	if(displayOnlyPlot)
	{
		[allMeta removeObjectForKey:META_FILE_SUBTITLES_KEY];
		[allMeta removeObjectForKey:META_FILE_SIZE_KEY];
		[allMeta removeObjectForKey:META_FILE_DURATION_KEY];
		
		//TV
		[allMeta removeObjectForKey:META_SHOW_AIR_DATE];
		[allMeta removeObjectForKey:BRLocalizedString(@"Season", @"Season in metadata display")];
		[allMeta removeObjectForKey:BRLocalizedString(@"Episode", @"Episode in metadata display")];
		[allMeta removeObjectForKey:BRLocalizedString(@"S/E", @"Season / Episode in metadata display")];
		
		//Movie
		[allMeta removeObjectForKey:META_MOVIE_MPAA_RATING_KEY];
		[allMeta removeObjectForKey:META_MOVIE_IMDB_RATING_KEY];
		[allMeta removeObjectForKey:META_MOVIE_RELEASE_DATE_KEY];
		[allMeta removeObjectForKey:META_MOVIE_IMDB_250_KEY];
		[allMeta removeObjectForKey:META_MOVIE_OSCAR_KEY];
		[allMeta removeObjectForKey:META_MOVIE_DIRECTOR_KEY];
		[allMeta removeObjectForKey:META_MOVIE_CAST_KEY];
		[allMeta removeObjectForKey:META_MOVIE_GENRES_KEY];
		[allMeta removeObjectForKey:META_MOVIE_IMDB_STATS_KEY];
	}
	
	NSMutableArray *values = [NSMutableArray array];
	NSMutableArray *keys = [NSMutableArray array];
	
	/*Put the metadata in order*/
	NSEnumerator *keyEnum = [order objectEnumerator];
	NSString *key = nil;
	while((key = [keyEnum nextObject]) != nil)
	{
		NSString *value = [allMeta objectForKey:key];
		if(value != nil)
		{
			[values addObject:value];
			[keys addObject:[self keyForDisplay:key]];
		}
	}
	
	/*And set it*/
	[metaLayer setMetadata:values withLabels:keys];
}

/*!
 * @brief Override the info about whether it has metadata
 *
 * @return We always have metadata
 */
- (BOOL)_assetHasMetadata
{
	return YES;
}

@end
