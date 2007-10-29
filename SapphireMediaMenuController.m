//
//  SapphireMediaMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMediaMenuController.h"

@interface BRRenderScene (compat)
+ (BRRenderScene *)sharedInstance;
@end

@implementation SapphireMediaMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMediaMenuController class] respondsToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	return [super init];
}

- (BRRenderScene *)scene
{
	if([[BRMediaMenuController class] respondsToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end
