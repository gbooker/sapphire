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
	fileName = [[BRTextControl alloc] initWithScene: scene];
	[fileName setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileName setText:@"File:"];
	NSRect 	frame = [[self masterLayer] frame];
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
	[movies release];
	[searchStr release];
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
	[[self list] addDividerAtIndex:1];
	[[self scene] renderScene];
}

/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
		[fileName setTextAttributes: [[BRThemeInfo sharedTheme] paragraphTextAttributes]];
		[fileName setText:choosingForFileName];	
}



/*!
 * @brief Sets the string we searched for
 *
 * @param search The string we searched for
 */
- (void)setSearchStr:(NSString *)search
{
	searchStr = [search retain];
}

/*!
 * @brief The string we searched for
 *
 * @return The string we searched for
 */
- (NSString *)searchStr
{
	return searchStr;
}

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
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
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	
	if(row == 0)
		/*Put in the special "this is not a movie"*/
		[[result textItem] setTitle:BRLocalizedString(@"<This is not a Movie>", @"Mark a file that is not a movie in the movie chooser")];
	else
		/*Put in the movie*/
		[[result textItem] setTitle:[[movies objectAtIndex:row-1] objectForKey:@"name"]];
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [movies count])
		return nil;
	
	if(row == 0)
		/*Put in the special "this is not a movie"*/
		return BRLocalizedString(@"<This is not a Movie>", @"Mark a file that is not a movie in the movie chooser");
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
