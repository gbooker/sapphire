//
//  SapphireApplianceController.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"

@implementation NSString (episodeSorting)

// Custom TV Episode handler 
- (NSComparisonResult) episodeCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@interface SapphireApplianceController (private)
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
- (NSMutableDictionary *)metaDataForPath:(NSString *)path;
@end

@implementation SapphireApplianceController

// Static set of file extensions to filter
static NSArray *extensions = nil;

+(void)load
{
	extensions = [[NSArray alloc] initWithObjects:@"avi", @"mov", @"mpg", @"wmv", nil];
}

+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.recursivemenu.root" );
}

// 
- (id) initWithScene: (BRRenderScene *) scene
{
/*
    if ( [super initWithScene: scene] == nil )
	return ( nil );
    
    // initialize your resources here
    
    return ( self );
*/
	SapphireDirectoryMetaData *mainMeta = [[SapphireDirectoryMetaData alloc] initWithFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/metaData.plist"]];
	return ( [self initWithScene: scene directory:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"] metaData:mainMeta] );
}

- (id) initWithScene: (BRRenderScene *) scene directory: (NSString *) dir metaData: (SapphireDirectoryMetaData *)meta;
{
	BOOL modifiedMeta = NO;
	if ( [super initWithScene: scene] == nil ) return ( nil );
	_dir = [dir retain];
		
	_names = [NSMutableArray new];
	metaData = [meta retain];
	[metaData setDelegate:self];

	NSMutableArray *files = [NSMutableArray array];
	NSArray *names = [[[NSFileManager defaultManager] directoryContentsAtPath:dir] retain];
	
	NSEnumerator *nameEnum = [names objectEnumerator];
	NSString *name = nil;
	// Display Menu Items
	while((name = [nameEnum nextObject]) != nil)
	{
		if([name hasPrefix:@"."])
			continue;
		//Only accept if it is a directory or right extension
		NSString *extension = [name pathExtension];
		if([extensions containsObject:extension])
			[files addObject:name];
		else if([self isDirectory:[_dir stringByAppendingPathComponent:name]])
			[_names addObject:name];
	}
	modifiedMeta |= [metaData pruneMetaDataWithFiles:files andDirectories:_names];
	modifiedMeta |= [metaData updateMetaDataWithFiles:files andDirectories:_names];
	[_names sortUsingSelector:@selector(episodeCompare:)];
	[files sortUsingSelector:@selector(episodeCompare:)];
	[_names addObjectsFromArray:files];
	
	if(modifiedMeta)
		[metaData writeMetaData];
	
	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

- (void) dealloc
{
    // always remember to deallocate your resources
	[_dir release];
	[_names release];
    [super dealloc];
}

//Check to see if the path is a directory
- (BOOL)isDirectory:(NSString *)path
{
	BOOL isDir = NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir;
}

- (NSString *)sizeStringForMetaData:(SapphireFileMetaData *)meta
{
	float size = [meta size];
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
}

- (void) willBePopped
{
    // The user pressed Menu, but we've not been removed from the screen yet
    
    // always call super
    [super willBePopped];
	[metaData cancelImport];
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
	if([self isDirectory:[_dir stringByAppendingPathComponent:name]])
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
	
	if([self isDirectory:[_dir stringByAppendingPathComponent:name]])
	{
		id controller = [[SapphireApplianceController alloc] initWithScene:[self scene] directory:[_dir stringByAppendingPathComponent:name] metaData:[metaData metaDataForDirectory:name]];
		[[self stack] pushController:controller];
		[controller release];
	}
	else
	{
		BRVideoPlayerController *controller = [[BRVideoPlayerController alloc] initWithScene:[self scene]];
		BRQTKitVideoPlayer *player = [[BRQTKitVideoPlayer alloc] init];
		NSError *error = nil;
		
		NSURL *url = [NSURL fileURLWithPath:[_dir stringByAppendingPathComponent:name]];
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

- (NSString *)directory
{
	return _dir;
}

- (void)updateComplete
{
	BRListControl *list = [self list];
	long selection = [list selection];
	[list reload];
	[list setSelection:selection];	
}

@end
