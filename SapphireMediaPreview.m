//
//  SapphireMediaPreview.m
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMediaPreview.h"
#import "SapphireMetaData.h"
#import "SapphireMedia.h"
#import "SapphireSettings.h"

@interface BRMetadataLayer (protectedAccess)
- (NSArray *)gimmieMetadataObjs;
@end

@implementation BRMetadataLayer (protectedAccess)
- (NSArray *)gimmieMetadataObjs
{
	if([self respondsToSelector:@selector(setStarRating:)])
		//This object is in a different possition
		return _metadataLabels;
	return _metadataObjs;
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

- (NSString *)coverArtForPath
{
	NSString *subPath = nil;
	int parents = 1;

	if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		subPath = [[meta path] stringByDeletingPathExtension];
		parents = 2;
	}
	else
		subPath = [[meta path] stringByAppendingPathComponent:@"cover"];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	while(parents >= 0)
	{
		NSEnumerator *extEnum = [coverArtExtentions objectEnumerator];
		NSString *ext = nil;
		while((ext = [extEnum nextObject]) != nil)
		{
			NSString *candidate = [subPath stringByAppendingPathExtension:ext];
			if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
				return candidate;
		}
		if(parents == 2)
			subPath = [[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"];
		else
			subPath = [[[subPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover"];
		parents--;
	}
	return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/ApplianceIcon.png"];
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
	NSMutableDictionary *allMeta = [meta getDisplayedMetaData];
	NSString *value = [allMeta objectForKey:META_TITLE_KEY];
	if(value != nil)
	{
		[_metadataLayer setTitle:value];
		[allMeta removeObjectForKey:META_TITLE_KEY];
	}
	value = [allMeta objectForKey:META_RATING_KEY];
	if(value != nil)
	{
		[_metadataLayer setRating:value];
		[allMeta removeObjectForKey:META_RATING_KEY];
	}
	value = [allMeta objectForKey:META_SUMMARY_KEY];
	if(value != nil)
	{
		if([[SapphireSettings sharedSettings] displaySpoilers])
			[_metadataLayer setSummary:value];
		[allMeta removeObjectForKey:META_SUMMARY_KEY];
	}
	value = [allMeta objectForKey:META_COPYRIGHT_KEY];
	if(value != nil)
	{
		[_metadataLayer setCopyright:value];
		[allMeta removeObjectForKey:META_COPYRIGHT_KEY];
	}
	[_metadataLayer setMetadata:[allMeta allValues] withLabels:[allMeta allKeys]];
}

- (BOOL)_assetHasMetadata
{
	return YES;
}


@end
