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
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import <SapphireCompatClasses/SapphireDVDLoadingController.h>

#import "SapphireBrowser.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireSettings.h"
#import "SapphireTheme.h"
#import "SapphireCollectionDirectory.h"

#import "SapphireImporterDataMenu.h"
#import "SapphireAllImporter.h"
#import "SapphireImportHelper.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireEntityDirectory.h"
#import "SapphireMovieDirectory.h"
#import "SapphireMarkMenu.h"
#import "SapphireDisplayMenu.h"
#import "SapphireAudioNowPlayingController.h"
#import "SapphireTVDirectory.h"
#import "SapphireCustomVirtualDirectoryImporter.h"
#import "SapphireURLLoader.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireTVTranslation.h"

#import "NSFileManager-Extensions.h"

NSString *SAPPHIRE_MANAGED_OBJECT_CONTEXT_CLOSING =	@"SapphireManagedObjectContextClosing";

#define ALL_IMPORT_MENU_ITEM	BRLocalizedString(@"  Import All Data", @"All Importer Menu Item")
#define SETTINGS_MENU_ITEM		BRLocalizedString(@"  Settings", @"Settings Menu Item")
#define RESET_MENU_ITEM			BRLocalizedString(@"  Reset the thing already", @"UI Quit")

@interface SapphireDistributedMessagesReceiver : NSObject <SapphireDistributedMessagesProtocol>
{
	SapphireApplianceController *controller;
	NSConnection				*rescanConnection;
}

- (id)initWithController:(SapphireApplianceController *)cont;
@end


@interface SapphireApplianceController ()
- (void)setMenuFromSettings;
- (void)recreateMenu;
@end

@implementation SapphireApplianceController

static NSArray *predicates = nil;

NSPredicate *unwatched = nil;
NSPredicate *favorite = nil;
NSPredicate *skipJoin = nil;
NSPredicate *strictUnwatched = nil;
NSPredicate *strictFavorite = nil;

static NSString *overrideDir = nil;

NSString *applicationSupportDir(void)
{
	NSString *ret = overrideDir;
	if(ret == nil)
		ret = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire"];
	NSFileManager *fm = [NSFileManager defaultManager];
	if(![fm isDirectory:ret])
		[fm constructPath:ret];
	return ret;
}

void overrideApplicationSupportdir(NSString *override)
{
	[overrideDir release];
	overrideDir = [override retain];
}

+ (void)initialize
{
	skipJoin = [[NSPredicate predicateWithFormat:@"joinedToFile == nil"] retain];
	unwatched = [[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"watched == NO"], skipJoin, nil]] retain];
	favorite = [[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"favorite == YES"], skipJoin, nil]] retain];
	//	NSPredicate *topShows = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"top == YES"], skipJoin, nil]];
	predicates = [[NSArray alloc] initWithObjects:unwatched, favorite/*, topShows*/, nil];
	strictUnwatched = [[NSPredicate predicateWithFormat:@"watched == NO"] retain];
	strictFavorite = [[NSPredicate predicateWithFormat:@"favorite == YES"] retain];
}

+ (NSPredicate *)predicate
{
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	int index = [settings indexOfLastPredicate];
	if(index == NSNotFound)
		return skipJoin;
	return [predicates objectAtIndex:index];
}

+ (NSPredicate *)nextPredicate
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
//		case 1:
//			newIndex = 2;
//			if([settings displayTopShows])
//				break;
		default:
			newIndex = NSNotFound;
	}
	[settings setIndexOfLastPredicate:newIndex];
	if(newIndex == NSNotFound)
		return skipJoin;
	return [predicates objectAtIndex:newIndex];
}

+ (PredicateType)predicateType
{
	return [[SapphireSettings sharedSettings] indexOfLastPredicate];
}

+ (void)setPredicateType:(PredicateType)type
{
	[[SapphireSettings sharedSettings] setIndexOfLastPredicate:type];
}

+ (NSPredicate *)unfilteredPredicate
{
	return skipJoin;
}

+ (NSPredicate *)unwatchedPredicate
{
	return strictUnwatched;
}

