//
//	QTMovieParser.m
//	QT7MiniDemo
//
//	Created by Thomas Cool on 7/19/10.
//	Copyright 2010 tomcool.org. All rights reserved.
//
#import "SapphireQTMovieParser.h"
#import <QuickTime/Movies.h>

enum {
	kMyQTMetaDataTypeGIF = 12,
};

NSString *TC_QT_TITLE			= @"Title";
NSString *TC_QT_LONG_DESC		= @"Long Description";
NSString *TC_QT_DESC			= @"Description";
NSString *TC_QT_RELEASE			= @"Release Date";
NSString *TC_QT_COPYRIGHT		= @"Copyright";
NSString *TC_QT_GENRES			= @"Genres";
NSString *TC_QT_TRACK			= @"Track";
NSString *TC_QT_DIRECTORS		= @"Directors";
NSString *TC_QT_ARTISTS			= @"Artists";
NSString *TC_QT_TYPE			= @"Type";

NSString *TC_QT_TV_SHOW			= @"TV Show";
NSString *TC_QT_TV_SEASON_NB	= @"TV Season #";
NSString *TC_QT_TV_EPISODE_NB	= @"TV Episode #";
NSString *TC_QT_TV_EP_ID		= @"TV Episode ID";
NSString *TC_QT_TV_NETWORK		= @"TV Network";

#pragma mark String Utils Declarations

/*
 *	Functions
 */

#pragma mark String Extraction Functions
static inline CFStringRef CreateStringFromUTF8Data(QTPropertyValuePtr keyValuePtr, ByteCount propValueSizeUsed)
{
	return(CFStringCreateWithFormat(NULL, NULL, CFSTR("%.*s"), propValueSizeUsed, keyValuePtr));
}

