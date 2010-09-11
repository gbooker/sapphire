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
#include <unistd.h>
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
#import "SapphireTVShow.h"
#import "SapphireConfirmPrompt.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireErrorDisplayController.h"
#import "SapphireWaitDisplay.h"

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "NSString-Extensions.h"
#import "NSFileManager-Extensions.h"

static SapphireSettings *sharedInstance = nil;

@implementation SapphireSettings

NSString *SettingHideFavorite		= @"HideFavorites";
NSString *SettingHideTopShows		= @"HideTopShows";
NSString *SettingHideUnwatched		= @"HideUnwatched";
NSString *SettingHideSpoilers		= @"HideSpoilers";
NSString *SettingHideAudio			= @"HideAudio";
NSString *SettingHideVideo			= @"HideVideo";
NSString *SettingHidePosterChooser	= @"PosterChooserOptOut";
NSString *SettingHideUIQuit			= @"HideUIQuit";
NSString *SettingEnableFastSwitch	= @"EnableFastSwitching";
NSString *SettingAC3Passthrough		= @"EnableAC3Passthrough";
NSString *SettingDirLookup			= @"EnableDirLookup";
NSString *SettingEnableAutoSelect	= @"EnableAutoSelection";
NSString *SettingDisableAnonReport	= @"DisableAnonymousReporting";
NSString *SettingLastPredicate		= @"LastPredicate";

NSString *SettingLogGeneralLevel	= @"GeneralLogLevel";
NSString *SettingLogImportLevel		= @"ImportLogLevel";
NSString *SettingLogFileLevel		= @"FileLogLevel";
NSString *SettingLogPlaybackLevel	= @"PlaybackLogLevel";
NSString *SettingLogMetadataLevel	= @"MetadataLogLevel";

NSString *SettingListName			= @"Name";
NSString *SettingListDescription	= @"Description";
NSString *SettingListKey			= @"Key";
NSString *SettingListGem			= @"Gem";
NSString *SettingListCommand		= @"Command";

typedef enum {
	SettingsCommandNone,
	SettingsCommandImportFileData,
	SettingsCommandImportTVData,
	SettingsCommandImportMovieData,
	SettingsCommandImportTVAutosortCalculate,
	SettingsCommandImportUpdateScrapers,
	SettingsCommandImportHidePosterChooser,
	SettingsCommandImportUseDirName,
	SettingsCommandImportHideAllChoosers,
	
	SettingsCommandCollectionsHide,
	SettingsCommandCollectionsDontImport,
	SettingsCommandCollectionsDelete,
	
	SettingsCommandFiltersSkipFavorite,
	SettingsCommandFiltersSkipUnwatched,
	
	SettingsCommandMetadataHideSpoilers,
	SettingsCommandMetadataHideAudio,
	SettingsCommandMetadataHideVideo,
	
	SettingsCommandAudioEnableAC3,
	
	SettingsCommandGeneralHideUIQuit,
	SettingsCommandGeneralFastDirectorySwitching,
	SettingsCommandGeneralDontAnonReport,
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
	{
		[self autorelease];
		return [sharedInstance retain];
	}
	
	self = [super initWithScene:scene];
	
	lastCommand = SettingsCommandNone;
	/*Setup display*/
	moc = [context retain];
	
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	settings = [[NSArray alloc] initWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Populate File Data", @"Populate File Data menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to examine all files, and remember the file size, length and other information that can be gathered from the file itself.", @"Populate File Data description"), SettingListDescription,
			[theme gem:IMPORT_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportFileData], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fetch TV Show Data", @"Fetch TV Show Data menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that for every TV episode, gather more information about this episode from the internet.", @"Fetch TV Show Data description"), SettingListDescription,
			[theme gem:TVR_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportTVData], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fetch Movie Data", @"Fetch Movie Data menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that for every Movie, gather more information from the internet.", @"Fetch Movie Data description"), SettingListDescription,
			[theme gem:IMDB_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportMovieData], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Calculate TV Directories", @"Calculate TV Dirs menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to calculate directories where each TV show is stored.", @"Calculate TV Dirs description"), SettingListDescription,
			[theme gem:TVR_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportTVAutosortCalculate], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Update Scrapers", @"Update Scrapers menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to download latest scrapers from the website.", @"Update Scrapers description"), SettingListDescription,
			[theme gem:CONE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportUpdateScrapers], SettingListCommand,
			nil],
/*		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Choose Movie Posters", @"Start Poster Chooser menu item"), SettingListName,
			BRLocalizedString(@"Choose Movie Posters", @"Start Poster Chooser description"), SettingListDescription,
			[theme gem:GREEN_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:COMMAND_IMPORT_MOVIE_POSTERS], SettingListCommand,
			nil],*/
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Collections", @"Hide Collections menu item"), SettingListName,
			BRLocalizedString(@"Allows the user to specify which collections should be hidden from Sapphire's main menu.", @"Hide Collections description"), SettingListDescription,
			[theme gem:FILE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandCollectionsHide], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Don't Import Collections", @"Don't Import Collections menu item"), SettingListName,
			BRLocalizedString(@"Allows the user to specify which collections should be skipped when importing meta data.", @"Don't Import Collections description"), SettingListDescription,
			[theme gem:FILE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandCollectionsDontImport], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Delete Collections", @"Delete Collections menu item"), SettingListName,
			BRLocalizedString(@"Allows the user to specify which collections should be delete along with its data.  Use this for collections which will never be used again.", @"Delete Collections description"), SettingListDescription,
			[theme gem:FILE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandCollectionsDelete], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Favorite Shows\" filter", @"Skip Favorite shows menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that when changing filter settings, skip over the favorite shows filter.", @"Skip Favorite shows description"), SettingListDescription,
			SettingHideFavorite, SettingListKey,
			[theme gem:YELLOW_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandFiltersSkipFavorite], SettingListCommand,
			nil],
