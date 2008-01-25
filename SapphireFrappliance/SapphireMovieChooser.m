/*
 * SapphireMovieChooser.m
 * Sapphire
 *
 * Created by Patrick Merrill on Jul. 27, 2007.
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

#import "SapphireMovieChooser.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import	"SapphireTheme.h"


@implementation SapphireMovieChooser

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	selection = -1;
	
	/* Set a control to display the fileName */
	fileNameText = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:@"File:" withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileNameText];
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	//	frame.size.height = frame.size.height / 16.0f;
	//	frame.size.width = frame.size.width * 2.0f / 3.0f;
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f) ;
	[fileNameText setFrame: frame];
	
	[self addControl: fileNameText];	
	[[self list] setDatasource:self];
	
	return self;
}

- (void)dealloc
{
	[movies release];
	[fileName release];
	[super dealloc];
}

- (NSArray *)movies
{
	return movies;
}

- (void)setMovies:(NSArray *)movieList
{
	movies = [movieList retain];
	[[self list] reload];
	[SapphireFrontRowCompat addDividerAtIndex:1 toList:[self list]];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain] ;
	[SapphireFrontRowCompat setText:choosingForFileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileNameText];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileNameText setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [fileNameText renderedSize];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.44f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileNameText setFrame:frame];
}

- (NSString *)fileName
{
	return fileName;
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
	return [movies count] + 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is Not a Movie>", @"Mark a file that is not a movie in the movie chooser") forMenu:result];
	else
	{
		/*Put in the movie results*/
		[SapphireFrontRowCompat setTitle:[NSString stringWithFormat:@"  %@",[[movies objectAtIndex:row-1] objectForKey:@"name"]] forMenu:result];
		[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
	}
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [movies count])
		return nil;
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		return BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser");
	else
		/*Put in the movie*/
		return [[movies objectAtIndex:row-1] objectForKey:@"name"];
}


- (void) itemSelected: (long) row
{
	/*User made selection, let's exit*/
	selection = row;
	[[self stack] popController];
}

@end
