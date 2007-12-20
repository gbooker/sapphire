/*
 * SapphireDVDLoadingController.m
 * Sapphire
 *
 * Created by Graham Booker on Dec. 20, 2007.
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

#import "SapphireDVDLoadingController.h"
#import "SapphireFrontRowCompat.h"

@interface BRDVDLoadingController (compat)
- (id)initWithAsset:(BRDVDMediaAsset *)asset;
@end

@implementation SapphireDVDLoadingController

- (id) initWithScene: (BRRenderScene *) scene forAsset:(BRDVDMediaAsset *)asset
{
	if([[BRDVDLoadingController class] instancesRespondToSelector:@selector(initWithScene:forAsset:)])
		return [super initWithScene:scene forAsset:asset];
	
	return [super initWithAsset:asset];
}

- (BRRenderScene *)scene
{
	if([[BRDVDLoadingController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

@end
