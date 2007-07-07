//
//  SapphireImporterDataMenu.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireDirectoryMetaData;
@protocol SapphireMetaDataScannerDelegate;

@interface SapphireImporterDataMenu : BRLayerController <SapphireMetaDataScannerDelegate>
{
	BRHeaderControl					*title;
	BRButtonControl					*button;
	BRTextControl					*text;
	BRTextControl					*fileProgress;
	BRTextControl					*currentFile;
	BRProgressBarWidget				*bar;

	SapphireDirectoryMetaData		*meta;
	NSMutableArray					*importItems;
	NSTimer							*importTimer;
	float							max;
	float							current;
	float							updated ;
	BOOL							suspended;
	BOOL							canceled;
}
- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData;
- (void) dealloc;
- (void)getItems;
@end

@interface SapphireImporterDataMenu (protectedAccess)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)importNextItem:(NSTimer *)timer;
- (void)setCurrentFile:(NSString *)theCurrentFile;
- (void)pause;
- (void)resume;
- (void)skipNextItem;
@end
