/*
 * SapphireTextWithSpinnerController.m
 * Sapphire
 *
 * Created by Graham Booker on Nov. 27, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
	
	if(NSClassFromString(@"BRRenderScene") != nil)
		return [BRRenderScene sharedInstance];
	return nil;
}

@end
