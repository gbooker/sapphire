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
+ (void)setLeftIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu;
@end
