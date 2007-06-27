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

- (BRTexture *)redGemForScene:(BRRenderScene *)scene;
- (BRTexture *)blueGemForScene:(BRRenderScene *)scene;
- (BRTexture *)greenGemForScene:(BRRenderScene *)scene;
- (BRTexture *)yellowGemForScene:(BRRenderScene *)scene;

@end
