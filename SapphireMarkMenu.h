//
//  SapphireMarkMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"
@class SapphireMetaData, SapphirePredicate;

@interface SapphireMarkMenu : SapphireMediaMenuController {
	BOOL				isDir;
	NSMutableArray		*names;
	NSMutableArray		*commands;
	SapphireMetaData	*metaData;
	SapphirePredicate	*predicate;
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireMetaData *)meta;
- (void) dealloc;

- (void)setPredicate:(SapphirePredicate *)newPredicate;

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

@end
