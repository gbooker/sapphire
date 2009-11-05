/*
 * SapphireCenteredMenuController.m
 * Sapphire
 *
 * Created by Graham Booker on Oct. 29, 2007.
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

#import "SapphireCenteredMenuController.h"
#import "SapphireFrontRowCompat.h"

@interface SapphireWideCenteredLayout : NSObject
{
	id								realLayout;
	id <SapphireListLayoutDelegate>	delegate;		//Not Retained
}
@end

@interface BRLayerController (compat)
- (void)wasBuried;
- (void)wasExhumed;
@end

@interface SapphireCenteredMenuController (compat)
- (id)firstSublayerNamed:(NSString *)name;
- (id)firstControlNamed:(NSString *)name;
- (void)setLayoutManager:(id)newLayout;
- (id)layoutManager;
@end

@implementation SapphireWideCenteredLayout
- (id)initWithReal:(id)real
{
	self = [super init];
	if(self == nil)
		return self;
	realLayout = [real retain];
	return self;
}

- (void)setDelegate:(id <SapphireListLayoutDelegate>)del
{
	delegate = del;
}

- (void) dealloc
{
	[realLayout release];
	[super dealloc];
}

- (void)layoutSublayersOfLayer:(id)layer
{
	[realLayout layoutSublayersOfLayer:layer];
	NSRect master = [layer frame];
  
  id listLayer;
  
  if([layer respondsToSelector:@selector(firstControlNamed:)])
    listLayer = [layer firstControlNamed:@"list"];
  else
    listLayer = [layer firstSublayerNamed:@"list"];
  
	NSRect listFrame = [listLayer frame];
	listFrame = [delegate listRectWithSize:listFrame inMaster:master];
	[listLayer setFrame:listFrame];
}
- (NSSize)preferredSizeOfLayer:(id)layer
{
	return [realLayout preferredSizeOfLayer:layer];
}

@end

@implementation SapphireCenteredMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	Class centeredMenuClass = [BRCenteredMenuController class];
	if([centeredMenuClass instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	self = [super init];
	if([centeredMenuClass instancesRespondToSelector:@selector(layoutManager)])
	{
		SapphireWideCenteredLayout *newLayout = [[SapphireWideCenteredLayout alloc] initWithReal:[self layoutManager]];
		[newLayout setDelegate:self];
		[self setLayoutManager:newLayout];
		[newLayout release];
	}
	return self;
}

- (BRRenderScene *)scene
{
	if([[BRCenteredMenuController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	if(NSClassFromString(@"BRRenderScene") != nil)
		return [BRRenderScene sharedInstance];
	return nil;
}

- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master
{
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*=2.0f;
	listFrame.origin.x = (master.size.width - listFrame.size.width) * 0.5f;
	listFrame.origin.y *= 2.0f;
	return listFrame;
}

- (void)_doLayout
{
	//Shrink the list frame to make room for displaying the filename
	[super _doLayout];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSRect listFrame = [[_listControl layer] frame];
	listFrame = [self listRectWithSize:listFrame inMaster:master];
	[[_listControl layer] setFrame:listFrame];
}

/*Just because so many classes use self as the list data source*/
- (float)heightForRow:(long)row
{
	return 0.0f;
}

- (BOOL)rowSelectable:(long)row
{
	return YES;
}

#include "SapphireStackControllerCompatFunctions.h"

@end
