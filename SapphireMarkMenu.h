//
//  SapphireMarkMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SapphireMetaData;

@interface SapphireMarkMenu : BRMediaMenuController {
	BOOL				isDir;
	NSArray				*names;
	SapphireMetaData	*metaData;
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireMetaData *)meta;
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

@end
