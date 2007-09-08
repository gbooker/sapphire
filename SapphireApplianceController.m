//
//  SapphireApplianceController.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import "SapphireBrowser.h"
#import "SapphireMetaData.h"
#import "SapphirePredicates.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireTVDirectory.h"

#import "SapphireImporterDataMenu.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireAllImporter.h"

#define BROWSER_MENU_ITEM		BRLocalizedString(@"   Browse", @"Browser Menu Item")
#define ALL_IMPORT_MENU_ITEM	BRLocalizedString(@"   Import All Data", @"All Importer Menu Item")
#define SETTINGS_MENU_ITEM		BRLocalizedString(@"   Settings", @"Settings Menu Item")
#define RESET_MENU_ITEM			BRLocalizedString(@"   Reset the thing already", @"UI Quit")

@interface SapphireApplianceController (private)
- (void)setMenuFromSettings;
- (void)recreateMenu;
@end

@implementation SapphireApplianceController

static NSArray *predicates = nil;

+ (void)initialize
{
	predicates = [[NSArray alloc] initWithObjects:[[SapphireUnwatchedPredicate alloc] init], [[SapphireFavoritePredicate alloc] init], [[SapphireTopShowPredicate alloc] init], nil];
	[predicates makeObjectsPerformSelector:@selector(release)];
}

+ (SapphirePredicate *)predicate
{
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	int index = [settings indexOfLastPredicate];
	if(index == NSNotFound)
		return nil;
	return [predicates objectAtIndex:index];
}

+ (SapphirePredicate *)nextPredicate
{
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	int index = [settings indexOfLastPredicate];
	int newIndex;
	switch(index)
	{
		case NSNotFound:
			newIndex = 0;
			if([settings displayUnwatched])
				break;
		case 0:
			newIndex = 1;
			if([settings displayFavorites])
				break;
		case 1:
			newIndex = 2;
			if([settings displayTopShows])
				break;
		default:
			newIndex = NSNotFound;
	}
	[settings setIndexOfLastPredicate:newIndex];
	if(newIndex == NSNotFound)
		return nil;
	return [predicates objectAtIndex:newIndex];
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

- (SapphireImporterDataMenu *)allImporterForCollection:(SapphireMetaDataCollection *)collection
{
	SapphireFileDataImporter *fileImp = [[SapphireFileDataImporter alloc] init];
	SapphireTVShowImporter *tvImp = [[SapphireTVShowImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/tvdata.plist"]];
	
	SapphireAllImporter *allImp = [[SapphireAllImporter alloc] initWithImporters:[NSArray arrayWithObjects:fileImp, tvImp, nil]];
	[fileImp release];
	[tvImp release];
	SapphireImporterDataMenu *ret = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaDataCollection:collection importer:allImp];
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
	
	settings								= [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/settings.plist"] metaDataCollection:metaCollection] ;
	[self setListTitle:						BRLocalizedString(@"Main Menu", @"")];
	[settings setListTitle:					BRLocalizedString(@"Settings", @"Settings Menu Item")] ;
	[settings setListIcon:					[theme gem:GEAR_GEM_KEY]];
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

- (void)recreateMenu
{
	SapphireImporterDataMenu *allImporter	= [self allImporterForCollection:metaCollection];

	NSMutableArray *mutableMasterNames = [[NSMutableArray alloc] init];
	NSMutableArray *mutableMasterControllers = [[NSMutableArray alloc] init];
	BRTexture *predicateGem = [SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]];
	
	SapphireTVDirectory *tvDir = [[SapphireTVDirectory alloc] init];
	SapphireBrowser *tvBrowser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:tvDir];
	[tvBrowser setListTitle:BRLocalizedString(@"TV Shows", nil)];
	[tvBrowser setListIcon:predicateGem];
	[mutableMasterNames addObject:BRLocalizedString(@"   TV Shows", nil)];
	[mutableMasterControllers addObject:tvBrowser];
	[tvBrowser release];
	
	NSEnumerator *browserPointsEnum = [[metaCollection collectionDirectories] objectEnumerator];
	NSString *browserPoint = nil;
	while((browserPoint = [browserPointsEnum nextObject]) != nil)
	{
		if(![metaCollection skipCollection:browserPoint])
			[[metaCollection directoryForPath:browserPoint] loadMetaData];
		if([metaCollection hideCollection:browserPoint])
			continue;
		SapphireBrowser *browser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection directoryForPath:browserPoint]];
		[browser setListTitle:[browserPoint lastPathComponent]];
		[browser setListIcon:predicateGem];
		[mutableMasterNames addObject:[NSString stringWithFormat:@"   %@", browserPoint]];
		[mutableMasterControllers addObject:browser];
		[browser release];
	}
	[mutableMasterNames addObjectsFromArray:[NSArray arrayWithObjects:
		ALL_IMPORT_MENU_ITEM,
		SETTINGS_MENU_ITEM,
		RESET_MENU_ITEM,
		nil]];
	[mutableMasterControllers addObjectsFromArray:[NSArray arrayWithObjects:
		allImporter,
		settings,
		nil]];
	masterNames = [[NSArray alloc] initWithArray:mutableMasterNames];
	masterControllers = [[NSArray alloc] initWithArray:mutableMasterControllers];
	[mutableMasterNames release];
	[mutableMasterControllers release];
	
	names = [[NSMutableArray alloc] init];
	controllers = [[NSMutableArray alloc] init];
	[self setMenuFromSettings];
}

- (void)setMenuFromSettings
{
	[names removeAllObjects];
	[controllers removeAllObjects];
	[names addObjectsFromArray:masterNames];
	[controllers addObjectsFromArray:masterControllers];
	if([settings disableUIQuit])
		[names removeLastObject];
}

- (void) willBePushed
{
    // We're about to be placed on screen, but we're not yet there
    [self recreateMenu];
	[[self list] reload];
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
	if([name isEqual: ALL_IMPORT_MENU_ITEM]) [result setLeftIcon:[theme gem:GEAR_GEM_KEY]];
	else if([name isEqual: SETTINGS_MENU_ITEM]) [result setLeftIcon:[theme gem:GEAR_GEM_KEY]];
	else if([name isEqual: RESET_MENU_ITEM]) [result setLeftIcon:[theme gem:CONE_GEM_KEY]];
	else [result setLeftIcon:[SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]]];
	
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
