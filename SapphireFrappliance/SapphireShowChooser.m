/*
 * SapphireShowChooser.m
 * Sapphire
 *
 * Created by Graham Booker on Jul. 1, 2007.
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

#import "SapphireShowChooser.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireTheme.h"


@implementation SapphireShowChooser

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	selection = -1;
	
	/* Set a control to display the fileName */
	fileName = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:@"File:" withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileName];
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
//	frame.size.height = frame.size.height / 16.0f;
//	frame.size.width = frame.size.width * 2.0f / 3.0f;
	frame.origin.y = frame.size.height / 4.0f;
	frame.origin.x = frame.size.width * (2.0f / 9.0f);
	[fileName setFrame: frame];
	
	
	[self addControl: fileName];	
	[[self list] setDatasource:self];
	
	return self;
}

- (void)dealloc
{
	[shows release];
	[searchStr release];
	[super dealloc];
}

- (void)setShows:(NSArray *)showList
{
	shows = [showList retain];
	[[self list] reload];
	[SapphireFrontRowCompat addDividerAtIndex:1 toList:[self list]];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (NSArray *)shows
{
	return shows;
}

- (void)setSearchStr:(NSString *)search
{
	searchStr = [search retain];
}

- (void)setFileName:(NSString*)choosingForFileName
{
	[SapphireFrontRowCompat setText:choosingForFileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileName];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileName setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [fileName renderedSize];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.44f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileName setFrame:frame];
}

- (NSString *)searchStr
{
	return searchStr;
}

- (void)willBePushed
{
	[super willBePushed];
	[(BRListControl *)[self list] setSelection:1];
}

- (int)selection
{
	return selection - 1;
}

- (long) itemCount
{
	return [shows count] + 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	
	if(row == 0)
		/*Put in the special "this is not a show"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is not a TV Show>", @"Mark an episode as not a TV show in the show chooser") forMenu:result];
	else
	{
		/*Put in the show*/
		[SapphireFrontRowCompat setTitle:[NSString stringWithFormat:@"  %@",[[shows objectAtIndex:row-1] objectForKey:@"name"]] forMenu:result];
		[SapphireFrontRowCompat setRightIcon:[theme gem:TVR_GEM_KEY] forMenu:result];
	}
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [shows count])
		return nil;
	
	if(row == 0)
		/*Put in the special "this is not a show"*/
		return BRLocalizedString(@"<This is not a TV Show>", @"Mark an episode as not a TV show in the show chooser");
	else
		/*Put in the show*/
		return [[shows objectAtIndex:row-1] objectForKey:@"name"];
}


- (void) itemSelected: (long) row
{
	/*User made selection, let's exit*/
	selection = row;
	[[self stack] popController];
}
@end