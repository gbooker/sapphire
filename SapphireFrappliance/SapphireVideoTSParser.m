/*
 * SapphireVideoTSParser.m
 * Sapphire
 *
 * Created by Warren Gavin on May. 7, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireVideoTsParser.h"

// These methods are not part of the public interface for the parser.
// Instead of declaring them in the header, we declare them here in a category that extends the class.

@interface SapphireVideoTsParser (InternalMethods)

/*!
 * @brief Open the main featre IFO at a given location
 */
-(BOOL) openIfoAt:(const NSString * const) path;

/*!
 * @brief read the video attributes for a ripped DVD
 */
-(void) parseVideo;

/*!
 * @brief read the audio attributes for a ripped DVD
 */
-(void) parseAudio;

/*!
 * @brief read the subtitle details for a ripped DVD
 */
-(void) parseSubtitles;

/*!
 * @brief read the playback time for a ripped DVD
 */
-(void) parseDuration;

@end

////////////////////////////////////////////////////////////////////////////////
// Standard values in DVD IFO files
static const unsigned int VtsOffset_PGCI             = 0x0cc;
static const unsigned int VtsOffset_VideoAttrs       = 0x200;
static const unsigned int VtsOffset_NumAudio         = 0x202;
static const unsigned int VtsOffset_AudioAttrs       = 0x204;
static const unsigned int VtsOffset_NumSubpictures   = 0x254;
static const unsigned int VtsOffset_SubpictureAttrs  = 0x256;

static const unsigned int VtsAttrSize_Video          = 2;
static const unsigned int VtsAttrSize_Audio          = 8;
static const unsigned int VtsAttrSize_Subpictures    = 6;

static const unsigned int VtsMax_Audio               = 8;
static const unsigned int VtsMax_Subpictures         = 32;

////////////////////////////////////////////////////////////////////////////////
// Macros for various attributes
#define vts_VideoCodingMode(attrs)                   ((attrs[0] & 0xc0) >> 6) + 1
#define vts_VideoIsPAL(attrs)                        ( attrs[0] & 0x30)
#define vts_VideoResolution(attrs)                   ( attrs[1] & 0x38)
#define vts_VideoIsWidescreen(attrs)                 ( attrs[0] & 0x0c)

#define vts_AudioIsDTS(attrs)                        ((attrs[0] & 0xe0) == 0x0c)
#define vts_AudioIsSurround(attrs)                   ( attrs[0] & 0x02)
#define vts_AudioIsCommentary(attrs)                 ( attrs[5] >    1)
#define vts_AudioSupportsDolbyDecoding(attrs)        ( attrs[7] & 0x80)

#define vts_SubpictureIsSubtitle(attrs)              ( attrs[0] & 0x01)

#define vts_CommonFirstLanguageCode(attrs)           ( attrs[2] )
#define vts_CommonSecondLanguageCode(attrs)          ( attrs[3] )

#define vts_CommonReadAtOffset(off, dst)             do{ [ifo seekToFileOffset:off]; [[ifo readDataOfLength:sizeof dst] getBytes:&dst];                  } while(0)
#define vts_CommonReadAtOffsetConv(off, dst, conv)   do{ [ifo seekToFileOffset:off]; [[ifo readDataOfLength:sizeof dst] getBytes:&dst]; dst = conv(dst); } while(0)

////////////////////////////////////////////////////////////////////////////////
// local functions

/*!
 * @brief Given the two encoding characters of a language, get the display friendly version
 */
static const NSString *languageFromEncodedChars( const char firstChar, const char secondChar )
{
	static NSLocale *currentLocale = nil;
	const char       langCode[]    = { firstChar, secondChar, 0 };
	
	if( currentLocale == nil )
		currentLocale = [NSLocale currentLocale];

	return [currentLocale displayNameForKey:NSLocaleLanguageCode
									  value:[NSString stringWithCString:langCode encoding:NSASCIIStringEncoding]];
}

/*!
 * @brief Given a collection of strings create a comma separated string of it's elements
 */
static const NSString *commaSeparatedStringFromCollection( const NSSet * const set )
{
	if( [set count] == 0 )
		return nil;
	
	const NSEnumerator    * const enumerator = [set objectEnumerator];
	const NSMutableString * const str        = [NSMutableString stringWithString:[enumerator nextObject]];
	const NSString        *       element    = nil;
	
	while( element = [enumerator nextObject] )
		[str appendFormat:@", %@", element];
	
	return str;
}

