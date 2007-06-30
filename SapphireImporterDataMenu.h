//
//  SapphireImporterDataMenu.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <BackRow/BRLayerController.h>
#import <BackRow/BRTextEntryDelegateProtocol.h>

@class BRRenderScene, BRControl, BRHeaderControl, BRTextEntryControl, BRButtonControl, SapphireDirectoryMetaData;
@protocol BRTextContainer;

@interface SapphireImporterDataMenu : BRLayerController
{
	BRHeaderControl				*title;
	BRButtonControl					*button;
	BRTextControl					*text;
	BRTextControl					*fileProgress;
	BRTextControl					*currentFile;
	BRProgressBarWidget			*bar;

	SapphireDirectoryMetaData		*meta;
	NSMutableArray					*importItems;
	NSTimer						*importTimer;
	float							max;
	float							current;
	float							updated ;
}
- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData;
- (void) dealloc;
@end
