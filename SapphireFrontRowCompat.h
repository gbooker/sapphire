//
//  SapphireFrontRowCompat.h
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

@interface BRRenderScene (compat)
+ (BRRenderScene *)sharedInstance;
@end

@interface SapphireFrontRowCompat : NSObject {
}
+ (BOOL)usingFrontRow;
+ (id)imageAtPath:(NSString *)path;
+ (BRAdornedMenuItemLayer *)textMenuItemForScene:(BRRenderScene *)scene folder:(BOOL)folder;
+ (void)setTitle:(NSString *)title forMenu:(BRAdornedMenuItemLayer *)menu;
+ (void)setRightJustifiedText:(NSString *)title forMenu:(BRAdornedMenuItemLayer *)menu;
+ (void)setLeftIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu;
+ (void)setRightIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu;
+ (id)selectedSettingImageForScene:(BRRenderScene *)scene;

+ (NSRect)frameOfController:(id)controller;
+ (void)setText:(NSString *)text withAtrributes:(NSDictionary *)attributes forControl:(BRTextControl *)control;
+ (void)addSublayer:(id)sub toControl:(id)controller;

+ (BRHeaderControl *)newHeaderControlWithScene:(BRRenderScene *)scene;
+ (BRButtonControl *)newButtonControlWithScene:(BRRenderScene *)scene masterLayerSize:(NSSize)size;
+ (BRTextControl *)newTextControlWithScene:(BRRenderScene *)scene;
+ (BRProgressBarWidget *)newProgressBarWidgetWithScene:(BRRenderScene *)scene;

+ (void)renderScene:(BRRenderScene *)scene;
@end
