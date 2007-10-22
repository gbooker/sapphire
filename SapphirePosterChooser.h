//
//  SapphirePosterChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <BackRow/BRMediaMenuController.h>
#import <BackRow/BRIconSourceProtocolProtocol.h>
#import <BackRow/BRMenuListItemProviderProtocol.h>

#define POSTER_CHOOSE_CANCEL		-1
#define POSTER_CHOOSE_REFRESH		0


@class BRRenderScene, BRRenderLayer, BRMarchingIconLayer;

@interface SapphirePosterChooser : BRMenuController {
	NSArray			*posters;
	NSMutableArray	*posterLayers;
	NSString		*fileName ;
	NSString		*movieTitle;
	long			selectedPoster;
	BRTextControl	*fileInfoText;
	BRMarchingIconLayer *   posterMarch;
	BRBlurryImageLayer	*defaultImage;
}
- (id) initWithScene: (BRRenderScene *) scene;
- (void) dealloc;
- (void) resetLayout;
- (void) willBePushed;
- (void) wasPopped;
- (void)setPosters:(NSArray *)posterList;
- (void)loadPosters;
- (void)reloadPoster:(int)index;
- (void)setFileName:(NSString *)choosingForFileName;
- (NSArray *)posters;
- (void)setMovieTitle:(NSString *)theMovieTitle;
- (NSString *)movieTitle;
- (NSString *)fileName;
- (long)selectedPoster;

@end

@interface SapphirePosterChooser (IconDataSource) <BRIconSourceProtocol>

- (long) iconCount;
- (BRRenderLayer *) iconAtIndex: (long) index;

@end

@interface SapphirePosterChooser (ListDataSource) <BRMenuListItemProvider>

- (long) itemCount;
- (id<BRMenuItemLayer>) itemForRow: (long) row;
- (NSString *) titleForRow: (long) row;
- (long) rowForTitle: (NSString *) title;

@end

@interface SapphirePosterChooser (IconListManagement)
- (BRBlurryImageLayer *) getPosterLayer: (NSString *) thePosterPath;
- (void) loadPoster:(int)index;
- (void) hideIconMarch;
- (void) showIconMarch;
- (void) selectionChanged: (NSNotification *) note;
@end