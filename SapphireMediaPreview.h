//
//  SapphireMediaPreview.h
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireMetaData;

@interface SapphireMediaPreview : BRMetadataPreviewController{
	SapphireMetaData	*meta;
}

- (void)setMetaData:(SapphireMetaData *)newMeta;

@end
