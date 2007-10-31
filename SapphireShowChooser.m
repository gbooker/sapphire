//
//  SapphireShowChooser.m
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireShowChooser.h"
#import "SapphireFrontRowCompat.h"


@implementation SapphireShowChooser

/*!
 * @brief Creates a new show chooser
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

/*!
 * @brief Sets the shows to choose from
 *
 * @param showList The list of shows to choose from
 */
- (void)setShows:(NSArray *)showList
{
	shows = [showList retain];
	[[self list] reload];
	[[self list] addDividerAtIndex:1 withLabel:@""];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

/*!
 * @brief The list of shows to choose from
 *
 * @return The list of shows to choose from
 */
- (NSArray *)shows
{
	return shows;
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
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
	[SapphireFrontRowCompat setText:choosingForFileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileName];
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
	return [shows count] + 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	if(row == 0)
		/*Put in the special "this is not a show"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is not a TV Show>", @"Mark an episode as not a TV show in the show chooser") forMenu:result];
	else
		/*Put in the show*/
		[SapphireFrontRowCompat setTitle:[[shows objectAtIndex:row-1] objectForKey:@"name"] forMenu:result];
	
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
