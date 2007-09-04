//
//  SapphireAudioMedia.m
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
		NSString *path = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/DefaultPreview.png"];
		NSURL *url = [NSURL fileURLWithPath:path];
		coverArt = CreateImageForURL(url);		
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
