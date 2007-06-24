//
//  SapphireBrowser.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireBrowser.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"

@interface SapphireBrowser (private)
- (void)reloadDirectoryContents;
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
- (NSMutableDictionary *)metaDataForPath:(NSString *)path;
@end

@implementation SapphireBrowser

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta
{
	return [self initWithScene:scene metaData:meta predicate:NULL];
}
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta predicate:(SapphirePredicate *)newPredicate;
{
	if ( [super initWithScene: scene] == nil ) return ( nil );
		
	_names = [NSMutableArray new];
	metaData = [meta retain];
	[metaData setDelegate:self];
	predicate = [newPredicate retain];

	[self reloadDirectoryContents];
	
	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

- (void)reloadDirectoryContents
{
	[metaData reloadDirectoryContents];
	[_names removeAllObjects];
	if(predicate == NULL)
	{
		[_names addObjectsFromArray:[metaData directories]];
		[_names addObjectsFromArray:[metaData files]];
	}
	else
	{
		[_names addObjectsFromArray:[metaData predicatedDirectories:predicate]];
		[_names addObjectsFromArray:[metaData predicatedFiles:predicate]];
	}

	BRListControl *list = [self list];
	long selection = [list selection];
	[list reload];
	[list setSelection:selection];	
}

- (void) dealloc
{
    // always remember to deallocate your resources
	[_names release];
	[metaData release];
	[predicate release];
    [super dealloc];
}

- (NSString *)sizeStringForMetaData:(SapphireFileMetaData *)meta
{
	float size = [meta size];
	if(size == 0)
		return @"-";
	char letter = ' ';
	if(size >= 1024000)
	{
		if(size >= 1024*1024000)
		{
			size /= 1024 * 1024 * 1024;
			letter = 'G';
		}
		else
		{
			size /= 1024 * 1024;
			letter = 'M';
		}
	}
	else if (size >= 1000)
	{
		size /= 1024;
		letter = 'K';
	}
	return [NSString stringWithFormat:@"%.1f\n%cB", size, letter];	
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
	[metaData resumeImport];
}

- (void) willBePopped
{
    // The user pressed Menu, but we've not been removed from the screen yet
    
    // always call super
    [super willBePopped];
	[metaData cancelImport];
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
    
    // always call super
	[metaData cancelImport];
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
	[self reloadDirectoryContents];
    [super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
    // handle being revealed when the user presses Menu
    
    // always call super
    [super wasExhumedByPoppingController: controller];
	[metaData resumeImport];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	return ( [ _names count]);
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
/*
    // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
    // return that object, it will be used to display the list item.
    return ( nil );
*/
	if( row > [_names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [_names objectAtIndex:row];
	if([[metaData directories] containsObject:name])
		result = [BRAdornedMenuItemLayer adornedFolderMenuItemWithScene: [self scene]] ;
	else
	{
		result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: [self scene]] ;
		BOOL watched = NO;
		SapphireFileMetaData *meta = [metaData metaDataForFile:name];
		if(meta != nil)
		{
			[[result textItem] setRightJustifiedText:[self sizeStringForMetaData:meta]];
			watched = [meta watched];
		}
		if(!watched)
			[result setLeftIcon:[[BRThemeInfo sharedTheme] unplayedPodcastImageForScene:[self scene]]]; 
	}
			
	// add text
	[[result textItem] setTitle: name] ;
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{

	if ( row > [ _names count] ) return ( nil );
	
	NSString *result = [ _names objectAtIndex: row] ;
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
	
	NSString *name = [_names objectAtIndex:row];
	NSString *dir = [metaData path];
	
	if([[metaData directories] containsObject:name])
	{
		id controller = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaData metaDataForDirectory:name] predicate:predicate];
		[[self stack] pushController:controller];
		[controller release];
	}
	else
	{
		BRVideoPlayerController *controller = [[BRVideoPlayerController alloc] initWithScene:[self scene]];
		BRQTKitVideoPlayer *player = [[BRQTKitVideoPlayer alloc] init];
		NSError *error = nil;
		
		NSURL *url = [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:name]];
		BRSimpleMediaAsset *asset  =[[BRSimpleMediaAsset alloc] initWithMediaURL:url];
		[player setMedia:asset error:&error];
		
		[controller setVideoPlayer:player];
		SapphireFileMetaData *meta = [metaData metaDataForFile:name];
		[meta setWatched];
		[meta writeMetaData];
		[[self stack] pushController:controller];

		[asset release];
		[player release];
		[controller release];
	}
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

- (void)updateComplete
{
	BRListControl *list = [self list];
	long selection = [list selection];
	[list reload];
	[list setSelection:selection];	
}

@end
