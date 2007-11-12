//
//  SapphireMovieChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMovieChooser.h"
#import "SapphireFrontRowCompat.h"


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

/*!
* @brief Override the layout
 *
 */
- (void)_doLayout
{
	//Shrink the list frame to make room for displaying the filename
	[super _doLayout];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSRect listFrame = [[_listControl layer] frame];	
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*=2.0f;
	listFrame.origin.x = (master.size.width - listFrame.size.width) * 0.5f;
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
	[SapphireFrontRowCompat addDividerAtIndex:3 toList:[self list]];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain] ;
	[SapphireFrontRowCompat setText:choosingForFileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileNameText];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileNameText setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [fileNameText renderedSize];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.4f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileNameText setFrame:frame];
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
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser") forMenu:result];
	else if(row==1)/*Put in the special "this is something else"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is something else>", @"Mark a file that something else in the movie chooser") forMenu:result];
	else if(row==2)/*Put in the special "this is a tv show"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is a TV Show>", @"Mark a file that is tv show in the movie chooser") forMenu:result];
	else
		/*Put in the movie results*/
		[SapphireFrontRowCompat setTitle:[[movies objectAtIndex:row-3] objectForKey:@"name"] forMenu:result];
	
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
