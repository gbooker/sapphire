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

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireAudioMedia.h"
#import <QTKit/QTKit.h>

@implementation SapphireAudioMedia

- (void) dealloc
{
	[movie release];
	[file release];
	[coverArt release];
	[super dealloc];
}

- (NSData *)dataForMetaDataKey:(OSType)key format:(OSType)format
{
	QTMetaDataItem item = kQTMetaDataItemUninitialized;
	QTMetaDataRef metaData = NULL;
	OSStatus err = QTCopyMovieMetaData([movie quickTimeMovie], &metaData);
	if(err == noErr)
		err = QTMetaDataGetNextItem(metaData, format, item, kQTMetaDataKeyFormatCommon, (const UInt8 *)&key, sizeof(key), &item);
	
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

- (NSString *)stringForKeyMetaData:(OSType)key format:(OSType)format
{
	NSData *stringData = [self dataForMetaDataKey:key format:format];
	if(stringData != NULL)
		return [[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding] autorelease];
	return nil;
}

- (void)setMovie:(QTMovie *)newMovie
{
	[movie release];
	[coverArt release];
	coverArt = NULL;
	movie = [newMovie retain];
	
	NSData *data = [self dataForMetaDataKey:kQTMetaDataCommonKeyArtwork format:kQTMetaDataStorageFormatQuickTime];
	if(data != NULL)
		coverArt = [[SapphireFrontRowCompat imageFromData:data] retain];
	
	if(coverArt == NULL)
	{
		NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultPreview" ofType:@"png"];
		coverArt = [[SapphireFrontRowCompat imageAtPath:path] retain];
	}
}

- (void)setFileMetaData:(SapphireFileMetaData *)meta
{
	[file release];
	file = [meta retain];
}

- (SapphireFileMetaData *)fileMetaData
{
	return file;
}

- (NSString *)artist
{
	NSString *artist = [self stringForKeyMetaData:kQTMetaDataCommonKeyArtist format:kQTMetaDataStorageFormatQuickTime];
	if(artist == nil)
		artist = [self stringForKeyMetaData:kUserDataTextArtist format:kQTMetaDataStorageFormatUserData];
	return artist;
}

- (NSString *)copyright
{
	NSString *copyright = [self stringForKeyMetaData:kQTMetaDataCommonKeyCopyright format:kQTMetaDataStorageFormatQuickTime];
	if(copyright == nil)
		copyright = [self stringForKeyMetaData:kUserDataTextCopyright format:kQTMetaDataStorageFormatUserData];
	return copyright;
}

- (NSString *)title
{
	NSString *fileTitle = [movie attributeForKey:QTMovieDisplayNameAttribute];
	return fileTitle;
}

- (NSString *)primaryCollectionTitle
{
	NSString *album = [self stringForKeyMetaData:kQTMetaDataCommonKeyAlbum format:kQTMetaDataStorageFormatQuickTime];
	if(album == nil)
		album = [self stringForKeyMetaData:kUserDataTextAlbum format:kQTMetaDataStorageFormatUserData];
	return album;
}

- (long)duration
{
	QTTime duration = [movie duration];
	double ret = 0.0;
	QTGetTimeInterval(duration, &ret);
	return (int)ret;
}

- (id)coverArt
{
	return coverArt;
}

@end
