/*
 * SapphireConfirmPrompt.m
 * Sapphire
 *
 * Created by Graham Booker on Feb. 11 2009.
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

#import "SapphireConfirmPrompt.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SapphireConfirmPrompt

- (id)initWithScene:(BRRenderScene *)scene title:(NSString *)title subtitle:(NSString *)sub invokation:(NSInvocation *)invokation;
{
	self = [super initWithScene:scene];
	if(self == nil)
		return self;
	
	[self setListTitle:title];
	invoke = [invokation retain];
	[invoke retainArguments];
	subText = [sub retain];
	
	subtitle = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:sub withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:subtitle];
		
	[[self list] setDatasource:self];

	[self addControl:subtitle];
	
	[SapphireLayoutManager setCustomLayoutOnControl:self];
	
	return self;
}

- (void) dealloc
{
	[invoke release];
	[subtitle release];
	[subText release];
	[super dealloc];
}

- (void)setText:(NSString *)theText
{
	[SapphireFrontRowCompat setText:theText withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:subtitle];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:subtitle renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.4f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[subtitle setFrame:frame];
}

- (void)doMyLayout
{
	[self setText:subText];
}


- (void)wasPushed
{
	[self setText:subText];
	[super wasPushed];
}

- (long) itemCount
{
	return 2;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	if(row == 0)
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"Cancel", @"Cancel") forMenu:result];
	else if(row == 1)
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"OK", @"OK") forMenu:result];
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	
	if ( row >= 1 ) return ( nil );
	
	NSString *result = BRLocalizedString(@"OK", @"OK") ;
	
	return [NSString stringWithFormat:@"  ????? %@", result];
}

- (long) rowForTitle: (NSString *) aTitle
{
    long result = -1;
    long i, count = [self itemCount];
    for ( i = 0; i < count; i++ )
    {
        if ( [aTitle isEqualToString: [self titleForRow: i]] )
        {
            result = i;
            break;
        }
    }
    
    return ( result );
}

- (void)itemSelected:(long)row
{
	if(row == 1)
	{
		[invoke invoke];
		BRControl *ret = nil;
		[invoke getReturnValue:&ret];
		if(ret != nil)
			[[self stack] swapController:ret];
		else
			[[self stack] popController];
	}
	else
		[[self stack] popController];
}

- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master
{
	listFrame.size.height = master.size.height * 3.0f / 8.0f;
	listFrame.origin.y = master.size.height / 16.0f;
	listFrame.size.width = master.size.width / 3.0f;
	listFrame.origin.x = master.size.width / 3.0f;
	return listFrame;
}

@end
