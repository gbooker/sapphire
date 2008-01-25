/*
 * SapphireAudioMedia.m
 * Sapphire
 *
 * Created by Graham Booker on Jul. 28, 2007.
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

#import "SapphireAudioMedia.h"
#import <QTKit/QTKit.h>

@implementation SapphireAudioMedia

- (void) dealloc
{
	[movie release];
	if(coverArt != NULL)
		CGImageRelease(coverArt);
	[super dealloc];
}

- (NSData *)dataForMetaDataKey:(OSType)key
{
	QTMetaDataItem item = kQTMetaDataItemUninitialized;
	QTMetaDataRef metaData = NULL;
	OSStatus err = QTCopyMovieMetaData([movie quickTimeMovie], &metaData);
	if(err == noErr)
		err = QTMetaDataGetNextItem(metaData, kQTMetaDataStorageFormatiTunes, item, kQTMetaDataKeyFormatCommon, (const UInt8 *)&key, sizeof(key), &item);
	
	QTPropertyValuePtr value = NULL;
	ByteCount valueSize;
	if(err == noErr && item != kQTMetaDataNoMoreItemsErr)
	{
		err = QTMetaDataGetItemValue(metaData, item, NULL, 0, &valueSize);
		if(err == noErr)
		{
			value = malloc(valueSize);
			err = QTMetaDataGetItemValue(metaData, item, value, valueSize, NULL);
		}
	}
	if(metaData != NULL)
		QTMetaDataRelease(metaData);

	NSData *ret = nil;
	if(value != NULL)
	{
		ret = [NSData dataWithBytes:value length:valueSize];
		free(value);
	}
	
	return ret;
}

- (NSString *)stringForKeyMetaData:(OSType)key
{
	NSData *stringData = [self dataForMetaDataKey:key];
	if(stringData != NULL)
		return [[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding] autorelease];
	return nil;
}

- (void)setMovie:(QTMovie *)newMovie
{
	[movie release];
	if(coverArt != NULL)
		CGImageRelease(coverArt);
	coverArt = NULL;
	movie = [newMovie retain];
	
	NSData *data = [self dataForMetaDataKey:kQTMetaDataCommonKeyArtwork];
	if(data != NULL)
	{
		CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, nil);
		if(source != NULL)
		{
			coverArt = CGImageSourceCreateImageAtIndex(source, 1, nil);
			CFRelease(source);
		}
	}
	
	if(coverArt == NULL)
	{
		NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultPreview" ofType:@"png"];
		NSURL *url = [NSURL fileURLWithPath:path];
		CGImageSourceRef  sourceRef;
		
		sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
		if(sourceRef) {
			coverArt = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
			CFRelease(sourceRef);
		}	
	}
}

- (NSString *)artist
{
	return [self stringForKeyMetaData:kQTMetaDataCommonKeyArtist];
}

- (NSString *)copyright
{
	return [self stringForKeyMetaData:kQTMetaDataCommonKeyCopyright];
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
	return coverArt;
}

@end
