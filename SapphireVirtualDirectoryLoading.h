//
//  SapphireVirtualDirectoryLoading.h
//  Sapphire
//
//  Created by Graham Booker on 11/27/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTextWithSpinnerController.h"

@class SapphireVirtualDirectory, SapphireBrowser;

@interface SapphireVirtualDirectoryLoading : SapphireTextWithSpinnerController {
	NSTimer						*checkTimer;
	SapphireBrowser				*browser;
	SapphireVirtualDirectory	*directory;
}

- (void)setDirectory:(SapphireVirtualDirectory *)dir;
- (void)setBrowser:(SapphireBrowser *)browse;

@end