static inline CFStringRef CreateStringFromPropertyValue(QTPropertyValuePtr keyValuePtr, ByteCount propValueSize)
{
	return(CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%.*s "), propValueSize, keyValuePtr));
}

static inline CFStringRef CreateStringFromUTF16BEData(QTPropertyValuePtr keyValuePtr, ByteCount propValueSizeUsed)
{
	return (CFStringCreateWithBytes(NULL, keyValuePtr, propValueSizeUsed, kCFStringEncodingUTF16BE, false));
}

#pragma mark Number Extraction Functions
static CFStringRef CreateStringFromSignedIntegerBEData(QTPropertyValuePtr keyValuePtr, ByteCount propValueSizeUsed)
{
	require (propValueSizeUsed != 0, NULLVALUEPTR);
	
	SInt32 *keyValAsInt = (SInt32 *)keyValuePtr;
	//NSLog(@"val: %i",*keyValAsInt);
	return (CFStringCreateWithFormat(NULL, NULL, CFSTR("%#.*x"), propValueSizeUsed, *keyValAsInt));
NULLVALUEPTR:
	return nil;
}

static CFStringRef CreateStringFromUnsignedIntegerBEData(QTPropertyValuePtr keyValuePtr, ByteCount propValueSizeUsed)
{
	require (propValueSizeUsed != 0, NULLVALUEPTR);

	SInt32 *keyValAsInt = (SInt32 *)keyValuePtr;
	//NSLog(@"val: %i",*keyValAsInt);
	return (CFStringCreateWithFormat(NULL, NULL, CFSTR("%i"), propValueSizeUsed, *keyValAsInt));
NULLVALUEPTR:
	return nil;
}

static CFStringRef CreateStringFromFloat32BEData(QTPropertyValuePtr keyValuePtr)
{
	Float32 *keyValAsFloat = (Float32 *)keyValuePtr;
	
	return (CFStringCreateWithFormat(NULL, NULL, CFSTR("%f"), *keyValAsFloat));
}

static CFStringRef CreateStringFromFloat64BEData(QTPropertyValuePtr keyValuePtr)
{
	Float32 *keyValAsFloat = (Float32 *)keyValuePtr;
	
	return (CFStringCreateWithFormat(NULL, NULL, CFSTR("%f"), *keyValAsFloat));
}

#pragma mark Extraction Function
static NSString *GetStringForMetaDataValue(UInt32 dataTypeCode, QTPropertyValuePtr keyValuePtr, ByteCount propValueSizeUsed)
{
	CFStringRef	str = nil;

	switch (dataTypeCode)
	{
		case kMyQTMetaDataTypeGIF:
		case kQTMetaDataTypeJPEGImage:
		case kQTMetaDataTypePNGImage:
		case kQTMetaDataTypeBMPImage:
		case kQTMetaDataTypeBinary:
			str=CFSTR("");
			break;

		case kQTMetaDataTypeUTF8:
			str = CreateStringFromUTF8Data(keyValuePtr, propValueSizeUsed);
			break;

		case kQTMetaDataTypeUTF16BE:
			str = CreateStringFromUTF16BEData(keyValuePtr, propValueSizeUsed);
			break;

		case kQTMetaDataTypeMacEncodedText:
			str = CreateStringFromPropertyValue(keyValuePtr, propValueSizeUsed);
			break;

		case kQTMetaDataTypeSignedIntegerBE:
			str = CreateStringFromSignedIntegerBEData(keyValuePtr, propValueSizeUsed);
			break;

		case kQTMetaDataTypeUnsignedIntegerBE:
			str = CreateStringFromUnsignedIntegerBEData(keyValuePtr, propValueSizeUsed);
			break;

		case kQTMetaDataTypeFloat32BE:
			str = CreateStringFromFloat32BEData(keyValuePtr);			
			break;

		case kQTMetaDataTypeFloat64BE:
			str = CreateStringFromFloat64BEData(keyValuePtr);						
			break;
	}

	// create a properly formatted string showing a count of the number of bytes of data
	// for display in our window and append the actual metadata value string to this display string
	//CFStringRef destStr = AppendMetaValueStringToDisplayString(str, propValueSizeUsed);

	return [(NSString *)str autorelease];
}

static int GetNumberForMetaDataValue(QTPropertyValuePtr propValuePtr, ByteCount propValueSize)
{
	int result = 0;
	if(propValueSize == 1) 
		result = *((char *)propValuePtr);
	else if(propValueSize == 2) 
		result = EndianS16_BtoN(*((short *)propValuePtr));
	else if(propValueSize == 4) 
		result = EndianS32_BtoN(*((int *)propValuePtr));
	
	return result;
}

#pragma mark LoadQTMetaData

static OSStatus TCUtils_GetItemPropertyValue(QTMetaDataRef metaDataRef, QTMetaDataItem item, QTPropertyClass inPropClass, QTPropertyID inPropID, QTPropertyValuePtr *outValPtr, ByteCount *outPropValueSizeUsed)
{
	QTPropertyValueType outPropType;
	ByteCount			outPropValueSize;
	UInt32				outPropFlags;

	*outValPtr = NULL;
	*outPropValueSizeUsed = 0;
	// first get the size of the property
	OSStatus status = QTMetaDataGetItemPropertyInfo(metaDataRef, item, inPropClass, inPropID, &outPropType, &outPropValueSize, &outPropFlags);
	if(status != noErr)
		return status;

	// allocate memory to hold the property value
	*outValPtr = malloc(outPropValueSize);
	
	// Return the property of the metadata item.
	status = QTMetaDataGetItemProperty(metaDataRef, item, inPropClass, inPropID, outPropValueSize, *outValPtr, outPropValueSizeUsed);
	
	// QTMetaDataKeyFormat types will be native endian in our byte buffer, we need
	// big endian so they look correct when we create a string. 
	if (outPropType == 'code' || outPropType == 'itsk' || outPropType == 'itlk') {
		OSTypePtr pType = (OSTypePtr)*outValPtr;
		*pType = EndianU32_NtoB(*pType);
	}

	return status;
}

static NSString * stringForKey(NSString *key)
{
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
						TC_QT_TITLE,			@"©nam",
						TC_QT_ARTISTS,			@"©ART",
						TC_QT_GENRES,			@"©gen",
						TC_QT_GENRES,			@"gnre",
						@"Album",				@"©alb",
						TC_QT_COPYRIGHT,		@"cprt",
						TC_QT_TRACK,			@"trkn",
						@"Disk #",				@"disk",
						TC_QT_RELEASE,			@"©day",
						TC_QT_DESC,				@"desc",
						TC_QT_LONG_DESC,		@"ldes",
						@"HD",					@"hdvd",
						@"Cover",				@"covr",
						TC_QT_TV_EP_ID,			@"tven",
						TC_QT_TV_SEASON_NB,		@"tvsn",
						TC_QT_TV_EPISODE_NB,	@"tves",
						TC_QT_TV_SHOW,			@"tvsh",
						TC_QT_TV_NETWORK,		@"tvnn",
						@"Play Gap",			@"pgap",
						TC_QT_TYPE,				@"stik",
						//@"User Rating",@"rtng", -- Clean - Explicit
						nil];
	
	NSString *r = [d objectForKey:key];
	if(r == nil) 
		return key;
	return r;
}

