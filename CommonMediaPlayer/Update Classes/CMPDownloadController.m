/*
 * CMPDownloadController.m
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 25 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */


#import "CMPDownloadController.h"
#import "CMPProgressBarControl.h"
#import "BackRowUtils.h"
#import <BackRow/BackRow.h>
#import "CMPInstaller.h"

#define myDomain			(CFStringRef)@"??"

static NSString * const kDefaultURLString = @"nada";

@implementation CMPDownloadController

+ (void) clearAllDownloadCaches
{
    [[NSFileManager defaultManager] removeFileAtPath: [self downloadCachePath]
                                             handler: nil];
}

+ (NSString *) downloadCachePath
{
    static NSString * __cachePath = nil;

    if ( __cachePath == nil )
    {
        // find the user's Caches folder
        NSArray * list = NSSearchPathForDirectoriesInDomains( NSCachesDirectory,
            NSUserDomainMask, YES );

        // handle any failures in that API
        if ( (list != nil) && ([list count] != 0) )
            __cachePath = [list objectAtIndex: 0];
        else
            __cachePath = NSTemporaryDirectory( );

        __cachePath = [[__cachePath stringByAppendingPathComponent: @"CMPDownloads"] retain];

        // ensure this exists
        [[NSFileManager defaultManager] createDirectoryAtPath: __cachePath
                                                   attributes: nil];
    }

    return ( __cachePath );
}

+ (NSString *) outputPathForURLString: (NSString *) urlstr
{
    NSString * cache = [self downloadCachePath];
    NSString * name = [urlstr lastPathComponent];

    // trim any parameters from the URL
    NSRange range = [name rangeOfString: @"?"];
    if ( range.location != NSNotFound )
        name = [name substringToIndex: range.location];

    NSString * folder = [[name stringByDeletingPathExtension]
                         stringByAppendingPathExtension: @"download"];

    return ( [NSString pathWithComponents: [NSArray arrayWithObjects: cache,
        folder, name, nil]] );
}


/* 
 
 these checks are required here too because of the paragraph theme being taken out of 3.0 appletv and if i linked to the 
 CMPATVVersion in here nitoTV craps out with some variables i must've reused between the framework and nitoTV, its all moot
 anyways because this class is largely useless till i can fashion a working brcontroller.
 
 */

+ (BOOL)threePointZeroOrGreater
{
	
	NSComparisonResult theResult = [@"3.0" compare:[CMPDownloadController atvVersion] options:NSNumericSearch];
	if ( theResult == NSOrderedDescending ){
		return NO;
	} else if ( theResult == NSOrderedAscending ){
		return YES;
	} else if ( theResult == NSOrderedSame ) {
		return YES;
	}
	return NO;
}

+ (NSString *)atvVersion
{
	NSDictionary *finderDict = [[NSBundle mainBundle] infoDictionary];
	NSString *theVersion = [finderDict objectForKey: @"CFBundleVersion"];
	return theVersion;
}

- (void) drawSelf

{

	NSString *urlstr = _downloadURL;
	
	_header = [[BRHeaderControl alloc] init];
	_sourceText = [[BRTextControl alloc] init];
	_progressBar = [[CMPProgressBarControl alloc] init];
	
	// work out our desired output path
	_outputPath = [[CMPDownloadController outputPathForURLString: urlstr] retain];
	
	// lay out our UI
	NSRect masterFrame = [[self parent] frame];
	NSRect frame = masterFrame;
	
	// header goes in a specific location
	frame.origin.y = frame.size.height * 0.82f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[_header setFrame: frame];
	
	// progress bar goes in a specific place too (one-eighth of the way
	// up the screen)
	frame.size.width = masterFrame.size.width * 0.45f;
	frame.size.height = ceilf( frame.size.width * 0.068f );
	frame.origin.x = (masterFrame.size.width - frame.size.width) * 0.5f;
	frame.origin.y = masterFrame.origin.y + (masterFrame.size.height * (1.0f / 8.0f));
	[_progressBar setFrame: frame];
	
	NSString *title = [NSString stringWithFormat:BRLocalizedString(@"Downloading %@ %@", @"Downloading %@ %@"), _downloadTitle, _downloadVersion];
	
	[self setTitle: title];
	[self setSourceText: urlstr];   // this lays itself out
	[_progressBar setCurrentValue: [_progressBar minValue]];
	
	// add the controls
	[self addControl: _header];
	[self addControl: _sourceText];
	[self addControl: _progressBar];
	
	
}



- (id) initWithSettings:(NSDictionary *)settingsDict {
	
    if ( [super init] == nil )
        return ( nil );

	_downloadTitle = [settingsDict valueForKey:@"name"];
	_downloadVersion = [settingsDict valueForKey:@"version"];
	_downloadVersion = [settingsDict valueForKey:@"url"];
	
	[_downloadTitle retain];
	[_downloadVersion retain];
	[_downloadVersion retain];
	
	
    return ( self );
}

