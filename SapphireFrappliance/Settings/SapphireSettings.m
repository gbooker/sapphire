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
#import "SapphireFileMetaData.h"
#import "SapphireCollectionDirectory.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireMetaDataSupport.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "NSString-Extensions.h"
#import "NSFileManager-Extensions.h"

static SapphireSettings *sharedInstance = nil;

@implementation SapphireSettings

NSString *HIDE_FAVORITE_KEY			= @"HideFavorites";
NSString *HIDE_TOP_SHOWS_KEY		= @"HideTopShows";
NSString *HIDE_UNWATCHED_KEY		= @"HideUnwatched";
NSString *HIDE_SPOILERS_KEY			= @"HideSpoilers";
NSString *HIDE_AUDIO_KEY			= @"HideAudio";
NSString *HIDE_VIDEO_KEY			= @"HideVideo";
NSString *HIDE_POSTER_CHOOSER_KEY	= @"PosterChooserOptOut";
NSString *HIDE_UI_QUIT_KEY			= @"HideUIQuit";
NSString *ENABLE_FAST_SWITCHING_KEY = @"EnableFastSwitching";
NSString *USE_AC3_PASSTHROUGH		= @"EnableAC3Passthrough";
NSString *ENABLE_DIR_LOOKUP			= @"EnableDirLookup";
NSString *ENABLE_AUTO_SELECTION		= @"EnableAutoSelection";
NSString *DISABLE_ANON_KEY			= @"DisableAnonymousReporting";
NSString *LAST_PREDICATE			= @"LastPredicate";

NSString *SETTING_NAME					= @"Name";
NSString *SETTING_DESCRIPTION			= @"Description";
NSString *SETTING_KEY					= @"Key";
NSString *SETTING_GEM					= @"Gem";
NSString *SETTING_COMMAND				= @"Command";

typedef enum {
	COMMAND_NONE,
	COMMAND_IMPORT_FILE_DATA,
	COMMAND_IMPORT_TV_DATA,
	COMMAND_IMPORT_MOVIE_DATA,
	COMMAND_IMPORT_HIDE_POSTER_CHOOSER,
	COMMAND_IMPORT_USE_DIR_NAME,
	COMMAND_IMPORT_HIDE_ALL_CHOOSERS,
	
	COMMAND_COLLECTIONS_HIDE,
	COMMAND_COLLECTIONS_DONT_IMPORT,
	COMMAND_COLLECTIONS_DELETE,
	
	COMMAND_FILTERS_SKIP_FAVORITE,
	COMMAND_FILTERS_SKIP_UNWATCHED,
	
	COMMAND_METADATA_HIDE_SPOILERS,
	COMMAND_METADATA_HIDE_AUDIO,
	COMMAND_METADATA_HIDE_VIDEO,
	
	COMMAND_AUDIO_ENABLE_AC3,
	
	COMMAND_GENERAL_HIDE_UI_QUIT,
	COMMAND_GENERAL_FAST_DIRECTORY_SWITCHING,
	COMMAND_GENERAL_DONT_ANON_REPORT,
} SettingsCommand;

+ (SapphireSettings *)sharedSettings
{
	return sharedInstance;
}

+ (void)relinquishSettings
{
	[sharedInstance release];
	sharedInstance = nil;
}

