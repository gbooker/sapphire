/*
 * SapphireButtonControl.m
 * Sapphire
 *
 * Created by Graham Booker on Jan. 6, 2008.
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

#import "SapphireButtonControl.h"
#import <objc/objc-class.h>

@implementation SapphireButtonControl
- (BRSelectionLozengeLayer *)lozenge
{
	Class mycls = [self class];
	Ivar lozengeOffset = class_getInstanceVariable(mycls, "_lozenge");
	BRSelectionLozengeLayer *lozenge = *(BRSelectionLozengeLayer * *)(((char *)self)+lozengeOffset->ivar_offset);
	return lozenge;
}

- (void)setTitle:(NSString *)title
{
	NSRect frame = [super frame];
	BRSelectionLozengeLayer *lozenge = [self lozenge];
	frame.origin.x += frame.size.width / 2.0;
	frame.size.width = 0;
	[lozenge setFrame:frame];
	[super setTitle:title];
	Class mycls = [self class];
	Ivar titleLayerOffset = class_getInstanceVariable(mycls, "_title");
	BRTextLayer *titleLayer = *(BRTextLayer * *)(((char *)self)+titleLayerOffset->ivar_offset);
	frame = [self frame];
	frame.size.width = [titleLayer renderedSize].width + 4.0 * [lozenge edgeGlowWidth];
	frame.origin = NSMakePoint(-frame.size.width / 2.0, 0);
	[lozenge setFrame:frame];
}

- (NSRect)frame
{
	NSRect normalFrame = [super frame];
	normalFrame.size.width += [[self lozenge] edgeGlowWidth] * 4.0;
	return normalFrame;
}

- (void)setHidden:(BOOL)yn
{
	[super setHidden:yn];
	[[self lozenge] setHidden:yn];
}

- (void)setYPosition:(float)pos
{
	if([BRButtonControl instancesRespondToSelector:@selector(setYPosition:)])
		[super setYPosition:pos];
	else
	{
		NSRect frame = [super frame];
		frame.origin.y = pos;
		[super setFrame:frame];
	}
}

@end

