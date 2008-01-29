/*
 * SapphireSettings.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 23, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */


#import <BackRow/BackRow.h>
#import "SapphireApplianceController.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireMediaPreview.h"
#import "SapphireAllFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireMovieImporter.h"
#import "SapphirePosterChooser.h"
#import "SapphireCollectionSettings.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

static SapphireSettings *sharedInstance = nil;

@interface SapphireSettings(private)
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
@end

@implementation SapphireSettings

#define	HIDE_FAVORITE_KEY			@"HideFavorites"
#define	HIDE_TOP_SHOWS_KEY			@"HideTopShows"
#define	HIDE_UNWATCHED_KEY			@"HideUnwatched"
#define	HIDE_SPOILERS_KEY			@"HideSpoilers"
#define	HIDE_AUDIO_KEY				@"HideAudio"
#define	HIDE_VIDEO_KEY				@"HideVideo"
#define HIDE_POSTER_CHOOSER_KEY		@"PosterChooserOptOut"
#define HIDE_UI_QUIT_KEY			@"HideUIQuit"
#define	ENABLE_FAST_SWITCHING_KEY	@"EnableFastSwitching"
#define USE_AC3_PASSTHROUGH			@"EnableAC3Passthrough"
#define	DISABLE_ANON_KEY			@"DisableAnonymousReporting"
#define LAST_PREDICATE				@"LastPredicate"

+ (SapphireSettings *)sharedSettings
{
	return sharedInstance;
}