- (id) initWithScene: (BRRenderScene *) scene settingsPath:(NSString *)dictionaryPath context:(NSManagedObjectContext *)context;
{
	if(sharedInstance != nil)
		return sharedInstance;
	
	self = [super initWithScene:scene];
	
	lastCommand = COMMAND_NONE;
	/*Setup display*/
	moc = [context retain];
	
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	settings = [[NSArray alloc] initWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Populate File Data", @"Populate File Data menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to examine all files, and remember the file size, length and other information that can be gathered from the file itself.", @"Populate File Data description"), SETTING_DESCRIPTION,
			[theme gem:IMPORT_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_FILE_DATA], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fetch TV Show Data", @"Fetch TV Show Data menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that for every TV episode, gather more information about this episode from the internet.", @"Fetch TV Show Data description"), SETTING_DESCRIPTION,
			[theme gem:TVR_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_TV_DATA], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fetch Movie Data", @"Fetch Movie Data menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that for every Movie, gather more information from the internet.", @"Fetch Movie Data description"), SETTING_DESCRIPTION,
			[theme gem:IMDB_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_MOVIE_DATA], SETTING_COMMAND,
			nil],
/*		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Choose Movie Posters", @"Start Poster Chooser menu item"), SETTING_NAME,
			BRLocalizedString(@"Choose Movie Posters", @"Start Poster Chooser description"), SETTING_DESCRIPTION,
			[theme gem:GREEN_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_MOVIE_POSTERS], SETTING_COMMAND,
			nil],*/
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Collections", @"Hide Collections menu item"), SETTING_NAME,
			BRLocalizedString(@"Allows the user to specify which collections should be hidden from Sapphire's main menu.", @"Hide Collections description"), SETTING_DESCRIPTION,
			[theme gem:FILE_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_COLLECTIONS_HIDE], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Don't Import Collections", @"Don't Import Collections menu item"), SETTING_NAME,
			BRLocalizedString(@"Allows the user to specify which collections should be skipped when importing meta data.", @"Don't Import Collections description"), SETTING_DESCRIPTION,
			[theme gem:FILE_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_COLLECTIONS_DONT_IMPORT], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Delete Collections", @"Delete Collections menu item"), SETTING_NAME,
			BRLocalizedString(@"Allows the user to specify which collections should be delete along with its data.  Use this for collections which will never be used again.", @"Delete Collections description"), SETTING_DESCRIPTION,
			[theme gem:FILE_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_COLLECTIONS_DELETE], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Favorite Shows\" filter", @"Skip Favorite shows menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that when changing filter settings, skip over the favorite shows filter.", @"Skip Favorite shows description"), SETTING_DESCRIPTION,
			HIDE_FAVORITE_KEY, SETTING_KEY,
			[theme gem:YELLOW_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_FILTERS_SKIP_FAVORITE], SETTING_COMMAND,
			nil],
