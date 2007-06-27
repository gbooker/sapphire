//
//  SapphireTheme.h
//  Sapphire
//
//  Created by Graham Booker on 6/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BRTexture, BRRenderScene;

@interface SapphireTheme : NSObject {
	CGImageRef		redJem;
	CGImageRef		blueJem;
	CGImageRef		greenJem;
	CGImageRef		yellowJem;
}
+ (id)sharedTheme;

- (BRTexture *)redJemForScene:(BRRenderScene *)scene;
- (BRTexture *)blueJemForScene:(BRRenderScene *)scene;
- (BRTexture *)greenJemForScene:(BRRenderScene *)scene;
- (BRTexture *)yellowJemForScene:(BRRenderScene *)scene;

@end
