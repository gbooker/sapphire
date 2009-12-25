/*
 * SapphireErrorDisplayController.m
 * Sapphire
 *
 * Created by pnmerrill on Jan. 5, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireErrorDisplayController.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@interface SapphireErrorDisplayController ()
- (void)layoutFrame;
@end


@implementation SapphireErrorDisplayController

- (id)initWithScene:(BRRenderScene *)scene error:(NSString *)error longError:(NSString *)longError
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	errorString = [error retain];
	[self setListTitle:errorString];
	
	text = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:longError withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:text];
	[self addControl:text];
	[self layoutFrame];
	
	[SapphireLayoutManager setCustomLayoutOnControl:self];
	
	return self;
}

- (void) dealloc
{
	[errorString release];
	[text release];
	[super dealloc];
}

- (void)layoutFrame
{
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:text renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 2.0f / 3.0f)];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 2.0f / 3.0f - txtSize.height) * 0.5f + master.origin.y;
	frame.size = txtSize;
	[text setFrame:frame];
}

- (void)doMyLayout
{
	[self layoutFrame];
}

- (void)wasPushed
{
	[self layoutFrame];
	[super wasPushed];
}

@end