/*		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Top Shows\" filter", @"Skip Top shows menu item"), SETTING_NAME,
			BRLocalizedString(@"Skip \"Top Shows\" filter", @"Skip Top shows description"), SETTING_DESCRIPTION,
			HIDE_TOP_SHOWS_KEY, SETTING_KEY,
			[theme gem:GREEN_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_FILTERS_SKIP_TOP_SHOWS], SETTING_COMMAND,
			nil],*/
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Unwatched Shows\" filter", @"Skip Unwatched shows menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that when changing filter settings, skip over the unwatched shows filter.", @"Skip Unwatched shows description"),  SETTING_DESCRIPTION,
			HIDE_UNWATCHED_KEY, SETTING_KEY,
			[theme gem:BLUE_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_FILTERS_SKIP_UNWATCHED], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Show Spoilers", @"Hide show summary menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to disable the display of the show's synopsis.", @"Hide show summary description"), SETTING_DESCRIPTION,
			HIDE_SPOILERS_KEY, SETTING_KEY,
			[theme gem:NOTE_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_METADATA_HIDE_SPOILERS], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Audio Info", @"Hide perian audio info menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to disable the display of audio codec and sample rate information.", @"Hide perian audio info description"), SETTING_DESCRIPTION,
			HIDE_AUDIO_KEY, SETTING_KEY,
			[theme gem:AUDIO_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_METADATA_HIDE_AUDIO], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Video Info", @"Hide perian video info menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to disable the display of video codec, resolution, and color depth information.", @"Hide perian video info description"), SETTING_DESCRIPTION,
			HIDE_VIDEO_KEY, SETTING_KEY,
			[theme gem:VIDEO_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_METADATA_HIDE_VIDEO], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Poster Chooser", @"Hide poster chooser menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to automatically choose posters for movies instead of asking the user to choose one.", @"Hide poster chooser description"), SETTING_DESCRIPTION,
			HIDE_POSTER_CHOOSER_KEY, SETTING_KEY,
			[theme gem:IMPORT_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_HIDE_POSTER_CHOOSER], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide UI Quit", @"Hide the ui quitter menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to hide the main menu element forcing FrontRow to quit.", @"Hide the ui quitter description"), SETTING_DESCRIPTION,
			HIDE_UI_QUIT_KEY, SETTING_KEY,
			[theme gem:FRONTROW_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_GENERAL_HIDE_UI_QUIT], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fast Directory Switching", @"Don't rescan directories upon entry and used cached data"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that when using a filter, use the cached data to setup directories rather than scanning the directories themselves for new files.", @"Fast Directory Switching description"), SETTING_DESCRIPTION,
			ENABLE_FAST_SWITCHING_KEY, SETTING_KEY,
			[theme gem:FAST_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_GENERAL_FAST_DIRECTORY_SWITCHING], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Enable AC3 Passthrough", @"Enable AC3 Passthrough menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that you have an AC3 decoder and to enable passthrough of the full audio information to the decoder. This is how you get 5.1 and DTS output.", @"Enable AC3 Passthrough description"), SETTING_DESCRIPTION,
			USE_AC3_PASSTHROUGH, SETTING_KEY,
			[theme gem:AC3_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_AUDIO_ENABLE_AC3], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Use Directory Lookup", @"Use directory names instead of filenames for movie lookup"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire that you want to use directory names instead of file names for identifying movies.", @"Enable Directory lookup description"), SETTING_DESCRIPTION,
			ENABLE_DIR_LOOKUP, SETTING_KEY,
			[theme gem:IMDB_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_USE_DIR_NAME], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Auto-Select Movies/Shows", @"Hide movie/show chooser menu item"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire skip the TV Show and Movie choosers when importing and make selections automatically.", @"Enable movie/show chooser description"), SETTING_DESCRIPTION,
			ENABLE_AUTO_SELECTION, SETTING_KEY,
			[theme gem:IMPORT_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_IMPORT_HIDE_ALL_CHOOSERS], SETTING_COMMAND,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Disable Anonymous Reporting", @"Disable the anonymous reporting for aid in future features"), SETTING_NAME,
			BRLocalizedString(@"Tells Sapphire to not report any anonymous information on how you use Sapphire. Anonymous reporting enables us to improve the plugin for future use.", @"Disable the anonymous reporting description"), SETTING_DESCRIPTION,
			DISABLE_ANON_KEY, SETTING_KEY,
			[theme gem:REPORT_GEM_KEY], SETTING_GEM,
			[NSNumber numberWithInt:COMMAND_GENERAL_DONT_ANON_REPORT], SETTING_COMMAND,
			nil],
		nil];
	
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
		[NSNumber numberWithBool:NO], ENABLE_DIR_LOOKUP,
		[NSNumber numberWithBool:NO], ENABLE_AUTO_SELECTION,
		[NSNumber numberWithBool:NO], DISABLE_ANON_KEY,
		[NSNumber numberWithInt:NSNotFound], LAST_PREDICATE,
		nil];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	/*display*/
	BRListControl *list = [self list];
	[list setDatasource:self];
	[SapphireFrontRowCompat addDividerAtIndex:6 toList:list];
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
	[settings release];
	[options release];
	[path release];
	[defaults release];
	[moc release];
	[displayOnlyPlot release];
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

- (BOOL)dirLookup
{
	return [self boolForKey:ENABLE_DIR_LOOKUP];
}

