//
//  SapphireSettings.h
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"

@class SapphireDirectoryMetaData;

@interface SapphireSettings : SapphireMediaMenuController 
{
	NSArray						*names;
	NSArray						*keys;
	NSArray						*gems;
	NSMutableDictionary			*options;
	NSString					*path;
	NSDictionary				*defaults;
	SapphireMetaDataCollection	*metaCollection;
}

+ (SapphireSettings *)sharedSettings;
+ (void)relinquishSettings;

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaDataCollection:(SapphireMetaDataCollection *)collection;
- (void) dealloc;

- (BOOL)displayUnwatched;
- (BOOL)displayFavorites;
- (BOOL)displayTopShows;
- (BOOL)displaySpoilers;
- (BOOL)displayAudio;
- (BOOL)displayVideo;
- (BOOL)disableUIQuit;
- (BOOL)disableAnonymousReporting;
- (BOOL)useAC3Passthrough;
- (BOOL)fastSwitching;
- (int)indexOfLastPredicate;
- (void)setIndexOfLastPredicate:(int)index;

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
