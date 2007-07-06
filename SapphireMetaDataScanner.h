//
//  SapphireMetaDataScanner.h
//  Sapphire
//
//  Created by Graham Booker on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SapphireDirectoryMetaData;
@protocol SapphireMetaDataScannerDelegate;

@interface SapphireMetaDataScanner : NSObject <SapphireMetaDataScannerDelegate> {
	SapphireDirectoryMetaData				*metaDir;
	NSMutableArray							*remaining;
	NSMutableArray							*results;
	id <SapphireMetaDataScannerDelegate>	delegate;
}

- (id)initWithDirectoryMetaData:(SapphireDirectoryMetaData *)meta delegate:(id <SapphireMetaDataScannerDelegate>)newDelegate;
- (void)setGivesResults:(BOOL)givesResults;

@end