+ (NSPredicate *)favoritePredicate
{
	return strictFavorite;
}

+ (BRTexture *)gemForPredicate:(NSPredicate *)predicate
{
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if(predicate == nil)
		return [theme gem:RED_GEM_KEY];
	int index = [predicates indexOfObject:predicate];
	switch (index) {
		case 0:
			return [theme gem:BLUE_GEM_KEY];
		case 1:
			return [theme gem:YELLOW_GEM_KEY];
		case 2:
			return [theme gem:GREEN_GEM_KEY];
	}
	return [theme gem:RED_GEM_KEY];
}

+ (NSString *)keyForFilterPredicate:(NSPredicate *)filter andCheckPredicate:(NSPredicate *)check
{
	int found = 0;
	if(filter == skipJoin)
		found = 1;
	else if (filter == unwatched)
		found = 2;
	else if (filter == favorite)
		found = 4;
	else if (filter != nil)
		return [[filter description] stringByAppendingString:[check description]];
	
	if(check == strictUnwatched)
		found |= 2;
	else if (check == strictFavorite)
		found |= 4;
	else if (check != nil)
		return [[filter description] stringByAppendingString:[check description]];
	
	switch (found) {
		case 0:
			return @"nil";
		case 1:
			return @"S";
		case 2:
			return @"W";
		case 3:
			return @"SW";
		case 4:
			return @"F";
		case 5:
			return @"SF";
		case 6:
			return @"WF";
		case 7:
			return @"SWF";
	}
	return nil;
}

BRMusicNowPlayingController *musicController = nil;

+ (void)setMusicNowPlayingController:(BRMusicNowPlayingController *)controller
{
	if(musicController != nil)
	{
		[(BRMusicPlayer *)[musicController player] stop];
		[musicController release];
	}
	musicController = [controller retain];
}

+ (BRMusicNowPlayingController *)musicNowPlayingController
{
	return musicController;
}

+ (SapphireCustomVirtualDirectoryImporter *)customVirtualDirectoryImporter
{
	static SapphireCustomVirtualDirectoryImporter *customVirtualDirectoryImporter = nil;
	if(customVirtualDirectoryImporter == nil)
		customVirtualDirectoryImporter = [[SapphireCustomVirtualDirectoryImporter alloc] initWithPath:[applicationSupportDir() stringByAppendingPathComponent:@"virtualDirs.xml"]];
	return customVirtualDirectoryImporter;
}

+ (SapphireURLLoader *)urlLoader
{
	static SapphireURLLoader *urlLoader = nil;
	if(urlLoader == nil)
		urlLoader = [[SapphireURLLoader alloc] init];
	return urlLoader;
}

+ (void)logException:(NSException *)e
{
	NSMutableString *ret = [NSMutableString stringWithFormat:@"Exception: %@ %@\n", [e name], [e reason]];
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
	SapphireLog(SAPPHIRE_LOG_GENERAL, SAPPHIRE_LOG_LEVEL_ERROR, @"%@", ret);	
}

+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.Sapphire" );
}

