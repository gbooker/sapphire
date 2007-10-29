//
//  SapphireMovieChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMovieChooser.h"


@implementation SapphireMovieChooser

/*!
 * @brief Creates a new movie chooser
 *
 * @param scene The scene
 * @return The chooser
 */
- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	selection = -1;
	
	/* Set a control to display the fileName */
	fileNameText = [[BRTextControl alloc] initWithScene: scene];
	[fileNameText setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileNameText setText:@"File:"];
	NSRect 	frame = [[self masterLayer] frame];
	//	frame.size.height = frame.size.height / 16.0f;
	//	frame.size.width = frame.size.width * 2.0f / 3.0f;
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f) ;
	[fileNameText setFrame: frame];
	
	[self addControl: fileNameText];	
	[[self list] setDatasource:self];
	
	return self;
}

/*!
* @brief Override the layout
 *
 */
- (void)_doLayout
{
	//Shrink the list frame to make room for displaying the filename
	[super _doLayout];
	NSRect listFrame = [[_listControl layer] frame];
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*=2.0f;
	listFrame.origin.x *=0.25f;
	listFrame.origin.y *= 2.0f;
	[[_listControl layer] setFrame:listFrame];
}

- (void)dealloc
{
	[movies release];
	[fileName release];
	[super dealloc];
}

/*!
* @brief The list of movies to choose from
 *
 * @return The list of movies to choose from
 */
- (NSArray *)movies
{
	return movies;
}

/*!
 * @brief Sets the movies to choose from
 *
 * @param movieList The list of movies to choose from
 */
- (void)setMovies:(NSArray *)movieList
{
	movies = [movieList retain];
	[[self list] reload];
	[[self list] addDividerAtIndex:3 withLabel:nil];
	[[self scene] renderScene];
}

/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain] ;
	[fileNameText setTextAttributes: [[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileNameText setText:choosingForFileName];	
}

/*!
 * @brief The file name we searched for
 *
 * @return The file name we searched for
 */
- (NSString *)fileName
{
	return fileName;
}

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (int)selection
{
	return selection - 3;
}

- (long) itemCount
{
	return [movies count] + 3;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		[[result textItem] setTitle:BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser")];
	else if(row==1)/*Put in the special "this is something else"*/
			[[result textItem] setTitle:BRLocalizedString(@"<This is something else>", @"Mark a file that something else in the movie chooser")];
	else if(row==2)/*Put in the special "this is a tv show"*/
		[[result textItem] setTitle:BRLocalizedString(@"<This is a TV Show>", @"Mark a file that is tv show in the movie chooser")];
	else
		/*Put in the movie results*/
		[[result textItem] setTitle:[[movies objectAtIndex:row-3] objectForKey:@"name"]];
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [movies count])
		return nil;
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		return BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser");
	else if(row==1)/*Put in the special "this is something else"*/
		return BRLocalizedString(@"<This is something else>", @"Mark a file that is something else in the movie chooser");
	else if(row==2)/*Put in the special "this is a tv show"*/
		return BRLocalizedString(@"<This is a TV Show>", @"Mark a file that is a tv show in the movie chooser");
	else
		/*Put in the movie*/
		return [[movies objectAtIndex:row-3] objectForKey:@"name"];
}


- (void) itemSelected: (long) row
{
	/*User made selection, let's exit*/
	selection = row;
	[[self stack] popController];
}
@end
