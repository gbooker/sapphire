//
//  SapphireMarkMenu.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMarkMenu.h"
#import "SapphireMetaData.h"

@implementation SapphireMarkMenu

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireMetaData *)meta
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	isDir = [meta isKindOfClass:[SapphireDirectoryMetaData class]];
	metaData = [meta retain];
	if(isDir)
		names = [[NSArray alloc] initWithObjects:@"Mark All as Watched", @"Mark All as Unwatched", @"Mark All as Favorite", @"Mark All as Not Favorite", nil];
	else if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		NSString *watched = nil;
		NSString *favorite = nil;
		
		if([fileMeta watched])
			watched = @"Mark as Unwatched";
		else
			watched = @"Mark as Watched";

		if([fileMeta favorite])
			favorite = @"Mark as Favorite";
		else
			favorite = @"Mark as Not Favorite";
		names = [[NSArray alloc] initWithObjects:watched, favorite, nil];
	}
	else
	{
		[self autorelease];
		return nil;
	}
	[[self list] setDatasource:self];
	
	return self;
}

- (void) dealloc
{
	[metaData release];
	[names release];
	[super dealloc];
}

- (void) willBePushed
{
    // We're about to be placed on screen, but we're not yet there
    
    // always call super
    [super willBePushed];
}

- (void) wasPushed
{
    // We've just been put on screen, the user can see this controller's content now
    
    // always call super
    [super wasPushed];
}

- (void) willBePopped
{
    // The user pressed Menu, but we've not been removed from the screen yet
    
    // always call super
    [super willBePopped];
}

- (void) wasPopped
{
    // The user pressed Menu, removing us from the screen
    
    // always call super
    [super wasPopped];
}

- (void) willBeBuried
{
    // The user just chose an option, and we will be taken off the screen
    
    // always call super
    [super willBeBuried];
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
    // The user chose an option and this controller os no longer on screen
    
    // always call super
    [super wasBuriedByPushingController: controller];
}

- (void) willBeExhumed
{
    // the user pressed Menu, but we've not been revealed yet
    
    // always call super
    [super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
    // handle being revealed when the user presses Menu
    
    // always call super
    [super wasExhumedByPoppingController: controller];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	return ( [ names count]);
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	/*
	 // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
	 // return that object, it will be used to display the list item.
	 return ( nil );
	 */
	if( row >= [names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [names objectAtIndex:row];
	result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: [self scene]] ;
	
	// add text
	[[result textItem] setTitle: name] ;
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{
	
	if ( row >= [ names count] ) return ( nil );
	
	NSString *result = [ names objectAtIndex: row] ;
	return ( result ) ;
}

- (long) rowForTitle: (NSString *) title
{
    long result = -1;
    long i, count = [self itemCount];
    for ( i = 0; i < count; i++ )
    {
        if ( [title isEqualToString: [self titleForRow: i]] )
        {
            result = i;
            break;
        }
    }
    
    return ( result );
}

- (void) itemSelected: (long) row
{
    // This is called when the user presses play/pause on a list item
	if(row >= [names count])
		return;
	
	if(isDir)
	{
		SapphireDirectoryMetaData *dirMeta = (SapphireDirectoryMetaData *)metaData;
		switch(row)
		{
			case 0:
				[dirMeta setWatched:YES];
				break;
			case 1:
				[dirMeta setWatched:NO];
				break;
			case 2:
				[dirMeta setFavorite:YES];
				break;
			case 3:
				[dirMeta setFavorite:NO];
				break;
		}
	}
	else
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		switch(row)
		{
			case 0:
				[fileMeta setWatched:![fileMeta watched]];
				break;
			case 1:
				[fileMeta setFavorite:![fileMeta favorite]];
				break;
		}
	}
	[[self stack] popController];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end