+ (BOOL)upgradeNeeded
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *storeFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV3"];
	BOOL exists = [fm fileExistsAtPath:storeFile];
	BOOL oldExists = [fm fileExistsAtPath:[applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV2"]];
	oldExists |= [fm fileExistsAtPath:[applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireData"]];
	oldExists |= [fm fileExistsAtPath:[applicationSupportDir() stringByAppendingPathComponent:@"metaData.plist"]];
	oldExists |= [fm fileExistsAtPath:[applicationSupportDir() stringByAppendingPathComponent:@"movieData.plist"]];
	oldExists |= [fm fileExistsAtPath:[applicationSupportDir() stringByAppendingPathComponent:@"tvdata.plist"]];
	BOOL needNewMeta = !exists && oldExists;
	if(needNewMeta)
		return YES;
	else
	{
		NSManagedObjectContext *moc = [SapphireApplianceController newManagedObjectContextForFile:nil withOptions:nil];
		BOOL ret = [SapphireTVTranslation needsFetchShowIDsInContext:moc];
		[moc release];
		return ret;
	}
}


+ (NSManagedObjectContext *)newManagedObjectContextForFile:(NSString *)storeFile withOptions:(NSDictionary *)storeOptions
{
	if(storeFile == nil)
		storeFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV3"];
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm constructPath:[storeFile stringByDeletingLastPathComponent]];
	NSURL *storeUrl = [NSURL fileURLWithPath:storeFile];
	NSError *error = nil;
	
	NSString *mopath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Sapphire" ofType:@"momd"];
	mopath = [mopath stringByAppendingPathComponent:@"SapphireV3.mom"];
	NSURL *mourl = [NSURL fileURLWithPath:mopath];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mourl];
	
	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	if(![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:storeOptions error:&error])
	{
		SapphireLog(SAPPHIRE_LOG_ALL, SAPPHIRE_LOG_LEVEL_ERROR, @"Could not add store: %@", error);
		
		[coord release];
		[model release];
		return nil;
	}
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
	[moc setUndoManager:nil];
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	[moc setPersistentStoreCoordinator:coord];
	
	[model release];
	[coord release];
	
	return moc;
}

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	
	//Setup the theme's scene
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	[theme setScene:[self scene]];
	
	moc = [SapphireApplianceController newManagedObjectContextForFile:nil withOptions:nil];
	[SapphireMetaDataSupport setMainContext:moc];
	if(moc == nil)
	{
		[self autorelease];
		return nil;
	}
	
	[SapphireDirectoryMetaData createDirectoryWithPath:@"/" parent:nil inContext:moc];
	[SapphireCollectionDirectory collectionAtPath:@"/" mount:YES skip:YES hidden:YES manual:NO inContext:moc];
	
	settings								= [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[applicationSupportDir() stringByAppendingPathComponent:@"settings.plist"] context:moc];
	[self setListTitle:						BRLocalizedString(@"Main Menu", @"Main Menu title")];
	[settings setListTitle:					BRLocalizedString(@" Settings", @"Settings Menu Item")] ;
	[settings setListIcon:					[theme gem:GEAR_GEM_KEY]];
	[[self list] setDatasource:self];
	if([SapphireFrontRowCompat usingLeopard])
	{
		NSString *myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath] ;
		NSString *onlyPath = [myBundlePath stringByAppendingPathComponent:@"/Contents/Frameworks/LeopardOnly.framework"];
		NSBundle *only = [NSBundle bundleWithPath:onlyPath];
		Class onlyClass = [only principalClass];
		leoOnly = [[onlyClass alloc] initWithContext:moc];
	}
	mountsOnly = NO;
	
	SapphireSetLogLevel(SAPPHIRE_LOG_ALL, SAPPHIRE_LOG_LEVEL_ERROR);
	
	distributed = [[SapphireDistributedMessagesReceiver alloc] initWithController:self];
	
	return self;
}

- (void)dealloc
{
	[leoOnly release];
	[names release];
	[controllers release];
	[masterNames release];
	[masterControllers release];
	[moc release];
	[SapphireSettings relinquishSettings];
	[settings release];
	[SapphireImportHelper relinquishHelper];
	[distributed release];
	[super dealloc];
}

- (void)recreateMenu
{
	names = [[NSMutableArray alloc] init];
	controllers = [[NSMutableArray alloc] init];
	if(mountsOnly)
	{
		masterNames = [[NSArray alloc] init];
		masterControllers = [[NSArray alloc] init];
	}
	else
	{
		SapphireImporterDataMenu *allImporter	= [self allImporter];
		NSMutableArray *mutableMasterNames = [[NSMutableArray alloc] init];
		NSMutableArray *mutableMasterControllers = [[NSMutableArray alloc] init];
		
		SapphireBrowser *tvBrowser = [self tvBrowser];
		[tvBrowser setKillMusic:NO];
		[mutableMasterNames addObject:BRLocalizedString(@"  TV Shows", @"Movies Menu Item")];
		[mutableMasterControllers addObject:tvBrowser];
		
		SapphireBrowser *movieBrowser = [self movieBrowser];
		[movieBrowser setKillMusic:NO];
		[mutableMasterNames addObject:BRLocalizedString(@"  Movies", @"Movies Menu Item")];
		[mutableMasterControllers addObject:movieBrowser];
		
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
	}
	[self setMenuFromSettings];
}

