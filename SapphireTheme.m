//
//  SapphireTheme.m
//  Sapphire
//
//  Created by Graham Booker on 6/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
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

- (BRTexture *)redGemForScene:(BRRenderScene *)scene;
{
	if(redGem == NULL)
	{
		redGem = [self loadImage:@"Contents/Resources/Orange_Red.png"];
		if(redGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:redGem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)blueGemForScene:(BRRenderScene *)scene
{
	if(blueGem == NULL)
	{
		blueGem = [self loadImage:@"Contents/Resources/Blue.png"];
		if(blueGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:blueGem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)greenGemForScene:(BRRenderScene *)scene
{
	if(greenGem == NULL)
	{
		greenGem = [self loadImage:@"Contents/Resources/Green.png"];
		if(greenGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:greenGem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)yellowGemForScene:(BRRenderScene *)scene
{
	if(yellowGem == NULL)
	{
		yellowGem = [self loadImage:@"Contents/Resources/Yellow.png"];
		if(yellowGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:yellowGem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)gearGemForScene:(BRRenderScene *)scene
{
	if(gearGem == NULL)
	{
		gearGem = [self loadImage:@"Contents/Resources/Gear.png"];
		if(gearGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:gearGem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)coneGemForScene:(BRRenderScene *)scene
{
	if(coneGem == NULL)
	{
		coneGem = [self loadImage:@"Contents/Resources/Cone.png"];
		if(coneGem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:coneGem context:[scene resourceContext] mipmap:YES];
}

@end
