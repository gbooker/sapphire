//
//  SapphireSettings.m
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//


#import <BackRow/BackRow.h>
#import "SapphireApplianceController.h"
#import "SapphireSettings.h"

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

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaData:(SapphireDirectoryMetaData *)metaData
{
	if(sharedInstance != nil)
		return sharedInstance;
	
	self = [super initWithScene:scene];
	
	names = [[NSArray alloc] initWithObjects:	@"   Populate Show Data",
												@"   Hide \"Favorite Shows\"",
												@"   Hide \"Top Shows\"",
												@"   Hide \"Unwatched Shows\"", 
												@"   Hide Show Spoilers",
												@"   Disable Anonymous Reporting", nil];
	keys = [[NSArray alloc] initWithObjects:@"", HIDE_FAVORITE_KEY, HIDE_TOP_SHOWS_KEY, HIDE_UNWATCHED_KEY, HIDE_SPOILERS_KEY, DISABLE_ANON_KEY, nil];
	path = [dictionaryPath retain];
	options = [[NSDictionary dictionaryWithContentsOfFile:dictionaryPath] mutableCopy];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	populateShowDataController=[[SapphirePopulateDataMenu alloc] initWithScene: scene metaData:metaData];
	
	[[self list] setDatasource:self];
	[[self list] addDividerAtIndex:1];
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
	[path release];
	[super dealloc];
}

- (BOOL)displayUnwatched
{
	return ![[options objectForKey:HIDE_UNWATCHED_KEY] boolValue];
}

- (BOOL)displayFavorites;
{
	return ![[options objectForKey:HIDE_FAVORITE_KEY] boolValue];
}

- (BOOL)displayTopShows;
{
	return ![[options objectForKey:HIDE_TOP_SHOWS_KEY] boolValue];
}

- (BOOL)displaySpoilers;
{
	return ![[options objectForKey:HIDE_SPOILERS_KEY] boolValue];
}

- (BOOL)disableAnonymousReporting;
{
	return [[options objectForKey:DISABLE_ANON_KEY] boolValue];
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

	if(row==0)	[result setLeftIcon:[[BRThemeInfo sharedTheme] gearImageForScene:[self scene]]];
	else if( row > 0 && [[options objectForKey:[keys objectAtIndex:row]] boolValue])
	{
		[result setLeftIcon:[[BRThemeInfo sharedTheme] selectedSettingImageForScene:[self scene]]];
	}
	if(row==1)[result setRightIcon:[[SapphireTheme sharedTheme] yellowGemForScene:[self scene]]];
	if(row==2)[result setRightIcon:[[SapphireTheme sharedTheme] greenGemForScene:[self scene]]];
	if(row==3)[result setRightIcon:[[SapphireTheme sharedTheme] blueGemForScene:[self scene]]];
	if(row==4)[result setRightIcon:[[SapphireTheme sharedTheme] redGemForScene:[self scene]]];


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
//		[[self stack] pushController:populateShowDataController];
//		[[self stack] popController] ;

		
	} 
	if(row>0)
	{
		NSString *key = [keys objectAtIndex:row];
		NSNumber *setting = [options objectForKey:key];
		[options setObject:[NSNumber numberWithBool:![setting boolValue]] forKey:key];
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