- (SapphireBrowser *)tvBrowser
{
	BRTexture *predicateGem = [SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]];
	SapphireTVDirectory *tvDir = [[SapphireTVDirectory alloc] initWithContext:moc];
	SapphireBrowser *tvBrowser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:tvDir];
	[tvDir release];
	[tvBrowser setListTitle:BRLocalizedString(@" TV Shows", @"Movies Menu Title")];
	[tvBrowser setListIcon:predicateGem];
	[tvBrowser setKillMusic:YES];
	return [tvBrowser autorelease];
}

- (SapphireBrowser *)movieBrowser
{
	BRTexture *predicateGem = [SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]];
	SapphireMovieDirectory *movieDir = [[SapphireMovieDirectory alloc] initWithContext:moc];
	SapphireBrowser *movieBrowser = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:movieDir];
	[movieDir release];
	[movieBrowser setListTitle:BRLocalizedString(@" Movies", @"Movies Menu Title")];
	[movieBrowser setListIcon:predicateGem];
	[movieBrowser setKillMusic:YES];
	return [movieBrowser autorelease];	
}

- (void)setToMountsOnly
{
	[self setListTitle:BRLocalizedString(@"Collections", @"Title For Collection Menu")];
	mountsOnly = YES;
}

- (SapphireImporterDataMenu *)allImporter
{
	SapphireAllImporter *allImp = [[SapphireAllImporter alloc] init];
	SapphireImporterDataMenu *ret = [[SapphireImporterDataMenu alloc] initWithScene:[self scene] context:moc importer:allImp];
	[allImp release];
	return [ret autorelease];
}

- (SapphireSettings *)settings
{
	return settings;
}

- (void)setMenuFromSettings
{
	[names removeAllObjects];
	[controllers removeAllObjects];
	[names addObjectsFromArray:masterNames];
	[controllers addObjectsFromArray:masterControllers];
	NSMutableDictionary *dvds = [NSMutableDictionary dictionary];
	NSEnumerator *dvdEnum = [[NSClassFromString(@"BRDiskArbHandler") mountedDVDs] objectEnumerator];
	BRDiskInfo *dvdInfo;
	while((dvdInfo = [dvdEnum nextObject]) != nil)
	{
		NSString *mountpoint = [dvdInfo mountpoint];
		[dvds setObject:dvdInfo forKey:mountpoint];
	}
	
	BRTexture *predicateGem = [SapphireApplianceController gemForPredicate:[SapphireApplianceController predicate]];
	NSEnumerator *browserPointsEnum = [[SapphireCollectionDirectory availableCollectionDirectoriesInContext:moc includeHiddenOverSkipped:NO] objectEnumerator];
	SapphireCollectionDirectory *browserPoint = nil;
	int index = 2;
	if(mountsOnly)
		index = 0;
	while((browserPoint = [browserPointsEnum nextObject]) != nil)
	{
		if([browserPoint hiddenValue])
			continue;
		id controller = nil;
		if((dvdInfo = [dvds objectForKey:browserPoint]) != nil)
		{
			BRDVDMediaAsset *asset = [BRDVDMediaAsset assetFromDiskInfo:dvdInfo];
			controller = [[SapphireDVDLoadingController alloc] initWithScene:[self scene] forAsset:asset];
		}
		else
		{
			SapphireDirectoryMetaData *meta = [browserPoint directory];
			controller = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:meta];
			[controller setListTitle:[NSString stringWithFormat:@" %@",[[meta path] lastPathComponent]]];
			[controller setListIcon:predicateGem];
		}
		if(controller != nil)
		{
			[names insertObject:[NSString stringWithFormat:@"  %@", [browserPoint name]] atIndex:index];
			[controllers insertObject:controller atIndex:index];
			[controller release];
			index++;
		}
	}	
	
	if([settings disableUIQuit] && !mountsOnly)
		[names removeLastObject];
}

