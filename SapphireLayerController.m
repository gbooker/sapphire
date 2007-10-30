//
//  SapphireLayerController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireLayerController.h"
#import "SapphireFrontRowCompat.h"

@implementation SapphireLayerController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRPostedAlertController class] respondsToSelector:@selector(initWithScene:)])
		self = [super initWithScene:scene];
	else
		self = [super init];
	
	[self setControls:[NSArray array]];
	
	return self;
}

- (BRRenderScene *)scene
{
	if([[BRPostedAlertController class] respondsToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end
