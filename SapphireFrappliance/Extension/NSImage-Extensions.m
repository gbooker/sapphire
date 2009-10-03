/*
 * NSImage-Extensions.m
 * Sapphire
 *
 * Created by Warren Gavin on Oct. 7, 2007.
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

#import "NSImage-Extensions.h"
#import <QTKit/QTKit.h>

static NSData * imageAtTime( QTMovie *movie, QTTime frameTime )
{
	NSImage *image = [movie frameImageAtTime:frameTime];

	if ( image == nil )
		return nil;

	NSApplicationLoad(); // TIFFRepresentation won't work without this
	NSBitmapImageRep * imageBitmap = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

	return [imageBitmap representationUsingType:NSJPEGFileType properties:nil];
}

@implementation NSImage (QTImages)

+ (NSData *) imageFromMovie: (NSString *)path
{
	NSError * error     = nil;
	QTMovie * movie     = [QTMovie movieWithFile:path error:&error];	
	QTTime    imageTime = [movie duration];

	imageTime.timeValue /= 10;
	return imageAtTime( movie, imageTime );
}

+ (NSData *) imageFromMovie: (NSString *)path atTime: (unsigned int)instant
{
	NSError * error     = nil;
	QTMovie * movie     = [QTMovie movieWithFile:path error:&error];
	QTTime    imageTime = { instant, 1, 0 };

	return imageAtTime( movie, imageTime );
}

+ (NSArray *) imagesFromMovie: (NSString *)path forArraySize: (unsigned int) size
{
	SapphireLog(SAPPHIRE_LOG_FILE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Getting array of size %d from %@", size, path );
	NSError * error    = nil;
	QTMovie * movie    = [QTMovie movieWithFile:path error:&error];
	SapphireLog(SAPPHIRE_LOG_FILE, SAPPHIRE_LOG_LEVEL_DEBUG, @"movie opened");
	QTTime    duration = [movie duration];

	unsigned int i;
	NSMutableArray * images = [NSMutableArray arrayWithCapacity:size];

	srand(time(NULL));

	// Split the duration into 'size' chunks and take a random
	// image from each chunk
	for ( i = 0; i < size; ++i )
	{
		QTTime imageTime = duration;
		imageTime.timeValue = (rand() % (duration.timeValue/size)) + (i*duration.timeValue/size);

		SapphireLog(SAPPHIRE_LOG_FILE, SAPPHIRE_LOG_LEVEL_DEBUG, @"getting image");
		NSImage * image = [movie frameImageAtTime:imageTime];
		if ( image != nil )
			[images addObject:image];
	}

	SapphireLog(SAPPHIRE_LOG_FILE, SAPPHIRE_LOG_LEVEL_DEBUG, @"Returning array of size %d from %@", [images count], path );
	return images;
}

- (CGImageRef) newImageRef
{
	NSApplicationLoad(); // TIFFRepresentation won't work without this
	CGImageSourceRef sourceRef = CGImageSourceCreateWithData( (CFDataRef)[self TIFFRepresentation], NULL );
	
	CGImageRef ret = CGImageSourceCreateImageAtIndex( sourceRef, 0, NULL );
	CFRelease(sourceRef);
	
	return ret;
}

- (BOOL) writeToFile:(NSString *)path atomically:(BOOL)atomic
{
	NSApplicationLoad(); // TIFFRepresentation won't work without this
	NSBitmapImageRep * imageBitmap = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
	NSData           * imageData   = [imageBitmap representationUsingType:NSJPEGFileType properties:nil];

	return [imageData writeToFile:path atomically:atomic];
}

@end
