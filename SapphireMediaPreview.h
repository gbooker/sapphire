//
//  SapphireMediaPreview.h
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRMediaPreviewControllerProtocol.h>
#import <BackRow/BRRenderLayer.h>

@class SapphireFileMetaData;

@interface SapphireMediaPreview : BRMetadataPreviewController{
	SapphireFileMetaData	*meta;
}

- (void)setMetaData:(SapphireFileMetaData *)newMeta;

@end
