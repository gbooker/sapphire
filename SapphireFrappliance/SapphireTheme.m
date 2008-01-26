/*
 * SapphireTheme.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 27, 2007.
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

#import "SapphireTheme.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

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
		@"Contents/Resources/AC3.png", AC3_GEM_KEY,
		@"Contents/Resources/Audio.png", AUDIO_GEM_KEY,
		@"Contents/Resources/Video.png", VIDEO_GEM_KEY,
		@"Contents/Resources/TV.png", TV_GEM_KEY,
		@"Contents/Resources/Movie.png", MOV_GEM_KEY,
		@"Contents/Resources/AMPAS_Oscar.png", OSCAR_GEM_KEY,
		@"Contents/Resources/IMDB.png", IMDB_GEM_KEY,
		@"Contents/Resources/TVRage.png", TVR_GEM_KEY,
		@"Contents/Resources/File.png", FILE_GEM_KEY,
		@"Contents/Resources/Report.png", REPORT_GEM_KEY,
		@"Contents/Resources/Note.png", NOTE_GEM_KEY,
		@"Contents/Resources/Import.png", IMPORT_GEM_KEY,
		@"Contents/Resources/FrontRow.png", FRONTROW_GEM_KEY,
		@"Contents/Resources/FastSwitch.png", FAST_GEM_KEY,
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
	/*Flush cache in case the scene is different and it matters*/
	[gemDict removeAllObjects];
	scene = [theScene retain];
}

/*!
 * @brief Load an image from a path
 *
 * @param path The image path
 * @return A CGImageRef (retained) from the path
 */
- (CGImageRef)loadImage:(NSString *)path
{
	NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
	NSURL *url = [NSURL fileURLWithPath:[bundlePath stringByAppendingPathComponent:path]];
	CGImageRef        imageRef = NULL;
    CGImageSourceRef  sourceRef;
	sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	if(sourceRef) {
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
	
    return imageRef;
}

- (BRTexture *)gem:(NSString *)type
{
	/*Check cache*/
	BRTexture *ret = [gemDict objectForKey:type];
	if(ret != nil)
		return ret;
	
	if([SapphireFrontRowCompat usingFrontRow])
	{
		NSString *bundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
		id ret = [SapphireFrontRowCompat imageAtPath:[bundlePath stringByAppendingPathComponent:[gemFiles objectForKey:type]]];
		if(ret != nil)
			[gemDict setObject:ret forKey:type];
		return ret;
	}
	/*Load it*/
	CGImageRef image = [self loadImage:[gemFiles objectForKey:type]];
	if(image != NULL)
	{
		/*Create a texture*/
		ret = [BRBitmapTexture textureWithImage:image context:[scene resourceContext] mipmap:YES];
		CFRelease(image);
	}
	/*Save in the cache*/
	if(ret != nil)
		[gemDict setObject:ret forKey:type];
	/*return it*/
	return ret;
}

@end