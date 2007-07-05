//
//  SapphireAppliance.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright (c) 2007 __www.nanopi.net__. All rights reserved.
//

@interface SapphireAppliance : BRAppliance 
{
}

+ (NSString *) className;

- (NSString *) moduleName;
+ (NSString *) moduleKey;
- (NSString *) moduleKey;

- (BRLayerController *) applianceControllerWithScene: (BRRenderScene *) scene;

@end
