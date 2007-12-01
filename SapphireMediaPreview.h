//
//  SapphireMediaPreview.h
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@class SapphireMetaData, SapphireDirectoryMetaData;

@interface SapphireMediaPreview : BRMetadataPreviewController{
	SapphireMetaData			*meta;
	SapphireDirectoryMetaData	*dirMeta;
}

- (void)setMetaData:(SapphireMetaData *)newMeta inMetaData:(SapphireDirectoryMetaData *)dir;

@end
