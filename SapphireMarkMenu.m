//
//  SapphireMarkMenu.m
//  Sapphire
//
//  Created by Graham Booker on 6/25/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMarkMenu.h"
#import "SapphireMetaData.h"
#import "SapphireFrontRowCompat.h"
#import <QTKit/QTKit.h>

@implementation SapphireMarkMenu

typedef enum {
	COMMAND_TOGGLE_WATCHED,
	COMMAND_TOGGLE_FAVORITE,
	COMMAND_MARK_TO_REFETCH_TV,
	COMMAND_MARK_TO_REFETCH_MOVIE,
	COMMAND_MARK_TO_DELETE_METADATA,
	COMMAND_MARK_TO_JOIN,
	COMMAND_MARK_AND_JOIN,
	COMMAND_CLEAR_JOIN_MARK,
	COMMAND_JOIN,
} MarkCommand;

static NSMutableArray *joinList;

+ (void)initialize
{
	joinList = [[NSMutableArray alloc] init];
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireMetaData *)meta
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	/*Check to see if it is directory or file*/
	isDir = [meta isKindOfClass:[SapphireDirectoryMetaData class]];
	metaData = [meta retain];
	commands = nil;
	/*Create the menu*/
	if(isDir)
		names = [[NSMutableArray alloc] initWithObjects:
			BRLocalizedString(@"Mark All as Watched", @"Mark whole directory as watched"),
			BRLocalizedString(@"Mark All as Unwatched", @"Mark whole directory as unwatched"),
			BRLocalizedString(@"Mark All as Favorite", @"Mark whole directory as favorite"),
			BRLocalizedString(@"Mark All as Not Favorite", @"Mark whole directory as not favorite"),
			BRLocalizedString(@"Mark All to Refetch TV Data", @"Mark whole directory to re-fetch its tv data"),
			BRLocalizedString(@"Mark All to Refetch Movie Data", @"Mark whole directory to re-fetch its movie data"),
			BRLocalizedString(@"Mark All to Clear Metadata", @"Mark whole directory to delete the metadata"),
			nil];
	else if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		NSString *watched = nil;
		NSString *favorite = nil;
		
		if([fileMeta watched])
			watched = BRLocalizedString(@"Mark as Unwatched", @"Mark file as unwatched");
		else
			watched = BRLocalizedString(@"Mark as Watched", @"Mark file as watched");

		if([fileMeta favorite])
			favorite = BRLocalizedString(@"Mark as Not Favorite", @"Mark file as a favorite");
		else
			favorite = BRLocalizedString(@"Mark as Favorite", @"Mark file as not a favorite");
		names = [[NSMutableArray alloc] initWithObjects:watched, favorite, nil];
		commands = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithInt:COMMAND_TOGGLE_WATCHED], [NSNumber numberWithInt:COMMAND_TOGGLE_FAVORITE], nil];
		if([fileMeta importedTimeFromSource:META_TVRAGE_IMPORT_KEY])
		{
			[names addObject:BRLocalizedString(@"Mark to Refetch TV Data", @"Mark file to re-fetch its tv data")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_TV]];
		}
		if([fileMeta importedTimeFromSource:META_IMDB_IMPORT_KEY])
		{
			[names addObject:BRLocalizedString(@"Mark to Refetch Movie Data", @"Mark file to re-fetch its movie data")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_MOVIE]];
		}
		if([fileMeta fileClass] != FILE_CLASS_UNKNOWN)
		{
			[names addObject:BRLocalizedString(@"Mark to Clear Metadata", @"Mark a file to delete the metadata")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_DELETE_METADATA]];
		}
		if(![joinList containsObject:fileMeta])
		{
			[names addObject:BRLocalizedString(@"Mark This File to Be Joined", @"Mark This File to Be Joined")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_JOIN]];
			[names addObject:BRLocalizedString(@"Mark This File and Join Group", @"Mark This File and Join Group")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_AND_JOIN]];
		}
		if([joinList count])
		{
			[names addObject:BRLocalizedString(@"Join Marked Files", @"Join Marked Files")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_JOIN]];
			[names addObject:BRLocalizedString(@"Clear the Join List", @"Clear the Join List")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_CLEAR_JOIN_MARK]];
		}
	}
	else
	{
		/*Neither, so just return nil*/
		[self autorelease];
		return nil;
	}
	[[self list] setDatasource:self];
	
	return self;
}