/*		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Top Shows\" filter", @"Skip Top shows menu item"), SettingListName,
			BRLocalizedString(@"Skip \"Top Shows\" filter", @"Skip Top shows description"), SettingListDescription,
			SettingHideTopShows, SettingListKey,
			[theme gem:GREEN_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:COMMAND_FILTERS_SKIP_TOP_SHOWS], SettingListCommand,
			nil],*/
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Skip \"Unwatched Shows\" filter", @"Skip Unwatched shows menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that when changing filter settings, skip over the unwatched shows filter.", @"Skip Unwatched shows description"),  SettingListDescription,
			SettingHideUnwatched, SettingListKey,
			[theme gem:BLUE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandFiltersSkipUnwatched], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Show Spoilers", @"Hide show summary menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to disable the display of the show's synopsis.", @"Hide show summary description"), SettingListDescription,
			SettingHideSpoilers, SettingListKey,
			[theme gem:NOTE_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandMetadataHideSpoilers], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Audio Info", @"Hide perian audio info menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to disable the display of audio codec and sample rate information.", @"Hide perian audio info description"), SettingListDescription,
			SettingHideAudio, SettingListKey,
			[theme gem:AUDIO_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandMetadataHideAudio], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Video Info", @"Hide perian video info menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to disable the display of video codec, resolution, and color depth information.", @"Hide perian video info description"), SettingListDescription,
			SettingHideVideo, SettingListKey,
			[theme gem:VIDEO_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandMetadataHideVideo], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide Poster Chooser", @"Hide poster chooser menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to automatically choose posters for movies instead of asking the user to choose one.", @"Hide poster chooser description"), SettingListDescription,
			SettingHidePosterChooser, SettingListKey,
			[theme gem:IMPORT_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportHidePosterChooser], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Hide UI Quit", @"Hide the ui quitter menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to hide the main menu element forcing FrontRow to quit.", @"Hide the ui quitter description"), SettingListDescription,
			SettingHideUIQuit, SettingListKey,
			[theme gem:FRONTROW_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandGeneralHideUIQuit], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Fast Directory Switching", @"Don't rescan directories upon entry and used cached data"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that when using a filter, use the cached data to setup directories rather than scanning the directories themselves for new files.", @"Fast Directory Switching description"), SettingListDescription,
			SettingEnableFastSwitch, SettingListKey,
			[theme gem:FAST_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandGeneralFastDirectorySwitching], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Enable AC3 Passthrough", @"Enable AC3 Passthrough menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that you have an AC3 decoder and to enable passthrough of the full audio information to the decoder. This is how you get 5.1 and DTS output.", @"Enable AC3 Passthrough description"), SettingListDescription,
			SettingAC3Passthrough, SettingListKey,
			[theme gem:AC3_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandAudioEnableAC3], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Use Directory Lookup", @"Use directory names instead of filenames for movie lookup"), SettingListName,
			BRLocalizedString(@"Tells Sapphire that you want to use directory names instead of file names for identifying movies.", @"Enable Directory lookup description"), SettingListDescription,
			SettingDirLookup, SettingListKey,
			[theme gem:IMDB_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportUseDirName], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Auto-Select Movies/Shows", @"Hide movie/show chooser menu item"), SettingListName,
			BRLocalizedString(@"Tells Sapphire skip the TV Show and Movie choosers when importing and make selections automatically.", @"Enable movie/show chooser description"), SettingListDescription,
			SettingEnableAutoSelect, SettingListKey,
			[theme gem:IMPORT_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandImportHideAllChoosers], SettingListCommand,
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			BRLocalizedString(@"  Disable Anonymous Reporting", @"Disable the anonymous reporting for aid in future features"), SettingListName,
			BRLocalizedString(@"Tells Sapphire to not report any anonymous information on how you use Sapphire. Anonymous reporting enables us to improve the plugin for future use.", @"Disable the anonymous reporting description"), SettingListDescription,
			SettingDisableAnonReport, SettingListKey,
			[theme gem:REPORT_GEM_KEY], SettingListGem,
			[NSNumber numberWithInt:SettingsCommandGeneralDontAnonReport], SettingListCommand,
			nil],
		nil];
	
	path = [dictionaryPath retain];
	options = [[NSDictionary dictionaryWithContentsOfFile:dictionaryPath] mutableCopy];
	/*Set deaults*/
	defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithBool:NO], SettingHideFavorite,
		[NSNumber numberWithBool:YES], SettingHideTopShows,
		[NSNumber numberWithBool:NO], SettingHideUnwatched,
		[NSNumber numberWithBool:NO], SettingHideSpoilers,
		[NSNumber numberWithBool:NO], SettingHideAudio,
		[NSNumber numberWithBool:NO], SettingHideVideo,
		[NSNumber numberWithBool:NO], SettingHidePosterChooser,
		[NSNumber numberWithBool:YES], SettingHideUIQuit,
		[NSNumber numberWithBool:YES], SettingEnableFastSwitch,
		[NSNumber numberWithBool:NO], SettingAC3Passthrough,
		[NSNumber numberWithBool:NO], SettingDirLookup,
		[NSNumber numberWithBool:NO], SettingEnableAutoSelect,
		[NSNumber numberWithBool:NO], SettingDisableAnonReport,
		[NSNumber numberWithInt:NSNotFound], SettingLastPredicate,
		[NSNumber numberWithInt:SapphireLogLevelError], SettingLogGeneralLevel,
		[NSNumber numberWithInt:SapphireLogLevelError], SettingLogImportLevel,
		[NSNumber numberWithInt:SapphireLogLevelError], SettingLogFileLevel,
		[NSNumber numberWithInt:SapphireLogLevelError], SettingLogPlaybackLevel,
		[NSNumber numberWithInt:SapphireLogLevelError], SettingLogMetadataLevel,
		nil];
	if(options == nil)
		options = [[NSMutableDictionary alloc] init];

	/*display*/
	BRListControl *list = [self list];
	[list setDatasource:self];
	[SapphireFrontRowCompat addDividerAtIndex:8 toList:list];
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

