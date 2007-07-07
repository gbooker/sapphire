//
//  SapphireShowChooser.m
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireShowChooser.h"


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
	[[self list] addDividerAtIndex:1];
	[[self scene] renderScene];
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
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	
	if(row == 0)
		/*Put in the special "this is not a show"*/
		[[result textItem] setTitle:BRLocalizedString(@"<This is not a TV Show>", @"Mark an episode as not a TV show in the show chooser")];
	else
		/*Put in the show*/
		[[result textItem] setTitle:[[shows objectAtIndex:row-1] objectForKey:@"name"]];
	
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
