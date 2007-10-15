//
//  SapphirePosterChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphirePosterChooser.h"


@implementation SapphirePosterChooser

/*!
 * @brief Creates a new poster chooser
 *
 * @param scene The scene
 * @return The chooser
 */
- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene: scene];
	if(!self)
		return nil;
	selection = -1;
	

	
	/* Set a control to display the fileName */
	fileNameText = [[BRTextControl alloc] initWithScene: scene];
	[fileNameText setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileNameText setText:@"No File"];	
	NSRect 	frame = [[self masterLayer] frame];
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
	listFrame.origin.y *= 2.0f;
	[[_listControl layer] setFrame:listFrame];
}



- (void)dealloc
{
	[posters release];
	[fileName release];
	[movieTitle release];
	[super dealloc];
}

/*!
* @brief The list of movies to choose from
 *
 * @return The list of movies to choose from
 */
- (NSArray *)posters
{
	return posters;
}

/*!
 * @brief Sets the posters to choose from
 *
 * @param posterList The list of movies to choose from
 */
- (void)setPosters:(NSArray *)posterList
{
	posters = [posterList retain];
	[[self list] reload];
	[[self scene] renderScene];
}



/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
		[fileNameText setTextAttributes: [[BRThemeInfo sharedTheme] paragraphTextAttributes]];
		[fileNameText setText:choosingForFileName];	
}



/*!
 * @brief Sets the string we searched for
 *
 * @param search The string we searched for
 */
- (void)setMovieTitle:(NSString *)theMovieTitle
{
	movieTitle = [theMovieTitle retain];
}

/*!
 * @brief The string we searched for
 *
 * @return The string we searched for
 */
- (NSString *)movieTitle
{
	return movieTitle;
}

/*!
 * @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (int)selection
{
	return selection;
}

- (long) itemCount
{
	return [posters count];
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	[[result textItem] setTitle:[NSString stringWithFormat:@"Version %2d",row+1]];
	
	return result;
}



- (NSString *) titleForRow: (long) row
{
	if(row > [posters count])
		return nil;
	else
		return [NSString stringWithFormat:@"Version %2d",row+1];
}


- (void) itemSelected: (long) row
{
	/*User made selection, let's exit*/
	selection = row;
	[[self stack] popController];
}
@end