- (void) dealloc
{
    [self cancelDownload];

    [_header release];
    [_sourceText release];
    [_progressBar release];
    [_downloader release];
    [_outputPath release];

    [super dealloc];
}

- (BOOL) beginDownload
{
    if ( _downloader != nil )
        return ( NO );

    // see if we can resume from the current data
    if ( [self resumeDownload] == YES )
        return ( YES );

    // didn't work, delete & try again
    [self deleteDownload];

	
	NSString *urlstr = _downloadURL;

    NSURL * url = [NSURL URLWithString: urlstr];
    if ( url == nil )
        return ( NO );

    NSURLRequest * req = [NSURLRequest requestWithURL: url
                                          cachePolicy: NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval: 20.0];

    // create the dowloader
    _downloader = [[NSURLDownload alloc] initWithRequest: req delegate: self];
    if ( _downloader == nil )
        return ( NO );

    [_downloader setDeletesFileUponFailure: NO];

    return ( YES );
}

- (BOOL) resumeDownload
{
    if ( _outputPath == nil )
        return ( NO );

    NSString * resumeDataPath = [[_outputPath stringByDeletingLastPathComponent]
                                 stringByAppendingPathComponent: @"ResumeData"];
    if ( [[NSFileManager defaultManager] fileExistsAtPath: resumeDataPath] == NO )
        return ( NO );

    NSData * resumeData = [NSData dataWithContentsOfFile: resumeDataPath];
    if ( (resumeData == nil) || ([resumeData length] == 0) )
        return ( NO );

    // try to initialize using the saved data...
    _downloader = [[NSURLDownload alloc] initWithResumeData: resumeData
                                                   delegate: self
                                                       path: _outputPath];
    if ( _downloader == nil )
        return ( NO );

    [_downloader setDeletesFileUponFailure: NO];

    return ( YES );
}

- (void) cancelDownload
{
    [_downloader cancel];
    [self storeResumeData];
}

- (void) deleteDownload
{
    if ( _outputPath == nil )
        return;

    [[NSFileManager defaultManager] removeFileAtPath:
        [_outputPath stringByDeletingLastPathComponent]
                                             handler: nil];
}

// stack callbacks
- (void)controlWasActivated;
{
	[self drawSelf];
	
    if ( [self beginDownload] == NO )
    {
        [self setTitle: @"Download Failed"];
        [_progressBar setPercentage: 0.0f];
        ////[[self scene] renderScene];
    }
	
    [super controlWasActivated];
}

- (void)controlWillDeactivate;
{
    [self cancelDownload];
    [super controlWillDeactivate];
}

- (BOOL) isNetworkDependent
{
    return ( YES );
}

- (void) setTitle: (NSString *) title
{
    [_header setTitle: title];
}

- (NSString *) title
{
    return ( [_header title] );
}
- (void) setSourceText: (NSString *) srcText
{
	
    [_sourceText setText: srcText withAttributes:[[BRThemeInfo sharedTheme] CMPParagraphTextAttributes]];
	
    // layout this item
    NSRect masterFrame = [self frame];
	
	
    NSSize txtSize = [_sourceText renderedSize];
	
    NSRect frame;
    frame.origin.x = (masterFrame.size.width - txtSize.width) * 0.5f;
    frame.origin.y = (masterFrame.size.height * 0.75f) - txtSize.height;
    frame.size = txtSize;
    
	[_sourceText setFrame: frame];
}

- (NSString *) sourceText
{
    return ( [_sourceText text] );
}

- (float) percentDownloaded
{
    return ( [_progressBar percentage] );
}

- (void) storeResumeData
{
    NSData * data = [_downloader resumeData];
    if ( data != nil )
    {
            // store this in the .download folder
        NSString * path = [[_outputPath stringByDeletingLastPathComponent]
                           stringByAppendingPathComponent: @"ResumeData"];
        [data writeToFile: path atomically: YES];
    }
}

// NSURLDownload delegate methods
- (void) download: (NSURLDownload *) download
   decideDestinationWithSuggestedFilename: (NSString *) filename
{
    // we'll ignore the given filename and use our own
    // they'll likely be the same, anyway

    // ensure that all new path components exist
    [[NSFileManager defaultManager] createDirectoryAtPath: [_outputPath stringByDeletingLastPathComponent]
                                               attributes: nil];

    NSLog( @"Starting download to file '%@'", _outputPath );

    [download setDestination: _outputPath allowOverwrite: YES];
}

- (void) download: (NSURLDownload *) download didFailWithError: (NSError *) error
{
    [self storeResumeData];

    NSLog( @"Download encountered error '%d' (%@)", [error code],
           [error localizedDescription] );

    // show an alert for the returned error (hopefully it has nice
    // localized reasons & such...)
    BRAlertController * obj = [BRAlertController alertForError: error
                                                     withScene: [self scene]];
    [[self stack] swapController: obj];
}

