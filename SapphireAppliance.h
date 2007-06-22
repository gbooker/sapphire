//
//  SapphireAppliance.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BackRow/BRAppliance.h>

@class BRLayerController, BRRenderScene;

@interface SapphireAppliance : BRAppliance 
{
}

+ (NSString *) className;

- (NSString *) moduleName;
+ (NSString *) moduleKey;
- (NSString *) moduleKey;

- (BRLayerController *) applianceControllerWithScene: (BRRenderScene *) scene;

@end