- (void) dealloc
{
	[metaData release];
	[names release];
	[predicate release];
	[super dealloc];
}

- (void)setPredicate:(SapphirePredicate *)newPredicate
{
	predicate = [newPredicate retain];
}

- (void)doJoin
{
	if(![joinList count])
		return;
	
	QTMovie *resultingMovie = [[QTMovie alloc] init];
	[resultingMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	NSString *savePath = [[joinList objectAtIndex:0] path];
	BOOL hasmovExt = [[savePath pathExtension] isEqualToString:@"mov"];
	NSString *base = [savePath stringByDeletingPathExtension];
	if([[base lowercaseString] hasSuffix:@" part 1"])
		base = [base substringToIndex:[base length] - 7];
	if(hasmovExt)
		savePath = [[base stringByAppendingString:@" Joined"] stringByAppendingPathExtension:@"mov"];
	else
		savePath = [base stringByAppendingPathExtension:@"mov"];

	int i, count=[joinList count];
	for(i=0;i<count;i++)
	{
		SapphireFileMetaData *meta = [joinList objectAtIndex:i];
		NSError *error = nil;
		NSDictionary *openAttr = [NSDictionary dictionaryWithObjectsAndKeys:
								  [meta path], QTMovieFileNameAttribute,
								  [NSNumber numberWithBool:NO], QTMovieOpenAsyncOKAttribute,
								  nil];
		QTMovie *current = [[QTMovie alloc] initWithAttributes:openAttr error:&error];
		if(error == nil)
		{
			QTTimeRange range;
			range.time = [current selectionStart];
			range.duration = [current duration];
			[current setSelection:range];
			[resultingMovie appendSelectionFromMovie:current];
			[meta setJoinedFile:savePath];
		}
		[current release];
	}

	[resultingMovie writeToFile:savePath withAttributes:[NSDictionary dictionary]];
	[resultingMovie release];
	[joinList removeAllObjects];
	[metaData writeMetaData];
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
	if( row >= [names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [names objectAtIndex:row];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{
	
	if ( row >= [ names count] ) return ( nil );
	
	NSString *result = [ names objectAtIndex: row] ;
	return ( result ) ;
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
	if(row >= [names count])
		return;
	
	/*Do action on dir or file*/
	if(isDir)
	{
		SapphireDirectoryMetaData *dirMeta = (SapphireDirectoryMetaData *)metaData;
		switch(row)
		{
			case 0:
				[dirMeta setWatched:YES forPredicate:predicate];
				break;
			case 1:
				[dirMeta setWatched:NO forPredicate:predicate];
				break;
			case 2:
				[dirMeta setFavorite:YES forPredicate:predicate];
				break;
			case 3:
				[dirMeta setFavorite:NO forPredicate:predicate];
				break;
			case 4:
				[dirMeta setToImportFromSource:META_TVRAGE_IMPORT_KEY forPredicate:predicate];
			case 5:
				[dirMeta setToImportFromSource:META_IMDB_IMPORT_KEY forPredicate:predicate];
				break;
		}
	}
	else
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		switch([[commands objectAtIndex:row] intValue])
		{
			case COMMAND_TOGGLE_WATCHED:
				[fileMeta setWatched:![fileMeta watched]];
				break;
			case COMMAND_TOGGLE_FAVORITE:
				[fileMeta setFavorite:![fileMeta favorite]];
				break;
			case COMMAND_MARK_TO_REFETCH_TV:
				[fileMeta setToImportFromSource:META_TVRAGE_IMPORT_KEY];
				break;
			case COMMAND_MARK_TO_REFETCH_MOVIE:
				[fileMeta setToImportFromSource:META_IMDB_IMPORT_KEY];
				break;
			case COMMAND_MARK_TO_DELETE_METADATA:
				[fileMeta clearMetaData];
				break;
			case COMMAND_MARK_TO_JOIN:
				[joinList addObject:fileMeta];
				break;
			case COMMAND_CLEAR_JOIN_MARK:
				[joinList removeAllObjects];
				break;
			case COMMAND_MARK_AND_JOIN:
				[joinList addObject:fileMeta];
			case COMMAND_JOIN:
				[self doJoin];
				break;
		}
	}
	/*Save and exit*/
	[metaData writeMetaData];
	[[self stack] popController];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end
