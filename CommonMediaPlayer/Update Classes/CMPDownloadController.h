/*
 * CMPDownloadController.h
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

#import <Foundation/Foundation.h>
#import <BackRow/BRControl.h>
#import "CMPPlayerController.h"

/*
#import <BackRow/BRControl.h>

@class BRControllerStack, NSMutableDictionary;

@interface BRController : BRControl
{
    NSMutableDictionary *_labels;
    BRControllerStack *_stack;
    BOOL _depthLimited;
}

+ (id)defaultActionForKey:(id)fp8;
+ (id)controllerWithContentControl:(id)fp8;
- (id)init;
- (void)dealloc;
- (id)description;
- (void)setStack:(id)fp8;
- (id)stack;
- (BOOL)firstResponder;
- (void)addLabel:(id)fp8;
- (void)removeLabel:(id)fp8;
- (BOOL)isLabelled:(id)fp8;
- (BOOL)isNetworkDependent;
- (BOOL)recreateOnReselect;
- (BOOL)popsOnBury;
- (void)setDepthLimited:(BOOL)fp8;
- (BOOL)depthLimited;

@end


 obviously not working :(
 
*/
@class BRHeaderControl, BRTextControl, CMPProgressBarControl;

@class BRControllerStack, NSMutableDictionary;




@interface CMPDownloadController : NSObject
{
	int		padding[16];
    BRHeaderControl *       _header;
    BRTextControl *         _sourceText;
    CMPProgressBarControl *  _progressBar;

    NSURLDownload *         _downloader;
    NSString *              _outputPath;
    long long               _totalLength;
    long long               _gotLength;
	
	NSString *				_downloadTitle;
	NSString *				_downloadVersion;
	NSString *				_downloadURL;
	
}
-(NSRect)frame;

+ (void) clearAllDownloadCaches;
+ (NSString *) downloadCachePath;
+ (NSString *) outputPathForURLString: (NSString *) urlstr;

- (id) initWithSettings:(NSDictionary *)settingsDict;
- (BOOL) beginDownload;
- (BOOL) resumeDownload;
- (void) cancelDownload;
- (void) deleteDownload;

- (BOOL) isNetworkDependent;

- (void) setTitle: (NSString *) title;
- (NSString *) title;

- (void) setSourceText: (NSString *) text;
- (NSString *) sourceText;

- (float) percentDownloaded;

- (void) storeResumeData;

- (void)popTop;
- (void)installUpdate:(NSString *)outputPath;

@end