- (void)completeRescanOfDir:(NSArray *)filePaths
{
	if(![filePaths count])
		return;
	
	[SapphireMetaDataSupport save:moc];
	NSString *dirPath = [[filePaths objectAtIndex:0] stringByDeletingLastPathComponent];
	SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData directoryWithPath:dirPath inContext:moc];
	[dir addImportFilePaths:filePaths];
	[[dir delegate] directoryContentsChanged];
	[dir resumeImport];
}


- (void)rescanDirectory:(NSString *)dirPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(![[NSFileManager defaultManager] isDirectory:dirPath])
	{
		[pool drain];
		return;
	}
	
	if(![dirPath isAbsolutePath])
	{
		[pool drain];
		return;
	}
	
	dirPath = [dirPath stringByResolvingSymlinksInPath];
	
	NSManagedObjectContext *threadMoc = [SapphireApplianceController newManagedObjectContextForFile:nil withOptions:nil];
	SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData createDirectoryWithPath:dirPath inContext:threadMoc];
	[dir reloadDirectoryContents];
	NSArray *paths = [dir importFilePaths];
	[SapphireMetaDataSupport applyChangesFromContext:threadMoc];
	[threadMoc release];
	[self performSelectorOnMainThread:@selector(completeRescanOfDir:) withObject:paths waitUntilDone:NO];
	[pool drain];
}

- (void)doInitialPush
{
    // We've just been put on screen, the user can see this controller's content now
    [self recreateMenu];
	[[self list] reload];
    // always call super
    [super doInitialPush];
}

- (void)doInitialExhume
{
    // handle being revealed when the user presses Menu
    
	[self setMenuFromSettings];
	[[self list] reload];
	[SapphireFrontRowCompat renderScene:[self scene]];

    // always call super
    [super doInitialExhume];
}

- (void)wasPopped
{
    [super wasPopped];
	[SapphireApplianceController setMusicNowPlayingController:nil];
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
	[[self stack] pushController:controller];
}

- (id<BRMediaPreviewController>) previewControlForItem:(long)item
{
	return [self previewControllerForItem:item];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventRemoteAction remoteAction = [SapphireFrontRowCompat remoteActionForEvent:event];
	if ([(BRControllerStack *)[self stack] peekController] != self)
		remoteAction = 0;
	
	int row = [self getSelection];
	if(row < [controllers count])
	{
		BRLayerController *controller = [controllers objectAtIndex:row];
		id <SapphireDirectory> meta = nil;
		if([controller isKindOfClass:[SapphireBrowser class]])
			meta = [(SapphireBrowser *)controller metaData];
		switch (remoteAction)
		{
			case kBREventRemoteActionRight:
			{
				if(meta == nil)
					break;
				/*Do mark menu*/
				SapphireMarkMenu *mark = [[SapphireMarkMenu alloc] initWithScene:[self scene] metaData:meta];
				[mark setListTitle:[names objectAtIndex:row]];
				[[self stack] pushController:mark];
				[mark release];
				return YES;
			}
			case kBREventRemoteActionLeft:
			{
				SapphireDisplayMenu *display = [[SapphireDisplayMenu alloc] initWithScene:[self scene] directory:meta];
				[display setListTitle:[names objectAtIndex:row]];
				[[self stack] pushController:display];
				[display release];
				return YES;
			}
		}
		
	}
	return [super brEventAction:event];
}

@end

@implementation SapphireDistributedMessagesReceiver

- (id)initWithController:(SapphireApplianceController *)cont
{
	self = [super init];
	if(self == nil)
		return nil;
	
	controller = cont;
	NSPort *receivePort = [[NSSocketPort alloc] initWithTCPPort:DISTRIBUTED_MESSAGES_PORT];
	rescanConnection = [[NSConnection alloc] initWithReceivePort:receivePort sendPort:nil];
	[receivePort release];
	[rescanConnection setRootObject:self];
	
	return self;
}

- (void) dealloc
{
	[rescanConnection release];
	[super dealloc];
}

- (oneway void)rescanDirectory:(NSString *)dirPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread detachNewThreadSelector:@selector(rescanDirectory:) toTarget:controller withObject:dirPath];
	[pool drain];
}

@end
