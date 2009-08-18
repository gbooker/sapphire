/*
 * SapphireMediaMenuController.m
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

#import "SapphireMediaMenuController.h"
#import "SapphireFrontRowCompat.h"

@interface SapphireMediaMenuController (compat)
- (id)firstSublayerNamed:(NSString *)name;
- (id)firstControlNamed:(NSString *)name;
- (void)setLayoutManager:(id)newLayout;
- (id)layoutManager;
@end

@interface BRLayerController (compat)
- (void)wasBuried;
- (void)wasExhumed;
@end

@interface SapphireCustomMediaLayout : NSObject
{
	id								realLayout;
	id <SapphireListLayoutDelegate>	delegate;		//Not retained
}
@end

@implementation SapphireCustomMediaLayout
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

@implementation SapphireMediaMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	self = [super init];
	SapphireCustomMediaLayout *newLayout = [[SapphireCustomMediaLayout alloc] initWithReal:[self layoutManager]];
	[newLayout setDelegate:self];
	[self setLayoutManager:newLayout];
	[newLayout release];
	return self;
}

- (BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master
{
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

- (int)getSelection
{
	BRListControl *list = [self list];
	int row;
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(selection)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(selection)];
	[selInv invokeWithTarget:list];
	if([signature methodReturnLength] == 8)
	{
		double retDoub = 0;
		[selInv getReturnValue:&retDoub];
		row = retDoub;
	}
	else
		[selInv getReturnValue:&row];
	return row;
}

- (void)setSelection:(int)sel
{
	BRListControl *list = [self list];
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(setSelection:)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(setSelection:)];
	if(strcmp([signature getArgumentTypeAtIndex:2], "l"))
	{
		double dvalue = sel;
		[selInv setArgument:&dvalue atIndex:2];
	}
	else
	{
		long lvalue = sel;
		[selInv setArgument:&lvalue atIndex:2];
	}
	[selInv invokeWithTarget:list];
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventRemoteAction remoteAction = [SapphireFrontRowCompat remoteActionForEvent:event];
    if ([(BRControllerStack *)[self stack] peekController] != self)
		remoteAction = 0;
    
    int itemCount = [[(BRListControl *)[self list] datasource] itemCount];
    switch (remoteAction)
    {	
		case kBREventRemoteActionUp:
			if([self getSelection] == 0 && [event value] == 1)
			{
				[self setSelection:itemCount-1];
				[self updatePreviewController];
				return YES;
			}
			break;
		case kBREventRemoteActionDown:
			if([self getSelection] == itemCount-1 && [event value] == 1)
			{
				[self setSelection:0];
				[self updatePreviewController];
				return YES;
			}
			break;
    }
	return [super brEventAction:event];
}

#include "SapphireStackControllerCompatFunctions.h"

@end
