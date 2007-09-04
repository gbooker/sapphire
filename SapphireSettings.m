//
//  SapphireSettings.m
//  Sapphire
//
//  Created by pnmerrill on 6/23/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//


#import <BackRow/BackRow.h>
#import "SapphireApplianceController.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireCollectionSettings.h"

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
#define USE_AC3_PASSTHROUGH	@"EnableAC3Passthrough"
#define	DISABLE_ANON_KEY	@"DisableAnonymousReporting"
#define LAST_PREDICATE		@"LastPredicate"

/*!
 * @brief Get the shared settings object
 *
 * @return The settings object
 */
+ (SapphireSettings *)sharedSettings
{
	return sharedInstance;
}

/*!
 * @brief Allow the shared settings object to be freed
 */
+ (void)relinquishSettings
{
	[sharedInstance release];
	sharedInstance = nil;
}

/*!
 * @brief Create a settings object
 *
 * @param scene The scene
 * @param dictionaryPath The path of the saved setting
 * @param meta The top level meta data
 * @return The settings object
 */
- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaDataCollection:(SapphireMetaDataCollection *)collection
{
	if(sharedInstance != nil)
		return sharedInstance;
	
	self = [super initWithScene:scene];
	
	/*Setup display*/
	metaCollection = [collection retain];
	names = [[NSArray alloc] initWithObjects:	BRLocalizedString(@"   Populate File Data", @"Populate File Data menu item"),
												BRLocalizedString(@"   Fetch Internet Data", @"Fetch Internet Data menu item"),
												BRLocalizedString(@"   Hide Collections", @"Hide Collections menu item"),
												BRLocalizedString(@"   Don't Import Collections", @"Don't Import Collections menu item"),
												BRLocalizedString(@"   Skip \"Favorite Shows\" filter", @"Skip Favorite shows menu item"),
/*												BRLocalizedString(@"   Skip \"Top Shows\" filter", @"Skip Top shows menu item"),*/
												BRLocalizedString(@"   Skip \"Unwatched Shows\" filter", @"Skip Unwatched shows menu item"), 
												BRLocalizedString(@"   Hide Show Spoilers", @"Hide show summarys menu item"),
												BRLocalizedString(@"   Hide UI Quit", @"Hide the ui quitter menu item"),
												BRLocalizedString(@"   Fast Directory Switching", @"Don't rescan directories upon entry and used cached data"),
												BRLocalizedString(@"   Enable AC3 Passthrough", @"Enable AC3 Passthrough menu item"),
												BRLocalizedString(@"   Disable Anonymous Reporting", @"Disable the anonymous reporting for aid in future features"), nil];
	
	keys = [[NSArray alloc] initWithObjects:		@"",
													@"",
													@"",
													@"",
													HIDE_FAVORITE_KEY, 
													/*HIDE_TOP_SHOWS_KEY, */
													HIDE_UNWATCHED_KEY,  
													HIDE_SPOILERS_KEY,
													HIDE_UI_QUIT_KEY,
													ENABLE_FAST_SWITCHING_KEY,
													USE_AC3_PASSTHROUGH,
													DISABLE_ANON_KEY, nil];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	gems = [[NSArray alloc] initWithObjects:	[theme gem:EYE_GEM_KEY],
												[theme gem:EYE_GEM_KEY],
												[theme gem:EYE_GEM_KEY],
												[theme gem:EYE_GEM_KEY],
												[theme gem:YELLOW_GEM_KEY],
												/*[theme gem:GREEN_GEM_KEY],*/
												[theme gem:BLUE_GEM_KEY],
												[theme gem:RED_GEM_KEY],
												[theme gem:CONE_GEM_KEY],
												[theme gem:CONE_GEM_KEY],
												[theme gem:CONE_GEM_KEY],
												[theme gem:CONE_GEM_KEY], nil];		
	
	path = [dictionaryPath retain];
	options = [[NSDictionary dictionaryWithContentsOfFile:dictionaryPath] mutableCopy];
	/*Set deaults*/
	defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], HIDE_FAVORITE_KEY,
		[NSNumber numberWithBool:YES], HIDE_TOP_SHOWS_KEY,
		[NSNumber numberWithBool:NO], HIDE_UNWATCHED_KEY,
		[NSNumber numberWithBool:NO], HIDE_SPOILERS_KEY,
		[NSNumber numberWithBool:YES], HIDE_UI_QUIT_KEY,
		[NSNumber numberWithBool:YES], ENABLE_FAST_SWITCHING_KEY,
		[NSNumber numberWithBool:NO], USE_AC3_PASSTHROUGH,
		[NSNumber numberWithBool:NO], DISABLE_ANON_KEY,
		[NSNumber numberWithInt:NSNotFound], LAST_PREDICATE,
		nil];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	/*display*/
	[[self list] setDatasource:self];
	[[self list] addDividerAtIndex:4];
	/*Save our instance*/
	sharedInstance = [self retain];

	return self;
}

