//
//  SapphireMediaMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"
#import "SapphireFrontRowCompat.h"

@implementation SapphireMediaMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	return [super init];
}

- (BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}


/*Just because so many classes use self as the list data source*/
- (float)heightForRow:(long)row
{
	return 50.0f;
}

- (BOOL)rowSelectable:(long)row
{
	return YES;
}

@end
