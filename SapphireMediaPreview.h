//
//  SapphireMediaPreview.h
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRMediaPreviewControllerProtocol.h>
#import <BackRow/BRRenderLayer.h>

@class SapphireMetaData;

@interface SapphireMediaPreview : BRMetadataPreviewController{
	SapphireMetaData	*meta;
}

- (void)setMetaData:(SapphireMetaData *)newMeta;

@end