- (BOOL)autoSelection
{
	return [self boolForKey:ENABLE_AUTO_SELECTION];
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

- (void)setDisplayOnlyPlotUntil:(NSDate *)plotOnlyTime
{
	[displayOnlyPlot release];
	displayOnlyPlot = [plotOnlyTime retain];
}

- (BOOL)displayOnlyPlot
{
	return [displayOnlyPlot compare:[NSDate date]] == NSOrderedDescending;
}

- (void)wasExhumed
{
    // handle being revealed when the user presses Menu
	
	if(lastCommand == COMMAND_COLLECTIONS_DELETE)
	{
		NSArray *collections = [SapphireCollectionDirectory allCollectionsInContext:moc];
		NSEnumerator *colEnum = [collections objectEnumerator];
		SapphireCollectionDirectory *collection;
		BOOL change = NO;
		while((collection = [colEnum nextObject]) != nil)
		{
			if([collection deleteValue])
			{
				change = YES;
				SapphireDirectoryMetaData *dir = [collection directory];
				[moc deleteObject:dir];
			}
		}
		if(change)
			[SapphireMetaDataSupport save:moc];
	}
    
    // always call super
    [super wasExhumed];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	return [settings count];
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
/*
    // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
    // return that object, it will be used to display the list item.
    return ( nil );
*/
	if( row >= [settings count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil;
	NSDictionary *setting = [settings objectAtIndex:row];
	NSString *name = [setting objectForKey:SETTING_NAME];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];

	NSString *key = [setting objectForKey:SETTING_KEY];
	if(key != nil && [self boolForKey:key])
	{
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	}
	[SapphireFrontRowCompat setRightIcon:[setting objectForKey:SETTING_GEM] forMenu:result];

	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
	return result;
}

- (NSString *) titleForRow: (long) row
{

	if (row >= [settings count])
		return nil;
	
	NSString *result = [[settings objectAtIndex:row] objectForKey:SETTING_NAME];
	return result;
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
	NSDictionary *setting = [settings objectAtIndex:row];

	lastCommand = [[setting objectForKey:SETTING_COMMAND] intValue];
	switch (lastCommand) {
		case COMMAND_IMPORT_FILE_DATA:
		{
			SapphireAllFileDataImporter *importer = [[SapphireAllFileDataImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
		case COMMAND_IMPORT_TV_DATA:
		{
			SapphireTVShowImporter *importer = [[SapphireTVShowImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
		case COMMAND_IMPORT_MOVIE_DATA:
		{
			SapphireMovieImporter *importer = [[SapphireMovieImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
/*		case COMMAND_IMPORT_MOVIE_POSTERS:
		{
			SapphirePosterBrowse *chooser = [[SapphirePosterChooser alloc] initWithScene:[self scene] metaDataPath:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"movieData.plist"]];
			[[self stack] pushController:chooser];
			[chooser release];
			break;
		}*/
		case COMMAND_COLLECTIONS_HIDE:
		{
			SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] context:moc];
			[colSettings setGettingSelector:@selector(hiddenValue)];
			[colSettings setSettingSelector:@selector(setHiddenValue:)];
			[colSettings setListTitle:BRLocalizedString(@"Hide Collections", @"Hide Collections Menu Title")] ;
			[[self stack] pushController:colSettings];
			[colSettings release];
			break;
		}
		case COMMAND_COLLECTIONS_DONT_IMPORT:
		{
			SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] context:moc];
			[colSettings setGettingSelector:@selector(skipValue)];
			[colSettings setSettingSelector:@selector(setSkipValue:)];
			[colSettings setListTitle:BRLocalizedString(@"Skip Collections", @"Skip Collections Menu Title")] ;
			[[self stack] pushController:colSettings];
			[colSettings release];
			break;
		}
		case COMMAND_COLLECTIONS_DELETE:
		{
			SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] context:moc];
			[colSettings setGettingSelector:@selector(deleteValue)];
			[colSettings setSettingSelector:@selector(setDeleteValue:)];
			[colSettings setListTitle:BRLocalizedString(@"Delete Collections", @"Delete Collections Menu Title")];
			[[self stack] pushController:colSettings];
			[colSettings release];
			break;
		}
		default:
		{
			NSString *key = [setting objectForKey:SETTING_KEY];
			if(key == nil)
				break;
			BOOL setting = [self boolForKey:key];
			[options setObject:[NSNumber numberWithBool:!setting] forKey:key];
		}
	}

	/*Save our settings*/
	[self writeSettings];

	/*Redraw*/
	[[self list] reload] ;
	[SapphireFrontRowCompat renderScene:[self scene]];

}

- (id<BRMediaPreviewController>) previewControlForItem: (long) row
{
	return [self previewControllerForItem:row];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
	if(item >= [settings count])
		return nil;
	
	NSDictionary *setting = [settings objectAtIndex:item];
	
	/* Get setting name & kill the gem cushion  */
	NSString *settingName = [[setting objectForKey:SETTING_NAME] substringFromIndex:2];
	NSString *settingDescription=[setting objectForKey:SETTING_DESCRIPTION];
	/* Construct a gerneric metadata asset for display */
	NSMutableDictionary *settingMeta=[[NSMutableDictionary alloc] init];
	[settingMeta setObject:settingName forKey:META_TITLE_KEY];
	[settingMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
	[settingMeta setObject:settingDescription forKey:META_DESCRIPTION_KEY];
	SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
	[preview setUtilityData:settingMeta];
	[settingMeta release];
	[preview setShowsMetadataImmediately:YES];
	/*And go*/
	return [preview autorelease];
}

@end

