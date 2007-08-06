//
//  SapphireSettings.h
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class SapphireDirectoryMetaData;

@interface SapphireSettings : BRMediaMenuController 
{
	NSArray						*names;
	NSArray						*keys;
	NSArray						*gems;
	NSMutableDictionary			*options;
	NSString					*path;
	NSDictionary				*defaults;
	SapphireDirectoryMetaData	*metaData;
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
- (BOOL)useAC3Passthrough;
- (BOOL)fastSwitching ;

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
