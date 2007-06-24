//
//  SapphireApplianceController.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import "SapphireBrowser.h"
#import "SapphireMetaData.h"
#import "SapphirePredicates.h"
#import "SapphireSettings.h"

@interface SapphireApplianceController (private)
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
- (NSMutableDictionary *)metaDataForPath:(NSString *)path;
@end

@implementation SapphireApplianceController

+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.Sapphire" );
}

// 
- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	metaCollection = [[SapphireMetaDataCollection alloc] initWithFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/metaData.plist"] path:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"]];

	names = [[NSArray alloc] initWithObjects:@"   Unwatched",@"   Favorite Shows",@"   Top Shows", @"   Browse Shows", @"   Settings", nil];
	
	SapphireBrowser *unwatchedBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireUnwatchedPredicate alloc] init] autorelease]];
	SapphireBrowser *favoriteShowsBrowser	= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireFavoritePredicate alloc] init] autorelease]];
	SapphireBrowser *topShowsBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireTopShowPredicate alloc] init] autorelease]];
	SapphireBrowser *playBrowser			= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory]];	
	SapphireSettings *settingsMenu			= [[SapphireSettings alloc] initWithScene:[self scene]] ;
		
	[self setListTitle:							@"Main Menu"];
	[unwatchedBrowser setListTitle:			@"Unwatched Shows"];
	[favoriteShowsBrowser setListTitle:		@"Favorite Shows"];
	[topShowsBrowser setListTitle:			@"Favorite Shows"];
	[playBrowser setListTitle:				@"Show Browser"];
	[settingsMenu setListTitle:				@"Settings"] ;
	
	[settingsMenu  setListIcon:[[BRThemeInfo sharedTheme] gearImageForScene:[self scene]]] ;
	[playBrowser  setListIcon:[[BRThemeInfo sharedTheme] errorIconForScene:[self scene]]] ;
	[topShowsBrowser setListIcon:[[BRThemeInfo sharedTheme] errorIconForScene:[self scene]]] ;
	[favoriteShowsBrowser setListIcon:[[BRThemeInfo sharedTheme] errorIconForScene:[self scene]]] ;
	[unwatchedBrowser setListIcon:[[BRThemeInfo sharedTheme] errorIconForScene:[self scene]]] ;
	controllers = [[NSArray alloc] initWithObjects:unwatchedBrowser,favoriteShowsBrowser,topShowsBrowser,playBrowser,settingsMenu,nil];
	[unwatchedBrowser release];
	[favoriteShowsBrowser release];
	[topShowsBrowser release];
	[playBrowser release];
	[settingsMenu release];
	[[self list] setDatasource:self];

	return self;
}

- (void)dealloc
{
	[names release];
	[controllers release];
	[metaCollection release];
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
	if( row > [names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [names objectAtIndex:row];
	result = [BRAdornedMenuItemLayer adornedFolderMenuItemWithScene: [self scene]] ;
	[result setLeftIcon:[[BRThemeInfo sharedTheme] errorIconForScene:[self scene]]];
			
	// add text
	[[result textItem] setTitle: name] ;
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{

	if ( row > [ names count] ) return ( nil );
	
	NSString *result = [ names objectAtIndex: row] ;
	return ( result ) ;
/*
    // return the title for the list item at the given index here
    return ( @"Sapphire" );
*/
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
	
	id controller = [controllers objectAtIndex:row];
	[[self stack] pushController:controller];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

- (void)updateComplete
{
	BRListControl *list = [self list];
	long selection = [list selection];
	[list reload];
	[list setSelection:selection];	
}

@end