+ (void)relinquishSettings
{
	[sharedInstance release];
	sharedInstance = nil;
}

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath metaDataCollection:(SapphireMetaDataCollection *)collection
{
	if(sharedInstance != nil)
		return sharedInstance;
	
	self = [super initWithScene:scene];
	
	/*Setup display*/
	metaCollection = [collection retain];
	names = [[NSArray alloc] initWithObjects:	BRLocalizedString(@"  Populate File Data", @"Populate File Data menu item"),
												BRLocalizedString(@"  Fetch TV Show Data", @"Fetch TV Show Data menu item"),
												BRLocalizedString(@"  Fetch Movie Data", @"Fetch Movie Data menu item"),
/*												BRLocalizedString(@"  Choose Movie Posters", @"Start Poster Chooser menu item"),*/
												BRLocalizedString(@"  Hide Collections", @"Hide Collections menu item"),
												BRLocalizedString(@"  Don't Import Collections", @"Don't Import Collections menu item"),
												BRLocalizedString(@"  Skip \"Favorite Shows\" filter", @"Skip Favorite shows menu item"),
/*												BRLocalizedString(@"  Skip \"Top Shows\" filter", @"Skip Top shows menu item"),*/
												BRLocalizedString(@"  Skip \"Unwatched Shows\" filter", @"Skip Unwatched shows menu item"), 
												BRLocalizedString(@"  Hide Show Spoilers", @"Hide show summarys menu item"),
												BRLocalizedString(@"  Hide Audio Info", @"Hide perian audio info menu item"),
												BRLocalizedString(@"  Hide Video Info", @"Hide perian video info menu item"),
												BRLocalizedString(@"  Hide Poster Chooser", @"Hide poster chooser menu item"),
												BRLocalizedString(@"  Hide UI Quit", @"Hide the ui quitter menu item"),
												BRLocalizedString(@"  Fast Directory Switching", @"Don't rescan directories upon entry and used cached data"),
												BRLocalizedString(@"  Enable AC3 Passthrough", @"Enable AC3 Passthrough menu item"),
												BRLocalizedString(@"  Disable Anonymous Reporting", @"Disable the anonymous reporting for aid in future features"), nil];
	
	settingDescriptions=[[NSArray alloc] initWithObjects:
												BRLocalizedString(@"tells Sapphire to examine all files, and remember the file size, length and other information that can be gathered from the file itself.", @"Populate File Data description"),
												BRLocalizedString(@"tells Sapphire that for every TV episode, gather more information about this episode from the internet.", @"Fetch TV Show Data description"),
												BRLocalizedString(@"tells Sapphire that for every Movie, gather more information from the internet.", @"Fetch Movie Data description"),
/*												BRLocalizedString(@"Choose Movie Posters", @"Start Poster Chooser description"),*/
												BRLocalizedString(@"allows the user to specify which collections should be hidden from Sapphire's main menu.", @"Hide Collections description"),
												BRLocalizedString(@"allows to user to specify which collections should be skipped when importing meta data.", @"Don't Import Collections description"),
												BRLocalizedString(@"tells Sapphire that when changing filter settings, skip over the favorite shows filter.", @"Skip Favorite shows description"),
/*												BRLocalizedString(@"Skip \"Top Shows\" filter", @"Skip Top shows description"),*/
												BRLocalizedString(@"tells Sapphire that when changing filter settings, skip over the unwatched shows filter.", @"Skip Unwatched shows description"), 
												BRLocalizedString(@"tells Sapphire to disable the display of the show's synopsis.", @"Hide show summarys description"),
												BRLocalizedString(@"tells Sapphire to disable the display of audio codec and sample rate information.", @"Hide perian audio info description"),
												BRLocalizedString(@"tells Sapphire to disable the display of video codec, resolution, and color depth information.", @"Hide perian video info description"),
												BRLocalizedString(@"tells Sapphire to automatically choose posters for movies instead of asking the user to choose one.", @"Hide poster chooser description"),
												BRLocalizedString(@"tells Sapphire to hide the main menu element forcing frontrow to quit.", @"Hide the ui quitter description"),
												BRLocalizedString(@"tells Sapphire that when using a filter, use the cached data to setup directories rather than scanning the directories themselves for new files.", @"Fast Directory Switching description"),
												BRLocalizedString(@"tells Sapphire that you have an AC3 decoder and to enable passthrough of the full audio information to the decoder. This is how you get 5.1 output.", @"Enable AC3 Passthrough description"),
												BRLocalizedString(@"tells Sapphire to not report any anonymous information on how you use Sapphire. Anonymous reporting enables us to improve the plugin for future use.", @"Disable the anonymous reporting description"), nil];
		
	keys = [[NSArray alloc] initWithObjects:		@"",
													@"",
													@"",
												/*	@"",*/
													@"",
													@"",
													HIDE_FAVORITE_KEY, 
													/*HIDE_TOP_SHOWS_KEY, */
													HIDE_UNWATCHED_KEY,  
													HIDE_SPOILERS_KEY,
													HIDE_AUDIO_KEY,
													HIDE_VIDEO_KEY,
													HIDE_POSTER_CHOOSER_KEY,
													HIDE_UI_QUIT_KEY,
													ENABLE_FAST_SWITCHING_KEY,
													USE_AC3_PASSTHROUGH,
													DISABLE_ANON_KEY, nil];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	gems = [[NSArray alloc] initWithObjects:	[theme gem:IMPORT_GEM_KEY],
												[theme gem:TVR_GEM_KEY],
												[theme gem:IMDB_GEM_KEY],
												/*[theme gem:GREEN_GEM_KEY],*/
												[theme gem:FILE_GEM_KEY],
												[theme gem:FILE_GEM_KEY],
												[theme gem:YELLOW_GEM_KEY],
												/*[theme gem:GREEN_GEM_KEY],*/
												[theme gem:BLUE_GEM_KEY],
												[theme gem:NOTE_GEM_KEY],
												[theme gem:AUDIO_GEM_KEY],
												[theme gem:VIDEO_GEM_KEY],
												[theme gem:IMPORT_GEM_KEY],
												[theme gem:FRONTROW_GEM_KEY],
												[theme gem:FAST_GEM_KEY],
												[theme gem:AC3_GEM_KEY],
												[theme gem:REPORT_GEM_KEY], nil];		
	
	path = [dictionaryPath retain];
	options = [[NSDictionary dictionaryWithContentsOfFile:dictionaryPath] mutableCopy];
	/*Set deaults*/
	defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], HIDE_FAVORITE_KEY,
		[NSNumber numberWithBool:YES], HIDE_TOP_SHOWS_KEY,
		[NSNumber numberWithBool:NO], HIDE_UNWATCHED_KEY,
		[NSNumber numberWithBool:NO], HIDE_SPOILERS_KEY,
		[NSNumber numberWithBool:NO], HIDE_AUDIO_KEY,
		[NSNumber numberWithBool:NO], HIDE_VIDEO_KEY,
		[NSNumber numberWithBool:NO], HIDE_POSTER_CHOOSER_KEY,
		[NSNumber numberWithBool:YES], HIDE_UI_QUIT_KEY,
		[NSNumber numberWithBool:YES], ENABLE_FAST_SWITCHING_KEY,
		[NSNumber numberWithBool:NO], USE_AC3_PASSTHROUGH,
		[NSNumber numberWithBool:NO], DISABLE_ANON_KEY,
		[NSNumber numberWithInt:NSNotFound], LAST_PREDICATE,
		nil];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	/*display*/
	BRListControl *list = [self list];
	[list setDatasource:self];
	[SapphireFrontRowCompat addDividerAtIndex:5 toList:list];
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

