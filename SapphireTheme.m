//
//  SapphireTheme.m
//  Sapphire
//
//  Created by Graham Booker on 6/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireTheme.h"


@implementation SapphireTheme

+ (id)sharedTheme
{
	static SapphireTheme *shared = nil;
	if(shared == nil)
		shared = [[SapphireTheme alloc] init];
	
	return shared;
}

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	gemDict = [NSMutableDictionary new];
	gemFiles = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Contents/Resources/Orange_Red.png", RED_GEM_KEY,
		@"Contents/Resources/Blue.png", BLUE_GEM_KEY,
		@"Contents/Resources/Green.png", GREEN_GEM_KEY,
		@"Contents/Resources/Yellow.png", YELLOW_GEM_KEY,
		@"Contents/Resources/Gear.png", GEAR_GEM_KEY,
		@"Contents/Resources/Cone.png", CONE_GEM_KEY,
		@"Contents/Resources/Eye.png", EYE_GEM_KEY,
		nil];
	
	return self;
}

- (void)dealloc
{
	[gemDict release];
	[scene release];
	[gemFiles release];
	[super dealloc];
}

- (void)setScene:(BRRenderScene *)theScene
{
	[gemDict removeAllObjects];
	scene = [theScene retain];
}

- (CGImageRef)loadImage:(NSString *)path
{
	NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
	NSURL *url = [NSURL fileURLWithPath:[bundlePath stringByAppendingPathComponent:path]];
	CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	CGImageRef imageRef = NULL;
	if(sourceRef)
	{
		imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
		CFRelease(sourceRef);
	}
	return imageRef;
}

- (BRTexture *)gem:(NSString *)type
{
	BRTexture *ret = [gemDict objectForKey:type];
	if(ret != nil)
		return ret;
	
	CGImageRef image = [self loadImage:[gemFiles objectForKey:type]];
	if(image != NULL)
	{
		ret = [BRBitmapTexture textureWithImage:image context:[scene resourceContext] mipmap:YES];
		CFRelease(image);
	}
	if(ret != nil)
		[gemDict setObject:ret forKey:type];
	return ret;
}

@end