- (SapphireLogLevel)logLevelForKey:(NSString *)key
{
	/*Check the user's setting*/
	NSNumber *num = [options objectForKey:key];
	SapphireLogLevel value = [num intValue];
	if(num != nil && value > 0 && value < SapphireLogLevelCount)
		return value;
	return [[defaults objectForKey:key] intValue];
}

- (BOOL)displayUnwatched
{
	return ![self boolForKey:SettingHideUnwatched];
}

- (BOOL)displayFavorites
{
	return ![self boolForKey:SettingHideFavorite];
}

- (BOOL)displayTopShows
{
	return ![self boolForKey:SettingHideTopShows];
}

- (BOOL)displaySpoilers
{
	return ![self boolForKey:SettingHideSpoilers];
}

- (BOOL)displayAudio
{
	return ![self boolForKey:SettingHideAudio];
}

- (BOOL)displayVideo
{
	return ![self boolForKey:SettingHideVideo];
}

- (BOOL)displayPosterChooser
{
	return ![self boolForKey:SettingHidePosterChooser];
}

- (BOOL)disableUIQuit
{
	return [self boolForKey:SettingHideUIQuit];
}

- (BOOL)disableAnonymousReporting;
{
	return [self boolForKey:SettingDisableAnonReport];
}

- (BOOL)useAC3Passthrough
{
	return [self boolForKey:SettingAC3Passthrough];
}

