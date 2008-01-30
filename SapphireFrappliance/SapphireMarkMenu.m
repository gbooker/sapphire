/*
 * SapphireMarkMenu.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
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

#import "SapphireMarkMenu.h"
#import "SapphireMetaData.h"
#import "SapphireMediaPreview.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
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
	//Directory commands
	COMMAND_MARK_WATCHED,
	COMMAND_MARK_UNWATCHED,
	COMMAND_MARK_FAVORITE,
	COMMAND_MARK_NOT_FAVORITE,
	COMMAND_TOGGLE_SKIP,
	COMMAND_TOGGLE_COLLECTION
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
	{
		names = [[NSMutableArray alloc] initWithObjects:
			BRLocalizedString(@"Mark All as Watched", @"Mark whole directory as watched"),
			BRLocalizedString(@"Mark All as Unwatched", @"Mark whole directory as unwatched"),
			BRLocalizedString(@"Mark All as Favorite", @"Mark whole directory as favorite"),
			BRLocalizedString(@"Mark All as Not Favorite", @"Mark whole directory as not favorite"),
			BRLocalizedString(@"Mark All to Refetch TV Data", @"Mark whole directory to re-fetch its tv data"),
			BRLocalizedString(@"Mark All to Refetch Movie Data", @"Mark whole directory to re-fetch its movie data"),
			BRLocalizedString(@"Mark All to Clear Metadata", @"Mark whole directory to delete the metadata"),
			nil];
		markDescriptions = [[NSMutableArray alloc] initWithObjects:
			BRLocalizedString(@"Sapphire will save this directory as watched.", @"Mark directory watched description"),
			BRLocalizedString(@"Sapphire will save this directory as unwatched.", @"Mark directory as unwatched description"),
			BRLocalizedString(@"Sapphire will add this directory as favorite.", @"Mark directory as favorite description"),
			BRLocalizedString(@"Sapphire will remove this directory from favorites.", @"Mark directory as not favorite"),
			BRLocalizedString(@"tells Sapphire to refetch TV Show metadata for this directory the next time an import is run.", @"Mark directory to refetch tv data description"),
			BRLocalizedString(@"tells Sapphire to refetch Movie metadata for this directory the next time an import is run.", @"Mark whole directory to re-fetch its movie data"),
			BRLocalizedString(@"tells Sapphire to remove all metadata for this directory.", @"Mark directory to delete metadata description"),
			nil];
		commands = [[NSMutableArray alloc] initWithObjects:
					[NSNumber numberWithInt:COMMAND_MARK_WATCHED],
					[NSNumber numberWithInt:COMMAND_MARK_UNWATCHED],
					[NSNumber numberWithInt:COMMAND_MARK_FAVORITE],
					[NSNumber numberWithInt:COMMAND_MARK_NOT_FAVORITE],
					[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_TV],
					[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_MOVIE],
					[NSNumber numberWithInt:COMMAND_MARK_TO_DELETE_METADATA],
					nil];
		NSString *path = [meta path];
		if([path characterAtIndex:0] != '@')
		{
			SapphireMetaDataCollection *collection = [meta collection];
			if([collection skipCollection:path])
			{
				[names addObject:BRLocalizedString(@"Mark Directory For Importing", @"Marks this directory to be no longer be skipped during import")];
				[markDescriptions addObject:BRLocalizedString(@"tells Sapphire it's okay to import from this directory.", @"Mark Directory For Importing description")];
			}
			else
			{
				[names addObject:BRLocalizedString(@"Mark this Directory to Skip Import", @"Marks this directory to be skipped during import")];
				[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to skip this directory when importing.", @"Mark this Directory to Skip Import description")];
			}
			[commands addObject:[NSNumber numberWithInt:COMMAND_TOGGLE_SKIP]];
			if([collection isCollectionDirectory:path])
			{
				[names addObject:BRLocalizedString(@"Mark this Directory to Not be a Collection", @"Marks the directory to no longer be a collection")];
				[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to remove this directory from the Collections list.", @"Marks the directory to no longer be a collection description")];
			}
			else
			{
				[names addObject:BRLocalizedString(@"Mark this Directory as a Collection", @"Marks the directory to be a collection")];
				[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to add this directory to the Collections list.", @"Marks the directory to be a collection description")];
			}
			[commands addObject:[NSNumber numberWithInt:COMMAND_TOGGLE_COLLECTION]];
		}
	}
	else if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		NSString *watched = nil;
		NSString *watchedDesc = nil;
		NSString *favorite = nil;
		NSString *favoriteDesc = nil;
		
		if([fileMeta watched])
		{
			watched		= BRLocalizedString(@"Mark as Unwatched", @"Mark file as unwatched");
			watchedDesc = BRLocalizedString(@"Sapphire will save this file as unwatched.", @"Mark directory watched description");
		}
		else
		{
			watched		= BRLocalizedString(@"Mark as Watched", @"Mark file as watched");
			watchedDesc = BRLocalizedString(@"Sapphire will save this file as watched.", @"Mark directory watched description");
		}

		if([fileMeta favorite])
		{
			favorite	 = BRLocalizedString(@"Mark as Not Favorite", @"Mark file as a favorite");
			favoriteDesc = BRLocalizedString(@"Sapphire will remove this file from favorites.", @"Mark directory as not favorite");
		}
		else
		{
			favorite	 = BRLocalizedString(@"Mark as Favorite", @"Mark file as not a favorite");
			favoriteDesc = BRLocalizedString(@"Sapphire will add this file as favorite.", @"Mark directory as favorite description");

		}
		names			 = [[NSMutableArray alloc] initWithObjects:watched, favorite, nil];
		markDescriptions = [[NSMutableArray alloc] initWithObjects:watchedDesc, favoriteDesc, nil];
		commands = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithInt:COMMAND_TOGGLE_WATCHED], [NSNumber numberWithInt:COMMAND_TOGGLE_FAVORITE], nil];
		if([fileMeta importedTimeFromSource:META_TVRAGE_IMPORT_KEY])
		{
			[names addObject:BRLocalizedString(@"Mark to Refetch TV Data", @"Mark file to re-fetch its tv data")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to refetch TV Show metadata for this file the next time an import is done.", @"Mark file to refetch tv data description")];

			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_TV]];
		}
		if([fileMeta importedTimeFromSource:META_IMDB_IMPORT_KEY])
		{
			[names addObject:BRLocalizedString(@"Mark to Refetch Movie Data", @"Mark file to re-fetch its movie data")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to refetch Movie metadata for this file the next time an import is done.", @"Mark file to refetch movie description")];

			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_MOVIE]];
		}
		if([fileMeta fileClass] != FILE_CLASS_UNKNOWN)
		{
			[names addObject:BRLocalizedString(@"Mark to Clear Metadata", @"Mark a file to delete the metadata")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to remove all metadata for this file.", @"Mark file to delete metadata description")];

			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_DELETE_METADATA]];
		}
		if(![joinList containsObject:fileMeta])
		{
			[names addObject:BRLocalizedString(@"Mark This File to Be Joined", @"Mark This File to Be Joined")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire you wish to add this file to the list of files to join. The files will be joined in the order they were added to the list.", @"Mark file to be joined description")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_TO_JOIN]];
			[names addObject:BRLocalizedString(@"Mark This File and Join Group", @"Mark This File and Join Group")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to use this file and complete the joined list.", @"Mark file and join description")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_MARK_AND_JOIN]];
		}
		if([joinList count])
		{
			[names addObject:BRLocalizedString(@"Join Marked Files", @"Join Marked Files")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to complete the file join.", @"Join Marked Files description")];

			[commands addObject:[NSNumber numberWithInt:COMMAND_JOIN]];
			[names addObject:BRLocalizedString(@"Clear the Join List", @"Clear the Join List")];
			[markDescriptions addObject:BRLocalizedString(@"tells Sapphire to clear the file join list.", @"clear file join list description")];

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
		SapphireMetaDataCollection *collection = [dirMeta collection];
		NSString *path = [dirMeta path];
		switch([[commands objectAtIndex:row] intValue])
		{
			case COMMAND_MARK_WATCHED:
				[dirMeta setWatched:YES forPredicate:predicate];
				break;
			case COMMAND_MARK_UNWATCHED:
				[dirMeta setWatched:NO forPredicate:predicate];
				break;
			case COMMAND_MARK_FAVORITE:
				[dirMeta setFavorite:YES forPredicate:predicate];
				break;
			case COMMAND_MARK_NOT_FAVORITE:
				[dirMeta setFavorite:NO forPredicate:predicate];
				break;
			case COMMAND_MARK_TO_REFETCH_TV:
				[dirMeta setToImportFromSource:META_TVRAGE_IMPORT_KEY forPredicate:predicate];
				break;
			case COMMAND_MARK_TO_REFETCH_MOVIE:
				[dirMeta setToImportFromSource:META_IMDB_IMPORT_KEY forPredicate:predicate];
				break;
			case COMMAND_MARK_TO_DELETE_METADATA:
				[dirMeta clearMetaDataForPredicate:predicate];
				break;
			case COMMAND_TOGGLE_SKIP:
				[collection setSkip:![collection skipCollection:path] forCollection:path];
				break;
			case COMMAND_TOGGLE_COLLECTION:
				if([collection isCollectionDirectory:path])
					[collection removeCollectionDirectory:path];
				else
					[collection addCollectionDirectory:path];
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
		if(item >= [names count])
		return nil;
	else
	{
		/* Get setting name & kill cushion  */
		NSString *markName =[NSString stringWithFormat:@"%@ for \"%@\"",[names objectAtIndex:item],(NSString *)[self listTitle]];
		NSString *markDescription=[markDescriptions objectAtIndex:item];
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *markMeta=[[NSMutableDictionary alloc] init];
		[markMeta setObject:markName forKey:META_TITLE_KEY];
		[markMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[markMeta setObject:markDescription forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:markMeta];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

@end
