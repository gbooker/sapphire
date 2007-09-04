//
//  SapphireCollectionSettings.h
//  Sapphire
//
//  Created by Graham Booker on 9/3/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SapphireMetaDataCollection;

@interface SapphireCollectionSettings : BRMediaMenuController {
	NSArray							*names;
	SapphireMetaDataCollection		*metaCollection;
	NSInvocation					*setInv;
	NSInvocation					*getInv;
}

- (id) initWithScene: (BRRenderScene *) scene collection:(SapphireMetaDataCollection *)collection;
- (void)setSettingSelector:(SEL)selector;
- (void)setGettingSelector:(SEL)selector;

@end
