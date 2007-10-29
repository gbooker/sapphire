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

- (void)dealloc
{
	[meta release];
	[super dealloc];
}

/*!
 * @brief Set the File information
 *
 * @param newMeta The meta data
 */
- (void)setMetaData:(SapphireMetaData *)newMeta
{
	[meta release];
	NSString *path = [newMeta path];
	if(path == nil)
	{
		meta = nil;
		return;
	}
	meta = [newMeta retain];
	/*Now that we know the file, set the asset*/
	NSURL *url = [NSURL fileURLWithPath:[meta path]];
	SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
	[self setAsset:asset];
}

/*!
 * @brief Search for cover art in the current path
 *
 * @param path Path to search for cover art, minus the extension
 * @return The path to the found cover art
 */
- (NSString *)searchExtForPath:(NSString *)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	/*Search all extensions*/
	NSEnumerator *extEnum = [coverArtExtentions objectEnumerator];
	NSString *ext = nil;
	while((ext = [extEnum nextObject]) != nil)
	{
		NSString *candidate = [path stringByAppendingPathExtension:ext];
		/*Check the candidate*/
		if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
			return candidate;
	}
	/*Didn't find one*/
	return nil;
}

/*!
 * @brief Searches for the directory's cover art
 *
 * @param dir the directory to search
 * @param parents the number of parent directories to search after this one
 * @return The path to the found cover art
 */
- (NSString *)coverArtForDir:(NSString *)dir parents:(int)parents
{
	/*Check for cover.ext in the "Cover Art" dir*/
	NSString *ret = [self searchExtForPath:[dir stringByAppendingPathComponent:@"Cover Art/cover"]];
	if(ret != nil)
		return ret;
	/*Next check for cover.ext in the current dir*/
	ret = [self searchExtForPath:[dir stringByAppendingPathComponent:@"cover"]];
	if(ret != nil)
		return ret;
	/*Finally, try going up a dir*/
	if(parents != 0)
		return [self coverArtForDir:[dir stringByDeletingLastPathComponent] parents:parents -1];
	/*Didn't find one*/
	return nil;
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
		/*Search for cover art for the current directory or a single parent dir*/
		NSString *ret = [self coverArtForDir:[meta path] parents:1];
		if(ret != nil)
			return ret;
		/*Fallback to default*/
		return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
	}

	/*Find cover art for the current file in the "Cover Art" dir*/
	NSString *subPath = [[meta path] stringByDeletingPathExtension];
	NSString *fileName = [subPath lastPathComponent];
	NSString *ret = [self searchExtForPath:[[[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:fileName]];
	if(ret != nil)
		return ret;
	
	/*Find cover art for the current file in the current dir*/
	ret = [self searchExtForPath:subPath];
	if(ret != nil)
		return ret;
	
	/*Find cover art for the parent or its parent dir*/
	ret = [self coverArtForDir:[subPath stringByDeletingLastPathComponent] parents:2];
	if(ret != nil)
		return ret;
	
	/*Fallback to default*/
	return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
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
		[_metadataLayer setTitle:value];
	}
	
	/*Get the rating*/
	value = [allMeta objectForKey:META_RATING_KEY];
	if(value != nil)
		[_metadataLayer setRating:value];
	
	/*Get the description*/
	value = [allMeta objectForKey:META_DESCRIPTION_KEY];
	if(value != nil)
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[_metadataLayer setSummary:value];
	
	/*Get the copyright*/
	value = [allMeta objectForKey:META_COPYRIGHT_KEY];
	if(value != nil)
		[_metadataLayer setCopyright:value];
	
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
	if(value != nil)
	{
		/*If there is a release date, put it in the title*/
		NSDate *releaseDate = [allMeta objectForKey:META_MOVIE_RELEASE_DATE_KEY];
		if(releaseDate != nil)
		{
			NSDateFormatter *format = [[NSDateFormatter alloc] init];
			[format setDateStyle:NSDateFormatterShortStyle];
			[format setTimeZone:NSDateFormatterNoStyle];
			value = [[format stringFromDate:releaseDate]stringByAppendingFormat:@" - %@", value];
			[allMeta removeObjectForKey:META_MOVIE_RELEASE_DATE_KEY];
			[allMeta removeObjectForKey:META_MOVIE_TITLE_KEY];
		}
		[_metadataLayer setTitle:value];
	}
	/*Get the movie plot*/
	value=nil;
	value = [allMeta objectForKey:META_MOVIE_PLOT_KEY];
	if(value != nil)
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[_metadataLayer setSummary:value];
	
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
}


/*!
 * @brief populate metadata for media files
 */
- (void)_populateMetadata
{
	[super _populateMetadata];
	/*See if it loaded anything*/
	if([[_metadataLayer gimmieMetadataObjs] count])
		return;
	
	/*Get our data then*/
	NSArray *order = nil;
	NSMutableDictionary *allMeta = [meta getDisplayedMetaDataInOrder:&order];
	
	FileClass fileClass=FILE_CLASS_UNKNOWN ;
	if([meta isKindOfClass:[SapphireDirectoryMetaData class]])
		fileClass=FILE_CLASS_NOT_FILE;
	else
		fileClass=(FileClass)[(SapphireFileMetaData *) meta fileClass];
		
	
	
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
			[_metadataLayer setTitle:value];
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
			[keys addObject:key];
		}
	}
	
	/*And set it*/
	[_metadataLayer setMetadata:values withLabels:keys];

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
