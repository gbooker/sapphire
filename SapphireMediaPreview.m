//
//  SapphireMediaPreview.m
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaPreview.h"
#import "SapphireMetaData.h"
#import "SapphireMedia.h"
#import "SapphireSettings.h"
#import <objc/objc-class.h>
#import "SapphireFrontRowCompat.h"

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

@interface SapphireMediaPreview (private)
- (void)doPopulation;
- (NSString *)coverArtForPath;
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

- (void)setMetaData:(SapphireMetaData *)newMeta inMetaData:(SapphireDirectoryMetaData *)dir
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
}

/*!
 * @brief Search for cover art for the current metadata
 *
 * @return The path to the found cover art
 */
- (NSString *)coverArtForPath
{
	/*See if this is a directory*/
	if([meta isKindOfClass:[SapphireDirectoryMetaData class]])
	{
		NSString *ret = [(SapphireDirectoryMetaData *)meta coverArtPath];
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
		}
		[metaLayer setTitle:value];
	}
	
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
	
	/*Get the season and epsiodes*/
	value = [allMeta objectForKey:META_EPISODE_AND_SEASON_KEY];
	if(value != nil)
	{
		/*Remove the individuals so we don't display them*/
		[allMeta removeObjectForKey:META_EPISODE_NUMBER_KEY];
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
		[allMeta removeObjectForKey:META_MOVIE_RELEASE_DATE_KEY];
		[allMeta removeObjectForKey:META_MOVIE_TITLE_KEY];
	}
	/* No release date, sub in the movie title */
	[metaLayer setTitle:value];

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
		NSString *lastToAdd;
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
 * @brief populate metadata for media files
 */
- (void)_populateMetadata
{
	[super _populateMetadata];
	/*See if it loaded anything*/
	if([[[self gimmieMetadataLayer] gimmieMetadataObjs] count])
		return;
	
	[self doPopulation];
}

/*!
 * @brief populate metadata for media files
 */
- (void)_updateMetadataLayer
{
	[super _updateMetadataLayer];
	/*See if it loaded anything*/
	if([[[self gimmieMetadataLayer] gimmieMetadataObjs] count] && ![SapphireFrontRowCompat usingFrontRow])
		return;
	
	[self doPopulation];
}

- (void)doPopulation
{
	/*Get our data then*/
	NSArray *order = nil;
	NSMutableDictionary *allMeta = [meta getDisplayedMetaDataInOrder:&order];
	
	FileClass fileClass=FILE_CLASS_UNKNOWN ;
	if([meta isKindOfClass:[SapphireDirectoryMetaData class]])
		fileClass=FILE_CLASS_NOT_FILE;
	else
		fileClass=(FileClass)[(SapphireFileMetaData *) meta fileClass];
		
	
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
	/* Directory Preview Handeling */
	else
	{
		NSString *value = [allMeta objectForKey:META_TITLE_KEY];
		if(value != nil)
			[metaLayer setTitle:value];
	}
	
	/* Show / Hide perian info */
	if(![[SapphireSettings sharedSettings] displayAudio])
		[allMeta removeObjectForKey:AUDIO_DESC_LABEL_KEY];
	if(![[SapphireSettings sharedSettings] displayVideo])
		[allMeta removeObjectForKey:VIDEO_DESC_LABEL_KEY];
	
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
			[keys addObject:key];
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
