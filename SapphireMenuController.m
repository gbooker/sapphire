//
//  SapphireMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMenuController.h"

@interface BRRenderScene (compat)
+ (BRRenderScene *)sharedInstance;
@end

@implementation SapphireMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMenuController class] respondsToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	return [super init];
}

- (BRRenderScene *)scene
{
	if([[BRMenuController class] respondsToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end