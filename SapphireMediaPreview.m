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
	NSString *subPath2 = nil;
	NSString *subPath3 = nil;

	if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		subPath = [[meta path] stringByDeletingPathExtension];
		subPath2 =[[[meta path] stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"cover"];
		subPath3 =[[[[meta path] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"cover"];
	}
	else
		subPath = [[meta path] stringByAppendingPathComponent:@"cover"];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	BOOL foundSubPath2 = NO ;
	BOOL foundSubPath3 = NO ;
	NSString *candidate2 = nil;
	NSString *candidate3 = nil;
	NSEnumerator *extEnum = [coverArtExtentions objectEnumerator];
	NSString *ext = nil;
	while((ext = [extEnum nextObject]) != nil)
	{
		NSString *candidate =   [subPath stringByAppendingPathExtension:ext];
		if(!foundSubPath2) candidate2 = [subPath2 stringByAppendingPathExtension:ext];
		if(!foundSubPath3 && !foundSubPath2)candidate3 = [subPath3 stringByAppendingPathExtension:ext];
		if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
			return candidate;
		if([fm fileExistsAtPath:candidate2 isDirectory:&isDir] && !isDir)foundSubPath2=TRUE ;
		if([fm fileExistsAtPath:candidate3 isDirectory:&isDir] && !isDir && !foundSubPath2)foundSubPath3=TRUE ;
	}
	if(!isDir)
	{
		if(foundSubPath2) return candidate2 ;
		if(foundSubPath3) return candidate3 ;
	/*
		extEnum = [coverArtExtentions objectEnumerator];
		ext=nil ;
		subPath =[[[meta path] stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"cover"];
		while((ext = [extEnum nextObject]) != nil)
		{
			NSString *candidate = [subPath stringByAppendingPathExtension:ext];
			if([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir)
				return candidate;
		}
	*/	
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
