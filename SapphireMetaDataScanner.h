//
//  SapphireMetaDataScanner.h
//  Sapphire
//
//  Created by Graham Booker on 7/6/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SapphireMetaData.h"

@interface SapphireMetaDataScanner : NSObject <SapphireMetaDataScannerDelegate> {
	SapphireDirectoryMetaData				*metaDir;
	NSMutableArray							*remaining;
	NSMutableArray							*results;
	NSMutableSet							*skipDirectories;
	id <SapphireMetaDataScannerDelegate>	delegate;
}

- (id)initWithDirectoryMetaData:(SapphireDirectoryMetaData *)meta delegate:(id <SapphireMetaDataScannerDelegate>)newDelegate;
- (void)setSkipDirectories:(NSMutableSet *)skip;
- (void)setGivesResults:(BOOL)givesResults;

@end
