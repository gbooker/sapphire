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

- (BRTexture *)redJemForScene:(BRRenderScene *)scene;
{
	if(redJem == NULL)
	{
		redJem = [self loadImage:@"Contents/Resources/Orange_Red.png"];
		if(redJem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:redJem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)blueJemForScene:(BRRenderScene *)scene
{
	if(blueJem == NULL)
	{
		blueJem = [self loadImage:@"Contents/Resources/Orange_Blue.png"];
		if(blueJem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:blueJem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)greenJemForScene:(BRRenderScene *)scene
{
	if(greenJem == NULL)
	{
		greenJem = [self loadImage:@"Contents/Resources/Orange_Green.png"];
		if(greenJem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:greenJem context:[scene resourceContext] mipmap:YES];
}

- (BRTexture *)yellowJemForScene:(BRRenderScene *)scene
{
	if(yellowJem == NULL)
	{
		yellowJem = [self loadImage:@"Contents/Resources/Orange_Yellog.png"];
		if(yellowJem == NULL)
			return nil;
		
	}
	return [BRBitmapTexture textureWithImage:yellowJem context:[scene resourceContext] mipmap:YES];
}

@end
