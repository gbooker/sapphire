//
//  SapphireBrowser.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireBrowser.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"
#import "SapphireMarkMenu.h"
#import "SapphireMedia.h"
#import "SapphireVideoPlayer.h"
#import "SapphireMediaPreview.h"
#import "SapphireTheme.h"
#import "SapphireSettings.h"
#import "NSString-Extensions.h"

@interface SapphireBrowser (private)
- (void)reloadDirectoryContents;
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
- (NSMutableDictionary *)metaDataForPath:(NSString *)path;
@end

@interface BRTVShowsSortControl (bypassAccess)
- (BRTVShowsSortSelectorStateLayer *)gimmieDate;
- (BRTVShowsSortSelectorStateLayer *)gimmieShow;
- (int)gimmieState;
@end

@interface BRTVShowsSortSelectorStateLayer (bypassAccess)
- (BRTextLayer *)gimmieDate;
- (BRTextLayer *)gimmieShow;
@end

/*Private variables access, but only on BR 1.0; not used otherwise*/
@implementation BRTVShowsSortControl (bypassAccess)
- (BRTVShowsSortSelectorStateLayer *)gimmieDate
{
	return _sortedByDateWidget;
}

- (BRTVShowsSortSelectorStateLayer *)gimmieShow
{
	return _sortedByShowWidget;
}

- (int)gimmieState
{
	return _state;
}

@end

@implementation BRTVShowsSortSelectorStateLayer (bypassAccess)
- (BRTextLayer *)gimmieDate
{
	return _dateLayer;
}

- (BRTextLayer *)gimmieShow
{
	return _showLayer;
}

@end

@implementation SapphireBrowser

/*!
 * @brief Replace the text in a control with a string
 *
 * @param control The control on which to change the text
 * @param str The text to put into tho control
 */
- (void)replaceControlText:(BRTextLayer *)control withString:(NSString *)str
{
	/*Create a mutable copy of the control's attributed string*/
	NSMutableAttributedString  *dateString = [[control attributedString] mutableCopy];
	[dateString replaceCharactersInRange:NSMakeRange(0, [dateString length]) withString:str];
	/*Set the new string and we are done with it*/
	[control setAttributedString:dateString];
	[dateString release];
}

/*!
 * @brief Create a new normal browser
 *
 * @param scene The scene
 * @param meta The metadata for the directory to browse
 * @return The Browser
 */
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta
{
	return [self initWithScene:scene metaData:meta predicate:NULL];
}

/*!
 * @brief Creates the mode control in a compatible way
 *
 * @param scene The scene
 * @param names The names in the menu
 */
- (void)createModeControlWithScene:(BRRenderScene *)scene names:(NSArray *)names
{
	/*Check for the new way to do this*/
	Class modeClass = NSClassFromString(@"BRSegmentedSortControl");
	if(modeClass != nil)
		/*Use the new method*/
		//Ignore this warning if compiling with backrow 1.0
		modeControl = [[modeClass alloc] initWithScene:scene segmentNames:names selectedSegment:0];
	else
	{
		/*Hack in the old way*/
		modeControl = [[BRTVShowsSortControl alloc] initWithScene:scene state:1];
		NSString *name1 = [names objectAtIndex:0];
		NSString *name2 = [names objectAtIndex:1];
		[self replaceControlText:[[modeControl gimmieDate] gimmieDate] withString:name1];
		[self replaceControlText:[[modeControl gimmieDate] gimmieShow] withString:name2];
		[self replaceControlText:[[modeControl gimmieShow] gimmieDate] withString:name1];
		[self replaceControlText:[[modeControl gimmieShow] gimmieShow] withString:name2];
	}
}

