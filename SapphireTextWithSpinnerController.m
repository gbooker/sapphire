//
//  SapphireTextWithSpinnerController.m
//  Sapphire
//
//  Created by Graham Booker on 11/27/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireTextWithSpinnerController.h"
#import "SapphireFrontRowCompat.h"

@interface BRTextWithSpinnerController (compat)
- (id) initWithTitle:(NSString *)title text:(NSString *)text;
@end

@implementation SapphireTextWithSpinnerController
- (id) initWithScene: (BRRenderScene *) scene title:(NSString *)title text:(NSString *)text showBack:(BOOL)show
{
	if([[BRTextWithSpinnerController class] instancesRespondToSelector:@selector(initWithScene:title:text:showBack:)])
		return [super initWithScene:scene title:title text:text showBack:show];
	
	return [super initWithTitle:title text:text];
}

- (BRRenderScene *)scene
{
	if([[BRTextWithSpinnerController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end
