//
//  SapphireMediaPreview.m
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMediaPreview.h"
#import "SapphireMetaData.h"
#import "SapphireMedia.h"
#import "SapphireSettings.h"
#import <objc/objc-class.h>

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

static NSSet *coverArtExtentions = nil;

+ (void)initialize
{
	coverArtExtentions = [[NSSet alloc] initWithObjects:
		@"jpg",
		@"tif",
		@"tiff",
		@"png",
		nil];
}

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	return self;
}

- (void)dealloc
{
	[meta release];
	[super dealloc];
}

- (void)setMetaData:(SapphireMetaData *)newMeta
{
	[meta release];
	meta = [newMeta retain];
	NSURL *url = [NSURL fileURLWithPath:[meta path]];
	SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
	[self setAsset:asset];
}

- (NSString *)searchExtForPath:(NSString *)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	NSEnumerator *extEnum = [coverArtExtentions objectEnumerator];
	NSString *ext = nil;
	while((ext = [extEnum nextObject]) != nil)
	{
		NSString *candidate = [path stringByAppendingPathExtension:ext];
		if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
			return candidate;
	}
	return nil;
}

- (NSString *)coverArtForDir:(NSString *)dir parents:(int)parents
{
	NSString *ret = [self searchExtForPath:[dir stringByAppendingPathComponent:@"Cover Art/cover"]];
	if(ret != nil)
		return ret;
	ret = [self searchExtForPath:[dir stringByAppendingPathComponent:@"cover"]];
	if(ret != nil)
		return ret;
	if(parents != 0)
		return [self coverArtForDir:[dir stringByDeletingLastPathComponent] parents:parents -1];
	return nil;
}

- (NSString *)coverArtForPath
{
	if([meta isKindOfClass:[SapphireDirectoryMetaData class]])
	{
		NSString *ret = [self coverArtForDir:[meta path] parents:1];
		if(ret != nil)
			return ret;
		return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
	}

	NSString *subPath = [[meta path] stringByDeletingPathExtension];
	NSString *fileName = [subPath lastPathComponent];
	NSString *ret = [self searchExtForPath:[[[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:fileName]];
	if(ret != nil)
		return ret;
	
	ret = [self searchExtForPath:subPath];
	if(ret != nil)
		return ret;
	
	ret = [self coverArtForDir:[subPath stringByDeletingLastPathComponent] parents:2];
	if(ret != nil)
		return ret;
	
	return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
}

- (void)_loadCoverArt
{
	[super _loadCoverArt];
	
	if([_coverArtLayer texture] != nil)
		return;
	
	NSString *path = [self coverArtForPath];
	NSURL *url = [NSURL fileURLWithPath:path];
	CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	CGImageRef imageRef = nil;
	if(sourceRef)
	{
		imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
		CFRelease(sourceRef);
	}
	if(imageRef)
	{
		[_coverArtLayer setImage:imageRef];
		CFRelease(imageRef);
	}	
}

- (void)_populateMetadata
{
	[super _populateMetadata];
	if([[_metadataLayer gimmieMetadataObjs] count])
		return;
	NSArray *order = nil;
	NSMutableDictionary *allMeta = [meta getDisplayedMetaDataInOrder:&order];
	NSString *value = [allMeta objectForKey:META_TITLE_KEY];
	if(value != nil)
	{
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

	value = [allMeta objectForKey:META_RATING_KEY];
	if(value != nil)
		[_metadataLayer setRating:value];

	value = [allMeta objectForKey:META_DESCRIPTION_KEY];
	if(value != nil)
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[_metadataLayer setSummary:value];

	value = [allMeta objectForKey:META_COPYRIGHT_KEY];
	if(value != nil)
		[_metadataLayer setCopyright:value];
	
	value = [allMeta objectForKey:META_EPISODE_AND_SEASON_KEY];
	if(value != nil)
	{
		[allMeta removeObjectForKey:META_EPISODE_NUMBER_KEY];
		[allMeta removeObjectForKey:META_SEASON_NUMBER_KEY];
	}
	
	NSMutableArray *values = [NSMutableArray array];
	NSMutableArray *keys = [NSMutableArray array];
	
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

	[_metadataLayer setMetadata:values withLabels:keys];
}

- (BOOL)_assetHasMetadata
{
	return YES;
}


@end
