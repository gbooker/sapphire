//
//  SapphireApplianceController.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import "SapphireBrowser.h"
#import "SapphireMetaData.h"
#import "SapphirePredicates.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"

#import "SapphireImporterDataMenu.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireAllImporter.h"

#define UNWATCHED_MENU_ITEM		BRLocalizedString(@"   Unwatched", @"Unwatched Browser Menu Item")
#define FAVORITE_MENU_ITEM		BRLocalizedString(@"   Favorite Shows", @"Favorite Browser Menu Item")
#define TOP_SHOWS_MENU_ITEM		BRLocalizedString(@"   Top Shows", @"Top Shows Browser Menu Item")
#define BROWSER_MENU_ITEM		BRLocalizedString(@"   Browse Shows", @"Browser Menu Item")
#define ALL_IMPORT_MENU_ITEM	BRLocalizedString(@"   Import All Data", @"All Importer Menu Item")
#define SETTINGS_MENU_ITEM		BRLocalizedString(@"   Settings", @"Settings Menu Item")
#define RESET_MENU_ITEM			BRLocalizedString(@"   Reset the thing already", @"UI Quit")

@interface SapphireApplianceController (private)
- (void)setMenuFromSettings;
@end

@implementation SapphireApplianceController

static NSArray *predicates = nil;

+ (void)initialize
{
	predicates = [[NSArray alloc] initWithObjects:[[SapphireUnwatchedPredicate alloc] init], [[SapphireFavoritePredicate alloc] init], /*[[SapphireTopShowPredicate alloc] init], */[[NSNull alloc] init], nil];
	[predicates makeObjectsPerformSelector:@selector(release)];
}

+ (SapphirePredicate *)nextPredicate:(SapphirePredicate *)predicate
{
	if(predicate == nil)
		predicate = (SapphirePredicate *)[NSNull null];
	
	int index = [predicates indexOfObject:predicate];
	int count = [predicates count];
	index = (index + 1) % count;
	if(index == count - 1)
		return nil;
	return [predicates objectAtIndex:index];
}

+ (BRTexture *)gemForPredicate:(SapphirePredicate *)predicate
{
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if(predicate == nil)
		return [theme gem:RED_GEM_KEY];
	if([predicate isKindOfClass:[SapphireUnwatchedPredicate class]])
		return [theme gem:BLUE_GEM_KEY];
	if([predicate isKindOfClass:[SapphireFavoritePredicate class]])
		return [theme gem:YELLOW_GEM_KEY];
	if([predicate isKindOfClass:[SapphireTopShowPredicate class]])
		return [theme gem:GREEN_GEM_KEY];
	return nil;
}
								
+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.Sapphire" );
}

- (SapphireImporterDataMenu *)allImporterForRootDir:(SapphireDirectoryMetaData *)rootDir
{
	SapphireFileDataImporter *fileImp = [[SapphireFileDataImporter alloc] init];
	SapphireTVShowImporter *tvImp = [[SapphireTVShowImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/settings.plist"]];
	
	SapphireAllImporter *allImp = [[SapphireAllImporter alloc] initWithImporters:[NSArray arrayWithObjects:fileImp, tvImp, nil]];
	[fileImp release];
	[tvImp release];
	SapphireImporterDataMenu *ret = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaData:rootDir importer:allImp];
	return [ret autorelease];
}

// 
- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	
	//Setup the theme's scene
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	[theme setScene:[self scene]];

	metaCollection = [[SapphireMetaDataCollection alloc] initWithFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/metaData.plist"]];

	masterNames = [[NSArray alloc] initWithObjects:	UNWATCHED_MENU_ITEM,
													FAVORITE_MENU_ITEM,
													TOP_SHOWS_MENU_ITEM,
													BROWSER_MENU_ITEM,
													ALL_IMPORT_MENU_ITEM,
													SETTINGS_MENU_ITEM,
													RESET_MENU_ITEM, nil];
	
	SapphireDirectoryMetaData *rootDir = [metaCollection directoryForPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"]];
	SapphireBrowser *unwatchedBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:rootDir predicate:[predicates objectAtIndex:0]];
	SapphireBrowser *favoriteShowsBrowser	= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:rootDir predicate:[predicates objectAtIndex:1]];
	SapphireBrowser *topShowsBrowser		= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:rootDir predicate:[[[SapphireTopShowPredicate alloc] init] autorelease]];
	SapphireBrowser *playBrowser			= [[SapphireBrowser alloc] initWithScene:[self scene] metaData:rootDir];
	SapphireImporterDataMenu *allImporter	= [self allImporterForRootDir:rootDir];
	settings									= [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/settings.plist"] metaData:rootDir] ;
	[self setListTitle:							BRLocalizedString(@"Main Menu", @"")];
	[unwatchedBrowser setListTitle:			BRLocalizedString(@"Unwatched Shows", @"Unwatched Browser Menu Item")];
	[favoriteShowsBrowser setListTitle:		BRLocalizedString(@"Favorite Shows", @"Favorite Browser Menu Item")];
	[topShowsBrowser setListTitle:			BRLocalizedString(@"Top Shows", @"Top Shows Browser Menu Item")];
	[playBrowser setListTitle:				BRLocalizedString(@"Show Browser", @"Browser Menu Item")];
	[settings setListTitle:					BRLocalizedString(@"Settings", @"Settings Menu Item")] ;
	
	[settings setListIcon:[theme gem:GEAR_GEM_KEY]];
	[playBrowser setListIcon:[theme gem:RED_GEM_KEY]];
	[topShowsBrowser setListIcon:[theme gem:GREEN_GEM_KEY]];
	[favoriteShowsBrowser setListIcon:[theme gem:YELLOW_GEM_KEY]];
	[unwatchedBrowser setListIcon:[theme gem:BLUE_GEM_KEY]];
	masterControllers = [[NSArray alloc] initWithObjects:unwatchedBrowser,favoriteShowsBrowser,topShowsBrowser,playBrowser,allImporter,settings,nil];
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
	[names addObject:[masterNames objectAtIndex:5]];
	[controllers addObject:[masterControllers objectAtIndex:5]];
	if(![settings disableUIQuit])
		[names addObject:[masterNames objectAtIndex:6]];
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
	
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if([name isEqual: UNWATCHED_MENU_ITEM]) [result setLeftIcon:[theme gem:BLUE_GEM_KEY]];
	if([name isEqual: FAVORITE_MENU_ITEM])  [result setLeftIcon:[theme gem:YELLOW_GEM_KEY]];
	if([name isEqual: TOP_SHOWS_MENU_ITEM])  [result setLeftIcon:[theme gem:GREEN_GEM_KEY]];
	if([name isEqual: BROWSER_MENU_ITEM])  [result setLeftIcon:[theme gem:RED_GEM_KEY]];
	if([name isEqual: ALL_IMPORT_MENU_ITEM]) [result setLeftIcon:[theme gem:GEAR_GEM_KEY]];
	if([name isEqual: SETTINGS_MENU_ITEM]) [result setLeftIcon:[theme gem:GEAR_GEM_KEY]];
	if([name isEqual: RESET_MENU_ITEM]) [result setLeftIcon:[theme gem:CONE_GEM_KEY]];

			
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
