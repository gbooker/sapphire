//
//  SapphireBrowser.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireDirectoryMetaData, SapphireFileMetaData, SapphireMetaDataCollection, BRTVShowsSortControl, SapphireSettings, BRSegmentedSortControl, SapphirePredicate;
@protocol SapphireMetaDataDelegate, SapphireMetaDataScannerDelegate;

@interface SapphireBrowser : BRMediaMenuController <SapphireMetaDataDelegate, SapphireMetaDataScannerDelegate>
{
	NSMutableArray				* _names ;
	NSMutableArray				*items ;
	SapphireDirectoryMetaData	*metaData;
	SapphirePredicate			*predicate;
//	BRSegmentedSortControl		*modeControl;
	SapphireFileMetaData		*currentPlayFile;
	int							dirCount;
	int							fileCount;
	BOOL						cancelScan;
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta;
- (void) dealloc;

- (void) willBePushed;
- (void) wasPushed;
- (void) willBePopped;
- (void) wasPopped;
- (void) willBeBuried;
- (void) wasBuriedByPushingController: (BRLayerController *) controller;
- (void) willBeExhumed;
- (void) wasExhumedByPoppingController: (BRLayerController *) controller;

- (long) itemCount;
- (id<BRMenuItemLayer>) itemForRow: (long) row;
- (NSString *) titleForRow: (long) row;
- (long) rowForTitle: (NSString *) title;

- (void) itemSelected: (long) row;

//- (id<BRMediaPreviewController>) previewControllerForItem: (long) item;

@end
