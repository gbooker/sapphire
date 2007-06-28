//
//  SapphireSettings.h
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import "SapphirePopulateDataMenu.h"

@class BRHeaderControl ;

@interface SapphireSettings : BRMediaMenuController 
{
	NSArray						*names;
	NSArray						*keys;
	NSMutableDictionary			*options;
	SapphirePopulateDataMenu	*populateShowDataController;
	NSString					*path;
}

+ (SapphireSettings *)sharedSettings;
+ (void)relinquishSettings;

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaData:(SapphireDirectoryMetaData *)metaData;
- (void) dealloc;

- (BOOL)displayUnwatched;
- (BOOL)displayFavorites;
- (BOOL)displayTopShows;
- (BOOL)displaySpoilers;
- (BOOL)disableUIQuit;
- (BOOL)disableAnonymousReporting;

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
