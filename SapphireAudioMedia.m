//
//  SapphireAudioMedia.m
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireAudioMedia.h"
#import <QTKit/QTKit.h>

@implementation SapphireAudioMedia

- (void) dealloc
{
	[movie release];
	[super dealloc];
}

- (void)setMovie:(QTMovie *)newMovie
{
	[movie release];
	movie = [newMovie retain];
}

- (NSString *)title
{
	return [movie attributeForKey:QTMovieDisplayNameAttribute];
}

- (int)duration
{
	QTTime duration = [movie duration];
	double ret = 0.0;
	QTGetTimeInterval(duration, &ret);
	return (int)ret;
}

- (CGImageRef)coverArt
{
	NSImage *retNSI = [movie posterImage];
	if(retNSI != nil)
	{
		int bytesPerPixel = 4;
		int bitsPerComponent = 8;
		int bytesPerRow = [retNSI size].width * bytesPerPixel;
		int imageSize = bytesPerRow * [retNSI size].height;
		Ptr contextMemory = NewPtr( imageSize );
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		CGContextRef cgContext = CGBitmapContextCreate (contextMemory, [retNSI size].width, [retNSI size].height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
		NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
		
		[NSGraphicsContext setCurrentContext:nsContext];
		[NSGraphicsContext saveGraphicsState];
		[retNSI drawAtPoint:NSMakePoint(0,0) fromRect:NSMakeRect(0,0,[retNSI size].width, [retNSI size].height) operation:NSCompositeSourceOver fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];
		
		CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
		if(cgImage != NULL)
			return cgImage;
	}
	
	NSString *path = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
	NSURL *url = [NSURL fileURLWithPath:path];
	return CreateImageForURL(url);
}

@end
