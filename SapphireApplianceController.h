//
//  SapphireApplianceController.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRMediaMenuController.h>

@class BRRenderScene, BRRenderLayer;


@interface SapphireApplianceController : BRMediaMenuController
{
	NSString *_dir;
	NSMutableArray * _names ;

}

+ (NSString *) rootMenuLabel ;


- (id) initWithScene: (BRRenderScene *) scene;
- (id) initWithScene: (BRRenderScene *) scene directory: (NSString *)dir;
- (void) dealloc;
- (BOOL)isDirectory:(NSString *)path;
/*
- (void) willBePushed;
- (void) wasPushed;
- (void) willBePopped;
- (void) wasPopped;
- (void) willBeBuried;
- (void) wasBuriedByPushingController: (BRLayerController *) controller;
- (void) willBeExhumed;
- (void) wasExhumedByPoppingController: (BRLayerController *) controller;
*/
- (long) itemCount;
- (id<BRMenuItemLayer>) itemForRow: (long) row;
- (NSString *) titleForRow: (long) row;
- (long) rowForTitle: (NSString *) title;

- (void) itemSelected: (long) row;

//- (id<BRMediaPreviewController>) previewControllerForItem: (long) item;

@end