- (BOOL)displayUnwatched
{
	return ![self boolForKey:HIDE_UNWATCHED_KEY];
}

- (BOOL)displayFavorites
{
	return ![self boolForKey:HIDE_FAVORITE_KEY];
}

- (BOOL)displayTopShows
{
	return ![self boolForKey:HIDE_TOP_SHOWS_KEY];
}

- (BOOL)displaySpoilers
{
	return ![self boolForKey:HIDE_SPOILERS_KEY];
}

- (BOOL)displayAudio
{
	return ![self boolForKey:HIDE_AUDIO_KEY];
}

- (BOOL)displayVideo
{
	return ![self boolForKey:HIDE_VIDEO_KEY];
}

- (BOOL)displayPosterChooser
{
	return ![self boolForKey:HIDE_POSTER_CHOOSER_KEY];
}

- (BOOL)disableUIQuit
{
	return [self boolForKey:HIDE_UI_QUIT_KEY];
}

- (BOOL)disableAnonymousReporting;
{
	return [self boolForKey:DISABLE_ANON_KEY];
}

- (BOOL)useAC3Passthrough
{
	return [self boolForKey:USE_AC3_PASSTHROUGH];
}

- (BOOL)fastSwitching
{
	return [self boolForKey:ENABLE_FAST_SWITCHING_KEY];

}

- (int)indexOfLastPredicate
{
	return [[self numberForKey:LAST_PREDICATE] intValue];
}

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
    // The user chose an option and this controller is no longer on screen
    
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
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];

	if( row > 4 && [self boolForKey:[keys objectAtIndex:row]])
	{
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	}
	[SapphireFrontRowCompat setRightIcon:[gems objectAtIndex:row] forMenu:result];

	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{

	if ( row >= [ names count] ) return ( nil );
	
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
		SapphireAllFileDataImporter *importer = [[SapphireAllFileDataImporter alloc] init];
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
	/*Start Importing Movie Data*/
	else if(row == 2)
	{
		SapphireMovieImporter *importer = [[SapphireMovieImporter alloc] initWithSavedSetting:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"movieData.plist"]];
		SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaDataCollection:metaCollection importer:importer];
		[[self stack] pushController:menu];
		[menu release];
		[importer release];
	}
	/*
	 Start Movie Poster Chooser
	else if(row == 3)
	{
	//	SapphirePosterBrowse *chooser = [[SapphirePosterChooser alloc] initWithScene:[self scene] metaDataPath:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"movieData.plist"]];
	//	[[self stack] pushController:chooser];
	//	[chooser release];
	}
	*/
	else if(row == 3)
	{
		SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] collection:metaCollection];
		[colSettings setGettingSelector:@selector(hideCollection:)];
		[colSettings setSettingSelector:@selector(setHide:forCollection:)];
		[colSettings setListTitle:BRLocalizedString(@"Hide Collections", @"Hide Collections Menu Title")] ;
		[[self stack] pushController:colSettings];
		[colSettings release];
	}
	else if(row == 4)
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
	[SapphireFrontRowCompat renderScene:[self scene]];

}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(item >= [names count])
		return nil;
	else
	{
		/* Get setting name & kill the gem cushion  */
		NSString *settingName = [[names objectAtIndex:item]substringFromIndex:2];
		NSString *settingDescription=[settingDescriptions objectAtIndex:item];
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *settingMeta=[[NSMutableDictionary alloc] init];
		[settingMeta setObject:settingName forKey:META_TITLE_KEY];
		[settingMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[settingMeta setObject:settingDescription forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:settingMeta];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
	
    return ( nil );
}

@end

