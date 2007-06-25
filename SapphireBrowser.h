//
//  SapphireBrowser.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRMediaMenuController.h>
#import <BackRow/BRTVShowsSortControl.h>
#import "SapphirePredicates.h"

@class BRRenderScene, BRRenderLayer;

@class SapphireDirectoryMetaData, SapphireMetaDataCollection;
@protocol SapphireMetaDataDelegate;

@interface SapphireBrowser : BRMediaMenuController <SapphireMetaDataDelegate>
{
	NSMutableArray				* _names ;
	SapphireDirectoryMetaData	*metaData;
	SapphirePredicate			*predicate;
	BRTVShowsSortControl		*sort;
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta;
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta predicate:(SapphirePredicate *)newPredicate;
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