- (BOOL)fastSwitching
{
	return [self boolForKey:SettingEnableFastSwitch];

}

- (BOOL)dirLookup
{
	return [self boolForKey:SettingDirLookup];
}

- (BOOL)autoSelection
{
	return [self boolForKey:SettingEnableAutoSelect];
}

- (int)indexOfLastPredicate
{
	return [[self numberForKey:SettingLastPredicate] intValue];
}

- (void)setIndexOfLastPredicate:(int)index
{
	[options setObject:[NSNumber numberWithInt:index] forKey:SettingLastPredicate];
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

- (SapphireLogLevel)generalLogLevel
{
	return [self logLevelForKey:SettingLogGeneralLevel];
}

- (SapphireLogLevel)importLogLevel
{
	return [self logLevelForKey:SettingLogImportLevel];
}

- (SapphireLogLevel)fileLogLevel
{
	return [self logLevelForKey:SettingLogFileLevel];
}

- (SapphireLogLevel)playbackLogLevel
{
	return [self logLevelForKey:SettingLogPlaybackLevel];
}

- (SapphireLogLevel)metadataLogLevel
{
	return [self logLevelForKey:SettingLogMetadataLevel];
}

- (SapphireConfirmPrompt *)nextAutoSortPathConfirm:(NSArray *)shows
{
	int i, count = [shows count];
	SapphireTVShow *show;
	NSString *calcAutoPath = nil;
	NSString *autoPath;
	for(i=0; i<count; i++)
	{
		show = [shows objectAtIndex:i];
		calcAutoPath = [show calculateAutoSortPath];
		autoPath = [show autoSortPath];
		if(autoPath == nil && calcAutoPath == nil)
			continue;
		if(autoPath == nil || calcAutoPath == nil)
			//Only one of them is nil
			break;
		if(![autoPath isEqualToString:calcAutoPath])
			break;
	}
	
	if(i == count)
		return nil;
	
	NSArray *newArray = [shows subarrayWithRange:NSMakeRange(i+1, count-i-1)];
	NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(promptResult:forShow:remaining:)]];
	[invoke setTarget:self];
	[invoke setSelector:@selector(promptResult:forShow:remaining:)];
	[invoke setArgument:&show atIndex:3];
	[invoke setArgument:&newArray atIndex:4];
	[invoke retainArguments];
	
	NSString *question;
	if(calcAutoPath != nil)
		question = [NSString stringWithFormat:BRLocalizedString(@"Do you want to set the show path for %@ to %@?", @"Prompt for setting a show's path, arguments are show name and path"), [show name], calcAutoPath];
	else
		question = [NSString stringWithFormat:BRLocalizedString(@"Do you want to delete the show path for %@?", @"Prompt for deleting a show's path, argument is show name"), [show name]];
	
	SapphireConfirmPrompt *prompt = [[SapphireConfirmPrompt alloc] initWithScene:[self scene] title:BRLocalizedString(@"Show Path", @"Show Path") subtitle:question invocation:invoke];
	return [prompt autorelease];
}

- (BRLayerController *)promptResult:(SapphireConfirmPromptResult)result forShow:(SapphireTVShow *)show remaining:(NSArray *)remain
{
	if(result == SapphireConfirmPromptResultAbort)
		return nil;
	
	if(result == SapphireConfirmPromptResultOK)
	{
		[show setAutoSortPath:[show calculateAutoSortPath]];
		[SapphireMetaDataSupport save:moc];
	}
	
	return [self nextAutoSortPathConfirm:remain];
}

- (BRLayerController *)waitForDownloads
{
	SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
	while([loader loadingURLCount] != 0)
		usleep(100000);
	
	SapphireErrorDisplayController *error = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Restart Needed", @"Restart Needed") longError:BRLocalizedString(@"You must exist Frontrow for new scrapers to take effect", @"You must exist Frontrow for new scrapers to take effect")];
	return [error autorelease];
}

- (void)wasExhumed
{
    // handle being revealed when the user presses Menu
	
	if(lastCommand == SettingsCommandCollectionsDelete)
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
	NSString *name = [setting objectForKey:SettingListName];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];

	NSString *key = [setting objectForKey:SettingListKey];
	if(key != nil && [self boolForKey:key])
	{
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	}
	[SapphireFrontRowCompat setRightIcon:[setting objectForKey:SettingListGem] forMenu:result];

	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
	return result;
}

