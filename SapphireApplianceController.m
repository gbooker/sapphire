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
#import "SapphireTheme.h"

@interface SapphireApplianceController (private)
- (void)setMenuFromSettings;
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

	masterNames = [[NSArray alloc] initWithObjects:	@"   Unwatched",
													@"   Favorite Shows",
													@"   Top Shows",
													@"   Browse Shows", 
													@"   Settings",
													@"   Reset the thing already", nil];
	
	SapphireBrowser *unwatchedBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireUnwatchedPredicate alloc] init] autorelease]];
	SapphireBrowser *favoriteShowsBrowser	= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireFavoritePredicate alloc] init] autorelease]];
	SapphireBrowser *topShowsBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory] predicate:[[[SapphireTopShowPredicate alloc] init] autorelease]];
	SapphireBrowser *playBrowser			= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection rootDirectory]];	
	settings									= [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/settings.plist"] metaData:[metaCollection rootDirectory]] ;
	[self setListTitle:							@"Main Menu"];
	[unwatchedBrowser setListTitle:			@"Unwatched Shows"];
	[favoriteShowsBrowser setListTitle:		@"Favorite Shows"];
	[topShowsBrowser setListTitle:			@"Top Shows"];
	[playBrowser setListTitle:				@"Show Browser"];
	[settings setListTitle:					@"Settings"] ;
	
	[settings setListIcon:[[SapphireTheme sharedTheme] gearGemForScene:[self scene]]] ;
	[playBrowser setListIcon:[[SapphireTheme sharedTheme] redGemForScene:[self scene]]] ;
	[topShowsBrowser setListIcon:[[SapphireTheme sharedTheme] greenGemForScene:[self scene]]] ;
	[favoriteShowsBrowser setListIcon:[[SapphireTheme sharedTheme] yellowGemForScene:[self scene]]] ;
	[unwatchedBrowser setListIcon:[[SapphireTheme sharedTheme] blueGemForScene:[self scene]]] ;
	masterControllers = [[NSArray alloc] initWithObjects:unwatchedBrowser,favoriteShowsBrowser,topShowsBrowser,playBrowser,settings,nil];
	[unwatchedBrowser release];
	[favoriteShowsBrowser release];
	[topShowsBrowser release];
	[playBrowser release];
	names = [[NSMutableArray alloc] init];
	controllers = [[NSMutableArray alloc] init];
	[self setMenuFromSettings];
	[[self list] setDatasource:self];

	return self;
}

- (void)dealloc
{
	[names release];
	[controllers release];
	[masterNames release];
	[masterControllers release];
	[metaCollection release];
	[SapphireSettings relinquishSettings];
	[settings release];
	[super dealloc];
}

- (void)setMenuFromSettings
{
	[names removeAllObjects];
	[controllers removeAllObjects];
	
	if([settings displayUnwatched])
	{
		[names addObject:[masterNames objectAtIndex:0]];
		[controllers addObject:[masterControllers objectAtIndex:0]];
	}
	if([settings displayFavorites])
	{
		[names addObject:[masterNames objectAtIndex:1]];
		[controllers addObject:[masterControllers objectAtIndex:1]];
	}
	if([settings displayTopShows])
	{
		[names addObject:[masterNames objectAtIndex:2]];
		[controllers addObject:[masterControllers objectAtIndex:2]];
	}
	[names addObject:[masterNames objectAtIndex:3]];
	[controllers addObject:[masterControllers objectAtIndex:3]];
	[names addObject:[masterNames objectAtIndex:4]];
	[controllers addObject:[masterControllers objectAtIndex:4]];
	if(![settings disableUIQuit])
		[names addObject:[masterNames objectAtIndex:5]];
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
	[self setMenuFromSettings];
	[[self list] reload];
	[[self scene] renderScene];
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
*/
	if( row > [names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [names objectAtIndex:row];
	result = [BRAdornedMenuItemLayer adornedFolderMenuItemWithScene: [self scene]] ;
	
	
	if([name isEqual: @"   Unwatched"]) [result setLeftIcon:[[SapphireTheme sharedTheme] blueGemForScene:[self scene]]];
	if([name isEqual: @"   Favorite Shows"])  [result setLeftIcon:[[SapphireTheme sharedTheme] yellowGemForScene:[self scene]]];
	if([name isEqual: @"   Top Shows"])  [result setLeftIcon:[[SapphireTheme sharedTheme] greenGemForScene:[self scene]]];
	if([name isEqual: @"   Browse Shows"])  [result setLeftIcon:[[SapphireTheme sharedTheme] redGemForScene:[self scene]]];
	if( [name isEqual: @"   Settings"]) [result setLeftIcon:[[SapphireTheme sharedTheme] gearGemForScene:[self scene]]] ;
	if( [name isEqual: @"   Reset the thing already"]) [result setLeftIcon:[[SapphireTheme sharedTheme] coneGemForScene:[self scene]]] ;

			
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
	
	if(row == [controllers count])
		[[NSApplication sharedApplication] terminate:self];
	id controller = [controllers objectAtIndex:row];
	[[self stack] pushController:controller];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end
