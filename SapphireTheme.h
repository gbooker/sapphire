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
	CGImageRef		redGem;
	CGImageRef		blueGem;
	CGImageRef		greenGem;
	CGImageRef		yellowGem;
	CGImageRef		gearGem;
	CGImageRef		coneGem;
	CGImageRef		iGem;
}
+ (id)sharedTheme;

- (BRTexture *)redGemForScene:(BRRenderScene *)scene;
- (BRTexture *)blueGemForScene:(BRRenderScene *)scene;
- (BRTexture *)greenGemForScene:(BRRenderScene *)scene;
- (BRTexture *)yellowGemForScene:(BRRenderScene *)scene;
- (BRTexture *)gearGemForScene:(BRRenderScene *)scene;
- (BRTexture *)coneGemForScene:(BRRenderScene *)scene ;
- (BRTexture *)iGemForScene:(BRRenderScene *)scene ;
@end