- (NSString *) titleForRow: (long) row
{

	if (row >= [settings count])
		return nil;
	
	NSString *result = [[settings objectAtIndex:row] objectForKey:SettingListName];
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

	lastCommand = [[setting objectForKey:SettingListCommand] intValue];
	switch (lastCommand) {
		case SettingsCommandImportFileData:
		{
			SapphireAllFileDataImporter *importer = [[SapphireAllFileDataImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
		case SettingsCommandImportTVData:
		{
			SapphireTVShowImporter *importer = [[SapphireTVShowImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
		case SettingsCommandImportMovieData:
		{
			SapphireMovieImporter *importer = [[SapphireMovieImporter alloc] init];
			SapphireImporterDataMenu *menu = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:importer];
			[[self stack] pushController:menu];
			[menu release];
			[importer release];
			break;
		}
		case SettingsCommandImportTVAutosortCalculate:
		{
			NSArray *shows = doFetchRequest(SapphireTVShowName, moc, nil);
			SapphireConfirmPrompt *confirm = [self nextAutoSortPathConfirm:shows];
			if(confirm != nil)
				[[self stack] pushController:confirm];
			else
			{
				SapphireErrorDisplayController *error = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"No Changes", @"No Changes") longError:BRLocalizedString(@"Sapphire didn't detect any changes to show paths", @"Display info for no show path changes detected")];
				[[self stack] pushController:error];
				[error release];
			}
			break;
		}
		case SettingsCommandImportUpdateScrapers:
		{
			SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
			NSFileManager *fm = [NSFileManager defaultManager];
			[fm constructPath:[applicationSupportDir() stringByAppendingPathComponent:@"scrapers/common"]];
			NSArray *loads = [NSArray arrayWithObjects:@"tvrage.xml", @"imdb.xml", @"/common/dtrailer.xml", @"common/imdb.xml", @"common/impa.xml", @"common/movieposterdb.xml", @"common/tmdb.xml", nil];
			NSString *dest = [applicationSupportDir() stringByAppendingPathComponent:@"scrapers"];
			NSEnumerator *loadEnum = [loads objectEnumerator];
			NSString *load;
			while((load = [loadEnum nextObject]) != nil)
				[loader saveDataAtURL:[@"http://appletv.nanopi.net/svn/trunk/SapphireFrappliance/MetaDataImporting/Scrapers/" stringByAppendingString:load] toFile:[dest stringByAppendingPathComponent:load]];
			NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(waitForDownloads)]];
			[invoke setTarget:self];
			[invoke setSelector:@selector(waitForDownloads)];
			SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene:[self scene] title:BRLocalizedString(@"Downloading", @"Downloading") invocation:invoke];
			[[self stack] pushController:wait];
			[wait release];
			break;
		}
/*		case COMMAND_IMPORT_MOVIE_POSTERS:
		{
			SapphirePosterBrowse *chooser = [[SapphirePosterChooser alloc] initWithScene:[self scene] metaDataPath:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"movieData.plist"]];
			[[self stack] pushController:chooser];
			[chooser release];
			break;
		}*/
		case SettingsCommandCollectionsHide:
		{
			SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] context:moc];
			[colSettings setGettingSelector:@selector(hiddenValue)];
			[colSettings setSettingSelector:@selector(setHiddenValue:)];
			[colSettings setListTitle:BRLocalizedString(@"Hide Collections", @"Hide Collections Menu Title")] ;
			[[self stack] pushController:colSettings];
			[colSettings release];
			break;
		}
		case SettingsCommandCollectionsDontImport:
		{
			SapphireCollectionSettings *colSettings = [[SapphireCollectionSettings alloc] initWithScene:[self scene] context:moc];
			[colSettings setGettingSelector:@selector(skipValue)];
			[colSettings setSettingSelector:@selector(setSkipValue:)];
			[colSettings setListTitle:BRLocalizedString(@"Skip Collections", @"Skip Collections Menu Title")] ;
			[[self stack] pushController:colSettings];
			[colSettings release];
			break;
		}
		case SettingsCommandCollectionsDelete:
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
			NSString *key = [setting objectForKey:SettingListKey];
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
	NSString *settingName = [[setting objectForKey:SettingListName] substringFromIndex:2];
	NSString *settingDescription=[setting objectForKey:SettingListDescription];
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