/*!
 * @brief Writes settings to disk
 */
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
	[metaCollection release];
	[super dealloc];
}

/*!
 * @brief Get a setting
 *
 * @param key The setting to retrieve
 * @return The setting in an NSNumber
 */
- (NSNumber *)numberForKey:(NSString *)key
{
	/*Check the user's setting*/
	NSNumber *num = [options objectForKey:key];
	if(!num)
		/*User hasn't set yet, use default then*/
		num = [defaults objectForKey:key];
	return num;
}

/*!
 * @brief Get a setting
 *
 * @param key The setting to retrieve
 * @return YES if set, NO otherwise
 */
- (BOOL)boolForKey:(NSString *)key
{
	/*Check the user's setting*/
	NSNumber *num = [options objectForKey:key];
	if(!num)
		/*User hasn't set yet, use default then*/
		num = [defaults objectForKey:key];
	return [num boolValue];
}

/*!
 * @brief Returns whether to display unwatched
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayUnwatched
{
	return ![self boolForKey:HIDE_UNWATCHED_KEY];
}

/*!
 * @brief Returns whether to display favorites
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayFavorites;
{
	return ![self boolForKey:HIDE_FAVORITE_KEY];
}

/*!
 * @brief Returns whether to display top shows
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displayTopShows;
{
	return ![self boolForKey:HIDE_TOP_SHOWS_KEY];
}

/*!
 * @brief Returns whether to display spoilers
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)displaySpoilers;
{
	return ![self boolForKey:HIDE_SPOILERS_KEY];
}

/*!
 * @brief Returns whether to disable UI quit
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)disableUIQuit
{
	return [self boolForKey:HIDE_UI_QUIT_KEY];
}

/*!
 * @brief Returns whether to disable anonymous reporting
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)disableAnonymousReporting;
{
	return [self boolForKey:DISABLE_ANON_KEY];
}

/*!
 * @brief Returns whether to use AC3 passthrough
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)useAC3Passthrough
{
	return [self boolForKey:USE_AC3_PASSTHROUGH];
}

/*!
 * @brief Returns whether to use fast directory switching
 *
 * @return YES if set, NO otherwise
 */
- (BOOL)fastSwitching
{
	return [self boolForKey:ENABLE_FAST_SWITCHING_KEY];

}

/*!
 * @brief Returns the index of the last predicate used
 *
 * @return The index of the last predicate used
 */
- (int)indexOfLastPredicate
{
	return [[self numberForKey:LAST_PREDICATE] intValue];
}

/*!
 * @brief Sets the index of the last predicate
 *
 * @param index The index of the last predicate used
 */
- (void)setIndexOfLastPredicate:(int)index
{
	[options setObject:[NSNumber numberWithInt:index] forKey:LAST_PREDICATE];
	/*Save our settings*/
	[self writeSettings];
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

	if( row > 3 && [self boolForKey:[keys objectAtIndex:row]])
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
    // This is called when the user changed a setting

	/*Check for populate show data*/
	if(row==0)
	{
		SapphireFileDataImporter *importer = [[SapphireFileDataImporter alloc] init];
		SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaDataCollection:metaCollection importer:importer];
		[[self stack] pushController:menu];
		[menu release];
		[importer release];
	}
	/*Check for import of TV data*/
	else if(row == 1)
	{
		SapphireTVShowImporter *importer = [[SapphireTVShowImporter alloc] initWithSavedSetting:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tvdata.plist"]];
		SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaDataCollection:metaCollection importer:importer];
		[[self stack] pushController:menu];
		[menu release];
		[importer release];
	}
	else if(row == 2)
	{
		SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] collection:metaCollection];
		[colSettings setGettingSelector:@selector(hideCollection:)];
		[colSettings setSettingSelector:@selector(setHide:forCollection:)];
		[colSettings setListTitle:BRLocalizedString(@"Hide Collections", @"Hide Collections Menu Title")] ;
		[[self stack] pushController:colSettings];
		[colSettings release];
	}
	else if(row == 3)
	{
		SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] collection:metaCollection];
		[colSettings setGettingSelector:@selector(skipCollection:)];
		[colSettings setSettingSelector:@selector(setSkip:forCollection:)];
		[colSettings setListTitle:BRLocalizedString(@"Skip Collections", @"Skip Collections Menu Title")] ;
		[[self stack] pushController:colSettings];
		[colSettings release];
	}
	/*Change setting*/
	else
	{
		NSString *key = [keys objectAtIndex:row];
		BOOL setting = [self boolForKey:key];
		[options setObject:[NSNumber numberWithBool:!setting] forKey:key];
	}

	/*Save our settings*/
	[self writeSettings];

	/*Redraw*/
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

