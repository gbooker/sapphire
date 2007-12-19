/*
 * SapphireApplianceController.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#include <dlfcn.h>
#import "SapphireBrowser.h"
#import "SapphireMetaData.h"
#import "SapphirePredicates.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireTVDirectory.h"
#import "SapphireMovieDirectory.h"

#import "SapphireImporterDataMenu.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireMovieImporter.h"
#import "SapphireAllImporter.h"
#import "SapphireFrontRowCompat.h"
#import "SapphireVirtualDirectoryLoading.h"

#define BROWSER_MENU_ITEM		BRLocalizedString(@"  Browse", @"Browser Menu Item")
#define ALL_IMPORT_MENU_ITEM	BRLocalizedString(@"  Import All Data", @"All Importer Menu Item")
#define SETTINGS_MENU_ITEM		BRLocalizedString(@"  Settings", @"Settings Menu Item")
#define RESET_MENU_ITEM			BRLocalizedString(@"  Reset the thing already", @"UI Quit")

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
	if([SapphireFrontRowCompat usingFrontRow])
	{
		NSString *compatPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Frameworks/CompatClasses.framework"];
		NSBundle *compat = [NSBundle bundleWithPath:compatPath];
		[compat load];
	}
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

+ (void)logException:(NSException *)e
{
	NSMutableString *ret = [NSMutableString stringWithFormat:@"Exception:"];
	if([e respondsToSelector:@selector(backtrace)])
	{
		[ret appendFormat:@"%@\n%@", e, [(BRBacktracingException *)e backtrace]];
		Dl_info info;
		if(dladdr(&predicates, &info))
			[ret appendFormat:@"Sapphire is at 0x%X", info.dli_fbase];
	}
	else
	{
		NSArray *addrs = [SapphireFrontRowCompat callStackReturnAddressesForException:e];
		NSLog(@"Got addrs: %@", addrs);
		int i, count = [addrs count];
		NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
		for(i=0; i<count; i++)
		{
			Dl_info info;
			const void *addr = [[addrs objectAtIndex:i] pointerValue];
			if(dladdr(addr, &info))
				[mapping setObject:[NSString stringWithCString:info.dli_fname] forKey:[NSValue valueWithPointer:info.dli_fbase]];
			[ret appendFormat:@" 0x%X", addr];
		}
		NSEnumerator *mappingEnum = [mapping keyEnumerator];
		NSValue *key = nil;
		while((key = [mappingEnum nextObject]) != nil)
			[ret appendFormat:@"\n0x%X\t%@", [key pointerValue], [mapping objectForKey:key]];
	}
	NSLog(@"%@", ret);	
}

+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.Sapphire" );
}

- (SapphireImporterDataMenu *)allImporterForCollection:(SapphireMetaDataCollection *)collection
{
	SapphireFileDataImporter *fileImp = [[SapphireFileDataImporter alloc] init];
	SapphireTVShowImporter *tvImp = [[SapphireTVShowImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/tvdata.plist"]];
	SapphireMovieImporter *movImp = [[SapphireMovieImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/movieData.plist"]];
	SapphireAllImporter *allImp = [[SapphireAllImporter alloc] initWithImporters:[NSArray arrayWithObjects:tvImp,movImp,fileImp,nil]];
	[fileImp release];
	[tvImp release];
	[movImp release];
	SapphireImporterDataMenu *ret = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] metaDataCollection:collection importer:allImp];
	[allImp release];
	return [ret autorelease];
}

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	
	//Setup the theme's scene
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	[theme setScene:[self scene]];
	
	metaCollection = [[SapphireMetaDataCollection alloc] initWithFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/metaData.plist"]];
	
	settings								= [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/settings.plist"] metaDataCollection:metaCollection] ;
	[self setListTitle:						BRLocalizedString(@"Main Menu", @"")];
	[settings setListTitle:					BRLocalizedString(@" Settings", @"Settings Menu Item")] ;
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
	
	SapphireTVDirectory *tvDir = [[SapphireTVDirectory alloc] initWithCollection:metaCollection];
	SapphireBrowser *tvBrowser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:tvDir];
	[tvBrowser setListTitle:BRLocalizedString(@" TV Shows", nil)];
	[tvBrowser setListIcon:predicateGem];
	[mutableMasterNames addObject:BRLocalizedString(@"  TV Shows", nil)];
	[mutableMasterControllers addObject:tvBrowser];
//	[tvDir writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/virtualTVDir.plist"]];
	[tvBrowser release];
	
	SapphireMovieDirectory *movieDir = [[SapphireMovieDirectory alloc] initWithCollection:metaCollection];
	SapphireBrowser *movieBrowser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:movieDir];
	[movieBrowser setListTitle:BRLocalizedString(@" Movies", nil)];
	[movieBrowser setListIcon:predicateGem];
	[mutableMasterNames addObject:BRLocalizedString(@"  Movies", nil)];
	[mutableMasterControllers addObject:movieBrowser];
//	[movieDir writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/virtualMovieDir.plist"]];
	[movieBrowser release];
	
	[[metaCollection directoryForPath:@"/"] loadMetaData];
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
	
	BRTexture *predicateGem = [SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]];
	NSEnumerator *browserPointsEnum = [[metaCollection collectionDirectories] objectEnumerator];
	NSString *browserPoint = nil;
	int index = 2;
	while((browserPoint = [browserPointsEnum nextObject]) != nil)
	{
		if([metaCollection hideCollection:browserPoint])
			continue;
		SapphireBrowser *browser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaCollection directoryForPath:browserPoint]];
		[browser setListTitle:[NSString stringWithFormat:@" %@",[browserPoint lastPathComponent]]];
		[browser setListIcon:predicateGem];
		[names insertObject:[NSString stringWithFormat:@"  %@", browserPoint] atIndex:index];
		[controllers insertObject:browser atIndex:index];
		[browser release];
		index++;
	}	
	
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
	[SapphireFrontRowCompat renderScene:[self scene]];
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
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:YES];
	
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if([name isEqual: ALL_IMPORT_MENU_ITEM]) [SapphireFrontRowCompat setLeftIcon:[theme gem:IMPORT_GEM_KEY] forMenu:result];
	else if([name isEqual: SETTINGS_MENU_ITEM]) [SapphireFrontRowCompat setLeftIcon:[theme gem:GEAR_GEM_KEY] forMenu:result];
	else if([name isEqual: RESET_MENU_ITEM]) [SapphireFrontRowCompat setLeftIcon:[theme gem:FRONTROW_GEM_KEY] forMenu:result];
	else if([name isEqual: @"  TV Shows"]) [SapphireFrontRowCompat setLeftIcon:[theme gem:TV_GEM_KEY] forMenu:result];
	else if([name isEqual: @"  Movies"]) [SapphireFrontRowCompat setLeftIcon:[theme gem:MOV_GEM_KEY] forMenu:result];
	else [SapphireFrontRowCompat setLeftIcon:[SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]] forMenu:result];
	
	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
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
	
	// This if statement needs to be done in a much more elegant way
	if([controller isKindOfClass:[SapphireBrowser class]])
	{
		SapphireDirectoryMetaData *meta = [(SapphireBrowser *)controller metaData];
		if([meta isKindOfClass:[SapphireVirtualDirectory class]])
		{
			if(![(SapphireVirtualDirectory *)meta isLoaded])
			{
				SapphireVirtualDirectoryLoading *loader = [[SapphireVirtualDirectoryLoading alloc]
														   initWithScene:[self scene]
														   title:BRLocalizedString(@"Loading", @"Loading")
														   text:BRLocalizedString(@"Virtual directory is still loading.\n  You may go back or wait for it to finish.", nil)
														   showBack:YES];
				[loader setDirectory:(SapphireVirtualDirectory *)meta];
				[loader setBrowser:(SapphireBrowser *)controller];
				controller = loader;
			}
		}
	}
	[[self stack] pushController:controller];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end