/*!
 * @brief Convert a BCD encoded byte into an integer
 *
 * BCD encodes numbers in such a way that their hex values "look" like their decimal values
 * i.e. the decimal value 12 is encoded as 0x12 (decimal 18).
 *
 * This makes it easy to print the values straight from byte values (printf("Decimal number = %x", byte))
 * but gets in our way, hence the need to decode.
 */
static unsigned int bcdDecode( const unsigned char timeAsBCD )
{
	return ((timeAsBCD & 0xf0) >> 4) * 10 + (timeAsBCD & 0x0f);
}

////////////////////////////////////////////////////////////////////////////////
// SapphireVideoTsParser
////////////////////////////////////////////////////////////////////////////////

@implementation SapphireVideoTsParser

-(id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (id) initWithPath: (NSString *)path
{
	[self init];

	if( [self openIfoAt:path] )
	{
		[self parseVideo];
		[self parseAudio];
		[self parseSubtitles];
		[self parseDuration];
		
		[ifo closeFile];
	}
	
	return self;
}

-(BOOL) openIfoAt: (const NSString * const)path
{
	NSString            * const videotsPath = [path stringByAppendingPathComponent:@"VIDEO_TS"];
	const NSFileManager * const fm          = [NSFileManager defaultManager];
	const NSEnumerator  * const enumerator  = [[fm directoryContentsAtPath:videotsPath] objectEnumerator];
	
	NSString  *filePath    = nil;
	NSString  *ifoPath     = nil;

	unsigned long long ifoSz = 0;

	// The largest IFO file (not including VIDEO_TS.IFO) corresponds to the main feature
	while( filePath = [enumerator nextObject] )
	{
		if( [[filePath lowercaseString] hasSuffix:@".ifo"] && [[filePath lastPathComponent] caseInsensitiveCompare:@"video_ts.ifo"] != NSOrderedSame )
		{
			unsigned long long sz = [[[fm fileAttributesAtPath:[videotsPath stringByAppendingPathComponent:filePath] traverseLink:YES] valueForKey:NSFileSize] unsignedLongLongValue];

			if ( sz > ifoSz )
			{
				ifoPath = [videotsPath stringByAppendingPathComponent:filePath];
				ifoSz   = sz;
			}
		}
	}

	if( ifoPath != nil )
		ifo = [NSFileHandle fileHandleForReadingAtPath:ifoPath];

	return ifo != nil;
}

-(void) parseVideo
{
	unsigned char videoAttrs[VtsAttrSize_Video];
	vts_CommonReadAtOffset( VtsOffset_VideoAttrs, videoAttrs );

	const NSMutableString * const videoText = [NSMutableString stringWithFormat:@"MPEG-%d", vts_VideoCodingMode( videoAttrs ) ];

	if( vts_VideoIsPAL( videoAttrs ) )
	{
		[videoText appendString:@", PAL"];
		switch( vts_VideoResolution( videoAttrs ) )
		{
			case 0:
				[videoText appendString:@", 720x576"];
				break;
			case 0x08:
				[videoText appendString:@", 704x576"];
				break;
			case 0x10:
				[videoText appendString:@", 352x576"];
				break;
			case 0x18:
				[videoText appendString:@", 352x288"];
				break;
			default:
				break;
		}
	}
	else
	{
		[videoText appendString:@", NTSC"];
		switch( vts_VideoResolution( videoAttrs ) )
		{
			case 0:
				[videoText appendString:@", 720x480"];
				break;
			case 0x08:
				[videoText appendString:@", 704x480"];
				break;
			case 0x10:
				[videoText appendString:@", 352x480"];
				break;
			case 0x18:
				[videoText appendString:@", 352x240"];
				break;
			default:
				break;
		}
	}

	if( vts_VideoIsWidescreen( videoAttrs ) )
		[videoText appendString:@" (16:9)"];
	else
		[videoText appendString:@" (4:3)"];

	video = videoText;
}

-(void) parseAudio
{
	unsigned short numAudio = 0;
	vts_CommonReadAtOffsetConv( VtsOffset_NumAudio, numAudio, EndianU16_BtoN );

	if( numAudio > 0 )
	{
		if( numAudio > VtsMax_Audio )
			numAudio = VtsMax_Audio;

		// Go through the different audio streams create a string of the form
		// 'English DTS, French, ...'
		unsigned char audioAttrs[VtsMax_Audio][VtsAttrSize_Audio];
		vts_CommonReadAtOffset( VtsOffset_AudioAttrs, audioAttrs );

		const NSMutableSet * const audioList = [NSMutableSet setWithCapacity:VtsMax_Audio];
		unsigned int idx;

		for( idx = 0; idx < numAudio; ++idx )
		{
			// Skip audio marked as'directors comments' etc, otherwise we're likely to end up
			// an audion description like "English Surround, French, English, English", which is silly
			if( vts_AudioIsCommentary( audioAttrs[idx] ) )
				continue;

			const NSMutableString * const audioText = [NSMutableString stringWithString:(NSString *)languageFromEncodedChars(vts_CommonFirstLanguageCode ( audioAttrs[idx] ),
																															 vts_CommonSecondLanguageCode( audioAttrs[idx] ) )];
			if( vts_AudioIsDTS( audioAttrs[idx] ) )
				[audioText appendString:@" - DTS"];

			if( vts_AudioIsSurround( audioAttrs[idx] ) )
			{
				if ( vts_AudioSupportsDolbyDecoding( audioAttrs[idx] ) )
					[audioText appendString:@"  Dolby Surround"];
				else
					[audioText appendString:@" Surround"];                
			}

			[audioList addObject:audioText];
		}

		audio = commaSeparatedStringFromCollection( audioList );
	}

	if( audio == nil )
		audio = @"Not specified";
}

-(void) parseSubtitles
{
	unsigned short numSubpictures = 0;
	vts_CommonReadAtOffsetConv( VtsOffset_NumSubpictures, numSubpictures, EndianU16_BtoN );

	if( numSubpictures > 0 )
	{
		if( numSubpictures > VtsMax_Subpictures )
			numSubpictures = VtsMax_Subpictures;

		unsigned char subpictureAttrs[VtsMax_Subpictures][VtsAttrSize_Subpictures];
		vts_CommonReadAtOffset( VtsOffset_SubpictureAttrs, subpictureAttrs );

		// Subtitles stored as a set, that way we only have one of each language
		// in our description string. Language duplicates are likely on DVD due to
		// commentaries and special subtitles for the hard of hearing, etc.
		const NSMutableSet * const subtitleList = [NSMutableSet setWithCapacity:VtsMax_Subpictures];
		unsigned int idx;
		for( idx = 0; idx < numSubpictures; ++idx )
		{
			if( vts_SubpictureIsSubtitle( subpictureAttrs[idx] ) )
				[subtitleList addObject:languageFromEncodedChars(vts_CommonFirstLanguageCode ( subpictureAttrs[idx] ),
																 vts_CommonSecondLanguageCode( subpictureAttrs[idx] ) )];
		}

		subtitles = commaSeparatedStringFromCollection( subtitleList );
	}

	if( subtitles == nil )
		subtitles = @"None";
}

-(void) parseDuration
{
	duration = 0;

	// DVD sub-feature duration is stored as part of the Program Chain (PGC)
	//
	// Multiple PGC's may exist, their information is stored in the program chain information (PGCI)
	// The PGCI is located at a sector specified by the PGCI sector pointer at offset 0xCC in the IFO
	// file.
	unsigned int pgci = 0;
	vts_CommonReadAtOffsetConv( VtsOffset_PGCI, pgci, EndianU32_BtoN );

	// Sector pointers are integers that must be multiplied by the sector size to get the correct
	// address. The DVD sector size is 2048, so multiplication is the same as left-shifting by 11
	pgci <<= 11;

	// PGCI has been converted into the sector address of the PGCI
	// The first two bytes specify the number of PGCs on the DVD (Big endian)
	unsigned short numPGC = 0;
	vts_CommonReadAtOffsetConv( pgci, numPGC, EndianU16_BtoN );

	if( numPGC > 0 )
	{
		// The offset to the first PGC is located 12 bytes past the address of the PGCI
		// this offset is relative to the PGCI 
		unsigned int pgc = 0;
		vts_CommonReadAtOffsetConv( pgci + 12, pgc, EndianU32_BtoN );

		// Duration is stored in three bytes at an offset of 4 bytes from the start of the pcg
		//
		// BCD format means the time is stored in nibbles hh:mm:ss
		unsigned char bcd[3];
		vts_CommonReadAtOffset( pgci + pgc + 4, bcd );

		// Time is stored in BCD format, decode to get hour:min:sec
		duration = bcdDecode( bcd[0] ) * 3600 + bcdDecode( bcd[1] ) * 60 + bcdDecode( bcd[2] );
	}
}

////////////////////////////////////////////////////////////////////////////////

- (const NSString * const) videoFormatsString
{
	return video;
}

- (const NSString * const) audioFormatsString
{
	return audio;
}

- (const NSString * const) subtitlesString
{
	return subtitles;
}

- (const NSNumber * const) mainFeatureDuration
{
	return [NSNumber numberWithLongLong:duration];
}

@end
