//
//  SapphireSettings.m
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//


#import <BackRow/BackRow.h>
#import "SapphireApplianceController.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireTVShowDataMenu.h"

static SapphireSettings *sharedInstance = nil;

@interface SapphireSettings(private)
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
@end

@implementation SapphireSettings

#define	HIDE_FAVORITE_KEY	@"HideFavorites"
#define	HIDE_TOP_SHOWS_KEY	@"HideTopShows"
#define	HIDE_UNWATCHED_KEY	@"HideUnwatched"
#define	HIDE_SPOILERS_KEY	@"HideSpoilers"
#define HIDE_UI_QUIT_KEY	@"HideUIQuit"
#define	ENABLE_FAST_SWITCHING_KEY	@"EnableFastSwitching"
#define	DISABLE_ANON_KEY	@"DisableAnonymousReporting"


+ (SapphireSettings *)sharedSettings
{
	return sharedInstance;
}

+ (void)relinquishSettings
{
	[sharedInstance release];
	sharedInstance = nil;
}

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaData:(SapphireDirectoryMetaData *)meta
{
	if(sharedInstance != nil)
		return sharedInstance;
	
	self = [super initWithScene:scene];
	
	metaData = [meta retain];
	names = [[NSArray alloc] initWithObjects:	@"   Populate Show Data",
												@"   Fetch TV Data",
												@"   Hide \"Favorite Shows\"",
/*												@"   Hide \"Top Shows\"",*/
												@"   Hide \"Unwatched Shows\"", 
												@"   Hide Show Spoilers",
												@"   Hide UI Quit",
												@"   Fast Directory Switching",
												@"   Disable Anonymous Reporting", nil];
	
	keys = [[NSArray alloc] initWithObjects:		@"",
													@"",
													HIDE_FAVORITE_KEY, 
													/*HIDE_TOP_SHOWS_KEY, */
													HIDE_UNWATCHED_KEY,  
													HIDE_SPOILERS_KEY,
													HIDE_UI_QUIT_KEY,
													ENABLE_FAST_SWITCHING_KEY, 
													DISABLE_ANON_KEY, nil];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	gems = [[NSArray alloc] initWithObjects:	[theme gem:EYE_GEM_KEY],
												[theme gem:EYE_GEM_KEY],
												[theme gem:YELLOW_GEM_KEY],
												/*[theme gem:GREEN_GEM_KEY],*/
												[theme gem:BLUE_GEM_KEY],
												[theme gem:RED_GEM_KEY],
												[theme gem:CONE_GEM_KEY],
												[theme gem:CONE_GEM_KEY],
												[theme gem:CONE_GEM_KEY], nil];		
	
	path = [dictionaryPath retain];
	options = [[NSDictionary dictionaryWithContentsOfFile:dictionaryPath] mutableCopy];
	defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], HIDE_FAVORITE_KEY,
		[NSNumber numberWithBool:YES], HIDE_TOP_SHOWS_KEY,
		[NSNumber numberWithBool:NO], HIDE_UNWATCHED_KEY,
		[NSNumber numberWithBool:NO], HIDE_SPOILERS_KEY,
		[NSNumber numberWithBool:YES], HIDE_UI_QUIT_KEY,
		[NSNumber numberWithBool:YES], ENABLE_FAST_SWITCHING_KEY,
		[NSNumber numberWithBool:NO], DISABLE_ANON_KEY,
		nil];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	populateShowDataController=[[SapphirePopulateDataMenu alloc] initWithScene: scene metaData:metaData];
	
	[[self list] setDatasource:self];
	[[self list] addDividerAtIndex:2];
	sharedInstance = [self retain];

	return self;
}

- (void)writeSettings
{
	[options writeToFile:path atomically:YES];
}

- (void)dealloc
{
	[names release];
	[options release];
	[gems release];
	[path release];
	[defaults release];
	[metaData release];
	[super dealloc];
}

- (BOOL)boolForKey:(NSString *)key
{
	NSNumber *num = [options objectForKey:key];
	if(!num)
		num = [defaults objectForKey:key];
	return [num boolValue];
}

- (BOOL)displayUnwatched
{
	return ![self boolForKey:HIDE_UNWATCHED_KEY];
}

- (BOOL)displayFavorites;
{
	return ![self boolForKey:HIDE_FAVORITE_KEY];
}

- (BOOL)displayTopShows;
{
	return ![self boolForKey:HIDE_TOP_SHOWS_KEY];
}

- (BOOL)displaySpoilers;
{
	return ![self boolForKey:HIDE_SPOILERS_KEY];
}

- (BOOL)disableUIQuit
{
	return [self boolForKey:HIDE_UI_QUIT_KEY];
}

- (BOOL)disableAnonymousReporting;
{
	return [self boolForKey:DISABLE_ANON_KEY];
}

- (BOOL)fastSwitching
{
	return [self boolForKey:ENABLE_FAST_SWITCHING_KEY];

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
	result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: [self scene]] ;

	if( row > 1 && [self boolForKey:[keys objectAtIndex:row]])
	{
		[result setLeftIcon:[[BRThemeInfo sharedTheme] selectedSettingImageForScene:[self scene]]];
	}
	[result setRightIcon:[gems objectAtIndex:row]];

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

	if(row==0)
	{
		id controller = populateShowDataController;
		[[self stack] pushController:controller];
	}
	else if(row == 1)
	{
		SapphireTVShowDataMenu *menu = [[SapphireTVShowDataMenu alloc] initWithScene:[self scene] metaData:metaData savedSetting:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tvdata.plist"]];
		[[self stack] pushController:menu];
		[menu release];
	}
	if(row>1)
	{
		NSString *key = [keys objectAtIndex:row];
		BOOL setting = [self boolForKey:key];
		[options setObject:[NSNumber numberWithBool:!setting] forKey:key];
	}

	[self writeSettings];

	[[self list] reload] ;
	[[self scene] renderScene];

}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end