- (void) download: (NSURLDownload *) download didReceiveDataOfLength: (unsigned) length
{
    _gotLength += (long long) length;
    float percentage = 0.0f;

    //NSLog( @"Got %u bytes, %lld total", length, _gotLength );

    // we'll handle the case where the NSURLResponse didn't include the
    // size of the source file
    if ( _totalLength == 0 )
    {
        // bump up the max value a bit
        percentage = [_progressBar percentage];
        if ( percentage >= 95.0f )
            [_progressBar setMaxValue: [_progressBar maxValue] + (float) (length << 3)];
    }

    [_progressBar setCurrentValue: _gotLength];
}

- (void) download: (NSURLDownload *) download didReceiveResponse: (NSURLResponse *) response
{
    // we might receive more than one of these (if we get redirects,
    // for example)
    _totalLength = 0;
    _gotLength = 0;

    NSLog( @"Got response for new download, length = %lld", [response expectedContentLength] );

    if ( [response expectedContentLength] != NSURLResponseUnknownLength )
    {
        _totalLength = [response expectedContentLength];
        [_progressBar setMaxValue: (float) _totalLength];
    }
    else
    {
        // an arbitrary number -- one megabyte
        [_progressBar setMaxValue: 1024.0f * 1024.0f];
    }
}

- (BOOL) download: (NSURLDownload *) download
   shouldDecodeSourceDataOfMIMEType: (NSString *) encodingType
{
    NSLog( @"Asked to decode data of MIME type '%@'", encodingType );

    // we'll allow decoding only if it won't interfere with resumption
    if ( [encodingType isEqualToString: @"application/gzip"] )
        return ( NO );

    return ( YES );
}

- (void) download: (NSURLDownload *) download
   willResumeWithResponse: (NSURLResponse *) response
                 fromByte: (long long) startingByte
{
    // resuming now, so pretty much as above, except we have a starting
    // value to set on the progress bar
    _totalLength = 0;
    _gotLength = (long long) startingByte;

    // the total here seems to be the amount *remaining*, not the
    // complete total

    NSLog( @"Resumed download at byte %lld, remaining is %lld",
           _gotLength, [response expectedContentLength] );

    if ( [response expectedContentLength] != NSURLResponseUnknownLength )
    {
        _totalLength = _gotLength + [response expectedContentLength];
        [_progressBar setMaxValue: (float) _totalLength];
    }
    else
    {
        // an arbitrary number
        [_progressBar setMaxValue: (float) (_gotLength << 1)];
    }

    // reset current value as appropriate
    [_progressBar setCurrentValue: (float) _gotLength];
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
    // completed the download: set progress full (just in case) and
    // go do something with the data
    [_progressBar setPercentage: 100.0f];

    NSLog( @"Download finished" );

    // we'll swap ourselves off the stack here, so let's remove our
    // reference to the downloader, just in case calling -cancel now
    // might cause a problem
    [_downloader autorelease];
    _downloader = nil;

	[self installUpdate:_outputPath];
	
    //NSURL * url = [NSURL fileURLWithPath: _outputPath];
	
	//do stuff with output here
	
}

- (void)installer:(id <CMPInstaller>)installer didEndWithSettings:(NSDictionary *)settings
{
	[installer autorelease];
	
	[self setTitle:[settings valueForKey:@"title"]];
	[self setSourceText:[settings valueForKey:@"sourceText"]];
	[self performAction:[settings valueForKey:@"action"]];
	
}

- (void)performAction:(NSString *)theAction
{
	if ([theAction isEqualToString:@"popTop"])
		[self popTop];
	else if([theAction isEqualToString:@"killFinder"])
		[CMPInstaller killFinder];
}

- (void)popTop
{
	[[self stack] popController];
}

- (void)installUpdate:(NSString *)outputPath
{
	
	CMPInstaller *cmpInstaller = [[CMPInstaller alloc] initWithUpdate:outputPath];
	[cmpInstaller setDelegate:self];
	[cmpInstaller performUpdate];
	
	
}


@end

@implementation BRThemeInfo (SpecialAdditions)

- (id)CMPParagraphTextAttributes
{
	NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
	
	BRThemeInfo *theInfo = [[BRThemeInfo sharedTheme] settingsItemSmallTextAttributes];
	id colorObject = [theInfo valueForKey:@"NSColor"];
	[myDict setValue:[NSNumber numberWithInt:21] forKey:@"BRFontLines"];
	[myDict setValue:[NSNumber numberWithInt:0] forKey:@"BRTextAlignmentKey"];
	
	if ([CMPDownloadController threePointZeroOrGreater])
	{
		
		
		id sizeObject = [theInfo valueForKey:@"BRFontPointSize"];
		id fontObject = [theInfo valueForKey:@"BRFontName"];
		[myDict setValue:sizeObject forKey:@"BRFontPointSize"];
		[myDict setValue:fontObject forKey:@"BRFontName"];
		
	} else {
		[myDict setValue:@"LucidaGrande-Bold" forKey:@"BRFontName"];
	}
	
	[myDict setValue:colorObject forKey:@"NSColor"];
	
	
	return [myDict autorelease];
}

@end