/*
 * SapphireLayoutManager.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 24, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireLayoutManager.h"

@interface BRLayerController (compat)
- (void)setLayoutManager:(id)newLayout;
- (id)layoutManager;
@end

@implementation SapphireLayoutManager

+ (id)setCustomLayoutOnControl:(BRLayerController <SapphireLayoutDelegate> *)control
{
	SapphireLayoutManager *newLayout = [[SapphireLayoutManager alloc] initWithReal:[control layoutManager]];
	[newLayout setDelegate:control];
	[control setLayoutManager:newLayout];
	[newLayout autorelease];
	
	return newLayout;
}

- (id)initWithReal:(id)real
{
	self = [super init];
	if(self == nil)
		return self;
	realLayout = [real retain];
	return self;
}

- (void) dealloc
{
	[realLayout release];
	[super dealloc];
}

- (void)setDelegate:(id <SapphireLayoutDelegate>)theDelegate
{
	delegate = theDelegate;
}

- (void)layoutSublayersOfLayer:(id)layer
{
	[realLayout layoutSublayersOfLayer:layer];
	[delegate doMyLayout];
}

- (NSSize)preferredSizeOfLayer:(id)layer
{
	return [realLayout preferredSizeOfLayer:layer];
}
@end