#pragma mark -
#pragma mark ObjC
@interface SapphireQTMovieParser ()
- (void)parseFile:(NSString *)file;
@end

@implementation SapphireQTMovieParser

- (id)initWithFile:(NSString *)file
{
	if(![[NSFileManager defaultManager] fileExistsAtPath:file])
		return nil;

	self=[super init];
	if(self)
		[self parseFile:file];

	return self;
}

- (NSMutableDictionary *)info
{
	return info;
}

- (NSData *)imageData
{
	return imageData;
}

- (NSString *)imageExtension
{
	return imageExtension;
}

- (void)parseFile:(NSString *)file
{
	info = [[NSMutableDictionary alloc] init];
	[info setObject:file forKey:@"Path"];
	NSError *openError;
//	NSArray* valueTypeDescriptions =
//		[NSArray arrayWithObjects: @"Binary", @"UTF-8", @"UTF-16BE", @"Mac-Encoded Text",
//			@"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", // 4-10 undefined
//			@"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", @"undefined", // 11-20 undefined
//			@"Signed Integer (Big-Endian)",
//			@"Unsigned Integer (Big-Endian)",
//			@"32-bit Float (Big-Endian)",
//			@"64-bit Float (Big-Endian)",
//			nil];

	qtMovie = [QTMovie movieWithURL:[NSURL fileURLWithPath:file] error:&openError];
	if(qtMovie == nil)
		return;
	
//	if (openError != nil) {
//		printf ("Error!\n");
//		NSLog(@"ERR: %@", openError);
//		NSString* desc = [openError localizedDescription];
//		printf ("%s\n", [desc UTF8String]);
//		return;
//	}
	Movie movie;
	movie = [qtMovie quickTimeMovie];

//	OSErr err = noErr;
//	Handle dataRef = nil;
//	OSType dataRefType;
//	Movie qtm = NULL;
//
//	err = QTNewDataReferenceFromFullPathCFString((CFStringRef)[[NSURL fileURLWithPath:file] path], kQTNativeDefaultPathStyle, 0, &dataRef, &dataRefType);
//	err= NewMovieFromDataRef(&qtm, newMovieIdleImportOK+newMovieAsyncOK, NULL, dataRef, dataRefType);

	QTMetaDataRef movieMetaData = malloc(sizeof(QTMetaDataRef)); 
	QTCopyMovieMetaData(movie, &movieMetaData); 
	QTMetaDataItem item = kQTMetaDataItemUninitialized;

	while(noErr == QTMetaDataGetNextItem(movieMetaData, kQTMetaDataStorageFormatWildcard, item, kQTMetaDataKeyFormatCommon, nil, 0, &item))
	{
		QTPropertyValuePtr	propValuePtr			= NULL;
		ByteCount			outPropValueSizeUsed	= 0;
		/*
		 *	Load the MetaData Key
		 */
		OSStatus status = TCUtils_GetItemPropertyValue(movieMetaData, item, kPropertyClass_MetaDataItem /*Metadata Item Property Class ID*/, kQTMetaDataItemPropertyID_Key /* Metadata Item Property ID*/, &propValuePtr, &outPropValueSizeUsed);
		if(status != noErr)
			goto propertyError;

		/*
		 *	Convert to Human Readable String
		 */
		NSString *key = GetStringForMetaDataValue(kQTMetaDataTypeMacEncodedText, propValuePtr, outPropValueSizeUsed);
		if([key length]>1) {
			key = [key substringToIndex:([key length]-1)];
		}
		NSString *keyString = stringForKey(key);
		
		free(propValuePtr);
		propValuePtr = NULL;
		
		/*
		 *	Get Metadata
		 */
		QTPropertyValuePtr	dataTypeValuePtr = NULL;
		ByteCount			ignore = 0;
		status = TCUtils_GetItemPropertyValue(movieMetaData, item, kPropertyClass_MetaDataItem /*Metadata Item Property Class ID*/, kQTMetaDataItemPropertyID_Value /*Metadata Item Property ID*/, &propValuePtr, &outPropValueSizeUsed);
		if(status != noErr)
			goto propertyError;

		/*
		 *	Get Metadata Format
		 */
		status = TCUtils_GetItemPropertyValue(movieMetaData, item, kPropertyClass_MetaDataItem, kQTMetaDataItemPropertyID_DataType, &dataTypeValuePtr, &ignore);
		if(status != noErr)
			goto dataValueError;
		
		UInt32 *dataTypePtr = (UInt32 *)dataTypeValuePtr;
		UInt32 dataType = *dataTypePtr;
		//NSLog(@"key: %@, Key: %@, Format: %@",key, keyString,[valueTypeDescriptions objectAtIndex:*dataType]);
		/*
		 *	Check For Cover
		 */

		if([key isEqualToString:@"trkn"] || [key isEqualToString:@"disk"])
		{
			unsigned result1 = GetNumberForMetaDataValue(propValuePtr, 4);
			unsigned result2 = GetNumberForMetaDataValue(propValuePtr + 4, 4);
			[info setObject:[NSArray arrayWithObjects:
							 [NSNumber numberWithInt:result1],
							 [NSNumber numberWithInt:result2],
							 nil]
					 forKey:keyString];
			//NSLog(@"data: %@ outPut: %@ output2: %@ %i %i",data,outPut,outPut2,NSSwapBigIntToHost(result),NSSwapBigIntToHost(result2));
			//[data release];
		}
		if([keyString isEqualToString:@"Cover"])
		{
			imageData = [[NSData alloc] initWithBytes:propValuePtr length:outPropValueSizeUsed];
			switch (dataType) {
				case kMyQTMetaDataTypeGIF:
					imageExtension = @"gif";
					break;
				case kQTMetaDataTypeJPEGImage:
					imageExtension = @"jpg";
					break;
				case kQTMetaDataTypePNGImage:
					imageExtension = @"png";
					break;
				case kQTMetaDataTypeBMPImage:					
					imageExtension = @"bmp";
					break;
				default:
					break;
			}
		}
		/*
		 *	Check For String
		 */
		else if(dataType == kQTMetaDataTypeUTF8 ||
				dataType == kQTMetaDataTypeUTF16BE ||
				dataType == kQTMetaDataTypeMacEncodedText)
		{
			NSString *valueString = [[NSString alloc] initWithBytes:propValuePtr length:outPropValueSizeUsed encoding:NSUTF8StringEncoding];
			if([keyString isEqualToString:@"com.apple.iTunes"] || [keyString isEqualToString:@"com.apple.iTunes "])
			{
				//NSDictionary *dict= [NSDictionary dictionaryWithContentsOfString
				NSData *plistData = [valueString dataUsingEncoding:NSUTF8StringEncoding];
				NSString *error = nil;
				NSPropertyListFormat format;
				NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
				if(!plist)
					[info setObject:valueString forKey:@"Rating"];
				else
					[info setObject:plist forKey:@"iTunes Meta"];
				[error release];
			}
			else
				[info setObject:valueString forKey:keyString];

			[valueString release];
		}
		/*
		 *	Check For Integers
		 */
		else if(dataType==kQTMetaDataTypeSignedIntegerBE ||
				dataType==kQTMetaDataTypeUnsignedIntegerBE)
		{
			int result = GetNumberForMetaDataValue(propValuePtr, outPropValueSizeUsed);
			[info setObject:[NSNumber numberWithInt:result] forKey:keyString];
		}
		
dataValueError:
		if(dataTypeValuePtr != NULL)
			free(dataTypeValuePtr);
propertyError:
		if(propValuePtr != NULL)
			free(propValuePtr);
	}
	QTMetaDataRelease (movieMetaData);
}

- (void)dealloc
{
	[imageData release];
	[info release];
	[super dealloc];
}

@end
