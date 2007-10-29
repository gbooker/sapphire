//
//  SapphireCenteredMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireCenteredMenuController.h"
#import "SapphireFrontRowCompat.h"

@implementation SapphireCenteredMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRCenteredMenuController class] respondsToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	return [super init];
}

- (BRRenderScene *)scene
{
	if([[BRCenteredMenuController class] respondsToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end