/*!
 * @brief Creates a new predicated browser
 *
 * @param scene The scene
 * @praam meta The metadata for the directory to browse
 * @param newPredicate The predicate to use
 * @return The Browser
 */
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta predicate:(SapphirePredicate *)newPredicate;
{
	if ( [super initWithScene: scene] == nil ) return ( nil );
		
	_names = [NSMutableArray new];
	items = [NSMutableArray new];
	metaData = [meta retain];
	[metaData setDelegate:self];
	predicate = [newPredicate retain];

	/*Create the mode menu*/
	NSArray *names = [NSArray arrayWithObjects:
		BRLocalizedString(@"Select", @"Select Menu Item"),
		BRLocalizedString(@"Mark File", @"Mark File Menu Item"),
		nil];
	[self createModeControlWithScene:scene names:names];
	[self addControl:modeControl];
	
	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

/*!
 * @brief Override the layout
 */
- (void)_doLayout
{
	[super _doLayout];
	NSRect listFrame = [[_listControl layer] frame];
	/*Position the mode menu below the list*/
	NSRect modeRect;
	modeRect.size = [modeControl preferredSizeForScreenHeight:[self masterLayerFrame].size.height];
	modeRect.origin.y = listFrame.origin.y * 1.5f;
	modeRect.origin.x = (listFrame.size.width - modeRect.size.width)/2 + listFrame.origin.x;
	/*Shrink the list to make room for the mode*/
	listFrame.size.height -= listFrame.origin.y;
	listFrame.origin.y *= 2;
	[[_listControl layer] setFrame:listFrame];
	[modeControl setFrame:modeRect];
}

/*!
 * @brief Reload the display
 */
- (void)reloadDirectoryContents
{
	/*Remove the dividers*/
	BRListControl *list = [self list];
	[list removeDividerAtIndex:dirCount];
	[list removeDividerAtIndex:[_names count] - 1];
	/*Tell the metadata to get new data*/
	[metaData reloadDirectoryContents];
	/*Flush our cache*/
	[_names removeAllObjects];
	[items removeAllObjects];
	/*Check predicates*/
	if(predicate == NULL)
	{
		/*No filtering, so just set up the dirs and files into names and the counts*/
		NSArray *dirs = [metaData directories];
		[_names addObjectsFromArray:dirs];
		NSArray *files = [metaData files];
		[_names addObjectsFromArray:files];
		dirCount = [dirs count];
		fileCount = [files count];
	}
	else
	{
		/*Filter the dirs and files into names and counts*/
		NSArray *dirs = [metaData predicatedDirectories:predicate];
		[_names addObjectsFromArray:dirs];
		NSArray *files = [metaData predicatedFiles:predicate];
		[_names addObjectsFromArray:files];
		/*Put in the menu for rescan if fast switching enabled*/
		if([[SapphireSettings sharedSettings] fastSwitching])
			[_names addObject:BRLocalizedString(@"< Scan for new files >", @"Conduct a scan of the directory for new files")];
		dirCount = [dirs count];
		fileCount = [files count];
	}
	/*Init the cache*/
	int i=0, count=[_names count];
	for(i=0; i<count; i++)
	{
		[items addObject:[NSNull null]];
	}

	/*Do a reload*/
	[list reload];
	/*Add dividers*/
	if(dirCount && dirCount != [_names count])
		[list addDividerAtIndex:dirCount];
	if(predicate != NULL && [[SapphireSettings sharedSettings] fastSwitching])
		[list addDividerAtIndex:[_names count] -1];
	/*Draw*/
	[[self scene] renderScene];
}

/*!
 * @brief Get the mode in a compatible way
 *
 * @return The mode selection
 */
- (int)selectedMode
{
	/*Get if using the old method*/
	if([modeControl isKindOfClass:[BRTVShowsSortControl class]])
		return [modeControl gimmieState] - 1;
	
	/*Get it from the new method*/
	return [modeControl selectedSegment];
}

- (void) dealloc
{
    // always remember to deallocate your resources
	[_names release];
	[items release];
	[metaData release];
	[predicate release];
	[modeControl release];
    [super dealloc];
}

- (void) willBePushed
{
    // We're about to be placed on screen, but we're not yet there
    
    // always call super
    [super willBePushed];
	/*Reload upon display*/
	[self reloadDirectoryContents];
}

- (void) wasPushed
{
    // We've just been put on screen, the user can see this controller's content now
    
    // always call super
    [super wasPushed];
	/*Get metadata when we can*/
	[metaData resumeDelayedImport];
}

- (void) willBePopped
{
    // The user pressed Menu, but we've not been removed from the screen yet
    
    // always call super
    [super willBePopped];
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	[metaData setDelegate:nil];
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
    
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
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
    
	/*Check to see if the user stopped playing something*/
	id controller = [[self stack] peekController];
	if([controller isKindOfClass:[BRVideoPlayerController class]])
	{
		/*Check for 90% completion*/
		BRVideoPlayer *player = [(BRVideoPlayerController *)controller player];
		float elapsed = [player elapsedPlaybackTime];
		float duration = [player trackDuration];
		if(elapsed / duration > 0.9f)
			/*Mark as watched and reload info*/
			[currentPlayFile setWatched:YES];

		/*Get the resume time to save*/
		if(elapsed < duration - 2)
			[currentPlayFile setResumeTime:[player elapsedPlaybackTime]];
		else
			[currentPlayFile setResumeTime:0];
		[currentPlayFile writeMetaData];
	}
	/*cleanup*/
	[currentPlayFile release];
	currentPlayFile = nil;
	/*Reload our display*/
	[self reloadDirectoryContents];
    // always call super
    [super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
    // handle being revealed when the user presses Menu
    
    // always call super
    [super wasExhumedByPoppingController: controller];
	/*Check to see if dir is empty*/
	if(fileCount + dirCount == 0)
		[[self stack] popController];
	else
		/*Resume importing now that we are up again*/
		[metaData resumeDelayedImport];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	if([_names count])
		return ( [ _names count]);
	// Put up an empty item
	return 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
/*
    // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
    // return that object, it will be used to display the list item.
    return ( nil );
*/
	NSString * displayName=nil ;
	/*Check for no items*/
	int nameCount = [_names count];
	if( nameCount == 0)
	{
		BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
		[[result textItem] setTitle:BRLocalizedString(@"< EMPTY >", @"Empty directory")];
		return result;
	}
	if( row >= nameCount ) return ( nil ) ;
	
	/*Check our cache*/
	id cached = [items objectAtIndex:row];
	if(cached != [NSNull null])
		return cached;
	NSString *name = [_names objectAtIndex:row];
	// Pad filename to correcrtly display gem icons
	BRAdornedMenuItemLayer * result = nil;
	BOOL watched = NO;
	BOOL favorite = NO;
	BOOL gear = NO;
	BRRenderScene *scene = [self scene];
	/*Is this a dir*/
	if(row < dirCount)
	{
		result = [BRAdornedMenuItemLayer adornedFolderMenuItemWithScene: scene] ;
		SapphireDirectoryMetaData *meta = [metaData metaDataForDirectory:name];
		watched = [meta watchedForPredicate:predicate];
		favorite = [meta favoriteForPredicate:predicate];
	}
	/*Check for a file next*/
	else if(row < dirCount + fileCount)
	{
		result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: scene] ;
		SapphireFileMetaData *meta = [metaData metaDataForFile:name];
		if(meta != nil)
		{
			/*Display episode number if availble*/
			int eps= [meta episodeNumber] ;
			displayName=[meta episodeTitle] ;
			if(eps>0)
				[[result textItem] setRightJustifiedText:[NSString stringWithFormat:@" %02d",eps]];
			else
				/*Fallback to size*/
				[[result textItem] setRightJustifiedText:[meta sizeString]];
			watched = [meta watched];
			favorite = [meta favorite] ;
		}
	}
	/*Utility*/
	else
	{
		result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:scene];
		gear = YES;
	}
	/*Add icons*/
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if(gear) [result setLeftIcon:[theme gem:GEAR_GEM_KEY]];
	else if(!watched) [result setLeftIcon:[theme gem:BLUE_GEM_KEY]];
	else if(favorite)[result setLeftIcon:[theme gem:YELLOW_GEM_KEY]];
	else [result setLeftIcon:[theme gem:RED_GEM_KEY]];
			
	// add text
	if(displayName)name= displayName ;
	name=[@"   " stringByAppendingString: name] ;
	[[result textItem] setTitle: name] ;
	[items replaceObjectAtIndex:row withObject:result];
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{

	if ( row >= [ _names count] ) return ( nil );
	
	NSString *result = [ _names objectAtIndex: row] ;
	
	return ([@"  ????? " stringByAppendingString: result] ) ;
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
	
	if([_names count] == 0)
	{
		/*No items, so leave the empty dir*/
		[[self stack] popController];
		return;
	}
	
	NSString *name = [_names objectAtIndex:row];
	NSString *dir = [metaData path];
	
	/*Check mode for mark*/
	if([self selectedMode] == 1)
	{
		id meta = nil;
		/*Get metadata*/
		if(row < dirCount)
			meta = [metaData metaDataForDirectory:name];
		else
			meta = [metaData metaDataForFile:name];
		/*Do mark menu*/
		id controller = [[SapphireMarkMenu alloc] initWithScene:[self scene] metaData:meta];
		[(SapphireMarkMenu *)controller setPredicate:predicate];
		[[self stack] pushController:controller];
		[controller release];
		return;
	}
	
	/*Check for dir*/
	if(row < dirCount)
	{
		/*Browse the subdir*/
		id controller = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaData metaDataForDirectory:name] predicate:predicate];
		[controller setListTitle:name];
		[controller setListIcon:[self listIcon]];
		[[self stack] pushController:controller];
		[controller release];
	}
	else if(row < dirCount + fileCount)
	{
		/*Play the video*/
		BRVideoPlayerController *controller = [[BRVideoPlayerController alloc] initWithScene:[self scene]];
		
		currentPlayFile = [[metaData metaDataForFile:name] retain];
		[controller setAllowsResume:YES];
		
		NSString *path = [dir stringByAppendingPathComponent:name];
		
		/*Anonymous reporting*/
		if(![[SapphireSettings sharedSettings] disableAnonymousReporting])
		{
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/show.php"]];
/*			int ep = [currentPlayFile episodeNumber];
			int season = [currentPlayFile seasonNumber];
			NSString *showID = [currentPlayFile showID];*/
			NSMutableString *reqData = nil;
			
			NSMutableArray *reqComp = [NSMutableArray array];
			
/*			if(season != 0)
				[reqComp addObject:[NSString stringWithFormat:@"season=%d", season]];
			if(ep != 0)
				[reqComp addObject:[NSString stringWithFormat:@"ep=%d", ep]];
			if(showID != 0)
				[reqComp addObject:[NSString stringWithFormat:@"show=%d", showID]];*/
			if(path != 0)
				[reqComp addObject:[NSString stringWithFormat:@"path=%d", path]];
			
			int count = [reqComp count];
			int i;
			for(i=0; i<count-1; i++)
			{
				[reqData appendFormat:@"%@&", [reqComp objectAtIndex:i]];
			}
			if(count)
				[reqData appendFormat:@"%@", [reqComp objectAtIndex:i]];
			
			NSData *postData = [reqData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			
			[request setHTTPMethod:@"POST"];
			[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
			[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			[request setHTTPBody:postData];
			[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
			/*Trigger the req*/
			NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:nil];
			[download autorelease];
		}
		
		/*Set the asset resume time*/
		NSURL *url = [NSURL fileURLWithPath:path];
		SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
		[asset setResumeTime:[currentPlayFile resumeTime]];

		/*Get the player*/
		SapphireVideoPlayer *player = [[SapphireVideoPlayer alloc] init];
		[player setMetaData:currentPlayFile];
		NSError *error = nil;
		[player setMedia:asset error:&error];
		
		/*and go*/
		[controller setVideoPlayer:player];
		[[self stack] pushController:controller];

		[asset release];
		[player release];
		[controller release];
	}
	else
	{
		/*Do a scan*/
		cancelScan = NO;
		[metaData scanForNewFilesWithDelegate:self skipDirectories:[NSMutableSet set]];
	}
}

/*!
 * @brief Finished scanning the dir
 *
 * @param subs nil in this case
 */
- (void)gotSubFiles:(NSArray *)subs
{
	[self reloadDirectoryContents];	
}

/*!
* @brief Meta data delegate method to inform on its scanning progress
 *
 * @param dir The current directory it is scanning
 */
- (void)scanningDir:(NSString *)dir
{
}

/*!
 * @brief Check to see if the scan should be canceled
 *
 * @return YES if the scan should be canceled
 */
- (BOOL)getSubFilesCanceled
{
	return cancelScan;
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) row
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(row >= [_names count])
		return nil;
	/*Check to see if it is a dir or file*/
	NSString *name = [_names objectAtIndex:row];
	if(row < dirCount + fileCount)
	{
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		/*Check for dir*/
		if(row < dirCount)
			[preview setMetaData:[metaData metaDataForDirectory:name]];
		else
			[preview setMetaData:[metaData metaDataForFile:name]];
		[preview setShowsMetadataImmediately:NO];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

- (BOOL)brEventAction:(id)fp8
{
	/*Cancel imports on an action*/
	[metaData resumeDelayedImport];
	return [super brEventAction:fp8];
}

/*!
 * @brief The import on a file completed
 *
 * @param file Filename to the file which completed
 */
- (void)updateCompleteForFile:(NSString *)file
{
	/*Get the file*/
	int index = [_names indexOfObject:file];
	if(index != NSNotFound)
		[items replaceObjectAtIndex:index withObject:[NSNull null]];
	/*Relead the list and render*/
	BRListControl *list = [self list];
	[list reload];
	[[self scene] renderScene];
}

@end
