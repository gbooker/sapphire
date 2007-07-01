//
//  SapphireShowChooser.m
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireShowChooser.h"


@implementation SapphireShowChooser

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

- (void)setShows:(NSArray *)showList
{
	shows = [showList retain];
	[[self list] reload];
	[[self scene] renderScene];
}

- (NSArray *)shows
{
	return shows;
}

- (void)setSearchStr:(NSString *)search
{
	searchStr = [search retain];
}

- (NSString *)searchStr
{
	return searchStr;
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
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	
	if(row == 0)
		[[result textItem] setTitle:@"<This is not a TV Show>"];
	else
		[[result textItem] setTitle:[[shows objectAtIndex:row-1] objectForKey:@"name"]];
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [shows count])
		return nil;
	
	if(row == 0)
		return @"<This is not a TV Show>";
	else
		return [[shows objectAtIndex:row-1] objectForKey:@"name"];
}


- (void) itemSelected: (long) row
{
	selection = row;
	[[self stack] popController];
}
@end
