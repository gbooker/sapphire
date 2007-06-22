//
//  SapphireApplianceController.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>

#define FILES_KEY @"Files"
#define DIRS_KEY @"Dirs"

#define MODIFIED_KEY @"Modified"

@implementation NSString (episodeSorting)

// Custom TV Episode handler 
- (NSComparisonResult) episodeCompare:(NSString *)other
{
	return [self compare:other options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@interface SapphireApplianceController (private)
- (BOOL)pruneMetaDataWithFiles:(NSArray *)files andDirectories:(NSArray *)dirs;
- (BOOL)updateMetaDataWithFiles:(NSArray *)files andDirectories:(NSArray *)dirs;
@end

@implementation SapphireApplianceController

// Static set of file extensions to filter
static NSArray *extensions = nil;
static NSString *metaPath = nil;
static NSMutableDictionary *mainMetaDictionary = nil;

+(void)load
{
	extensions = [[NSArray alloc] initWithObjects:@"avi", @"mov", @"mpg", @"wmv", nil];
	metaPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/metaData.plist"] retain];
	mainMetaDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:metaPath];
	if(mainMetaDictionary == nil)
	{
		mainMetaDictionary = [[NSMutableDictionary alloc] init];
	}
}

+ (NSString *) rootMenuLabel
{
	return (@"net.pmerrill.recursivemenu.root" );
}

static void makeParentDir(NSFileManager *manager, NSString *dir)
{
	NSString *parent = [dir stringByDeletingLastPathComponent];
	
	BOOL isDir;
	if(![manager fileExistsAtPath:parent isDirectory:&isDir])
		makeParentDir(manager, parent);
	else if(!isDir)
		//Can't work with this
		return;
	
	[manager createDirectoryAtPath:dir attributes:nil];
}

+ (void)writeMetaData
{
	makeParentDir([NSFileManager defaultManager], [metaPath stringByDeletingLastPathComponent]);
	[mainMetaDictionary writeToFile:metaPath atomically:YES];
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
	return ( [self initWithScene: scene directory:[NSHomeDirectory() stringByAppendingPathComponent:@"Movies"] metaData:mainMetaDictionary] );
}

- (id) initWithScene: (BRRenderScene *) scene directory: (NSString *) dir metaData: (NSMutableDictionary *)meta;
{
	BOOL modifiedMeta = NO;
	if ( [super initWithScene: scene] == nil ) return ( nil );
	_dir = [dir retain];
		
	_names = [NSMutableArray new];
	_metaData = [meta retain];
	_metaFiles = [meta objectForKey:FILES_KEY];
	if(_metaFiles == nil)
	{
		_metaFiles = [NSMutableDictionary dictionary];
		[meta setObject:_metaFiles forKey:FILES_KEY];
		modifiedMeta = YES;
	}
	_metaDirs = [meta objectForKey:DIRS_KEY];
	if(_metaDirs == nil)
	{
		_metaDirs = [NSMutableDictionary dictionary];
		[meta setObject:_metaDirs forKey:DIRS_KEY];
		modifiedMeta = YES;
	}
	
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
	modifiedMeta |= [self pruneMetaDataWithFiles:files andDirectories:_names];
	modifiedMeta |= [self updateMetaDataWithFiles:files andDirectories:_names];
	[_names sortUsingSelector:@selector(episodeCompare:)];
	[files sortUsingSelector:@selector(episodeCompare:)];
	[_names addObjectsFromArray:files];
	
	if(modifiedMeta)
		[SapphireApplianceController writeMetaData];
	
	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

- (void) dealloc
{
    // always remember to deallocate your resources
	[_dir release];
	[_names release];
	[_metaData release];
    [super dealloc];
}

//Check to see if the path is a directory
- (BOOL)isDirectory:(NSString *)path
{
	BOOL isDir = NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir;
}

- (BOOL)pruneMetaDataWithFiles:(NSArray *)files andDirectories:(NSArray *)dirs
{
	BOOL ret = NO;
	NSSet *existingSet = [NSSet setWithArray:files];
	NSArray *metaArray = [_metaFiles allKeys];
	NSMutableSet *pruneSet = [NSMutableSet setWithArray:metaArray];

	[pruneSet minusSet:existingSet];
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		while((pruneKey = [pruneEnum nextObject]) != nil)
			[_metaFiles removeObjectForKey:pruneKey];
		ret = YES;		
	}
	
	existingSet = [NSSet setWithArray:dirs];
	metaArray = [_metaDirs allKeys];
	pruneSet = [NSMutableSet setWithArray:metaArray];
	
	[pruneSet minusSet:existingSet];
	if([pruneSet anyObject] != nil)
	{
		NSEnumerator *pruneEnum = [pruneSet objectEnumerator];
		NSString *pruneKey = nil;
		while((pruneKey = [pruneEnum nextObject]) != nil)
			[_metaDirs removeObjectForKey:pruneKey];
		ret = YES;
	}
	
	return ret;
}

- (BOOL)updateMetaDataWithFiles:(NSArray *)files andDirectories:(NSArray *)dirs
{
	BOOL ret = NO;
	NSArray *metaArray = [_metaDirs allKeys];
	NSSet *metaSet = [NSSet setWithArray:metaArray];
	NSMutableSet *newSet = [NSMutableSet setWithArray:dirs];
	
	[newSet minusSet:metaSet];
	if([newSet anyObject] != nil)
	{
		NSEnumerator *newEnum = [newSet objectEnumerator];
		NSString *newKey = nil;
		while((newKey = [newEnum nextObject]) != nil)
			[_metaDirs setObject:[NSMutableDictionary dictionary] forKey:newKey];
		ret = YES;
	}

	NSEnumerator *fileEnum = [files objectEnumerator];
	NSString *fileName = nil;
	NSMutableArray *newFiles = [NSMutableArray array];
	while((fileName = [fileEnum nextObject]) != nil)
	{
		NSDictionary *fileMeta = [_metaFiles objectForKey:fileName];
		if(fileMeta == nil)
			[newFiles addObject:fileName];
		else
		{
			NSString *path = [_dir stringByAppendingPathComponent:fileName];
			NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
			NSDate *modDate = [props objectForKey:NSFileModificationDate];
			if([[fileMeta objectForKey:MODIFIED_KEY] intValue] != [modDate timeIntervalSince1970])
				[newFiles addObject:fileName];
		}
	}
	//Do something in a thread to process newFiles
	
	return ret;
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
			result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: [self scene]] ;
			
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
		id controller = [[SapphireApplianceController alloc] initWithScene:[self scene] directory:[_dir stringByAppendingPathComponent:name] metaData:[_metaDirs objectForKey:name]];
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

@end
