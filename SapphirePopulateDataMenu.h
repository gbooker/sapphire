//
//  SapphirePopulateDataMenu.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <BackRow/BRLayerController.h>
#import <BackRow/BRTextEntryDelegateProtocol.h>

@class BRRenderScene, BRControl, BRHeaderControl, BRTextEntryControl, BRButtonControl;
@protocol BRTextContainer;

@interface SapphirePopulateDataMenu : BRLayerController <BRTextEntryDelegate>
{
	BRHeaderControl *       _title;
	BRTextEntryControl *    _entry;
	BRButtonControl *       _button;
	BRProgressBarLayer* _bar ;


}
- (id) initWithScene: (BRRenderScene *) scene;
- (void) dealloc;

- (void) textDidChange: (id<BRTextContainer>) sender;
- (void) textDidEndEditing: (id<BRTextContainer>) sender;

- (void) editTitle;

- (void) removeControl: (BRControl *) control;
- (void) fadeFrom: (BRControl *) from to: (BRControl *) to;
@end
