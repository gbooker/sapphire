/*
 * SapphireDisplayMenu.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 17, 2008.
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

#import "SapphireDisplayMenu.h"
#import "SapphireDirectory.h"
#import "SapphireSettings.h"
#import "SapphireFileSorter.h"
#import "SapphireApplianceController.h"
#import "SapphireFileMetaData.h"
#import "SapphireMediaPreview.h"
#import "SapphireTheme.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

typedef enum {
	COMMAND_PREDICATE_NONE,
	COMMAND_PREDICATE_UNWATCHED,
	COMMAND_PREDICATE_FAVORITE,
	COMMAND_SORT_NUM_BASE
} DisplayCommand;

@implementation SapphireDisplayMenu

- (id) initWithScene:(BRRenderScene *)scene directory:(id <SapphireDirectory>)directory
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;

	dir = [directory retain];
	names = [[NSMutableArray alloc] init];
	dispDescriptions = [[NSMutableArray alloc] init];
	commands = [[NSMutableArray alloc] init];
	
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	BOOL dispUnwatched = [settings displayUnwatched];
	BOOL dispFavorite = [settings displayFavorites];
	if(dispUnwatched || dispFavorite)
	{
		[names addObject:BRLocalizedString(@"Display All Files", @"Display All Files (no filtering)")];
		[commands addObject:[NSNumber numberWithInt:COMMAND_PREDICATE_NONE]];
		[dispDescriptions addObject:BRLocalizedString(@"Sapphire will not filter files, but instead display all files", @"No filtering description")];
		if(dispUnwatched)
		{
			[names addObject:BRLocalizedString(@"  Unwatched Files", @"Display only Unwatched Files")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_PREDICATE_UNWATCHED]];
			[dispDescriptions addObject:BRLocalizedString(@"Sapphire will filter files to display only unwatched files", @"Unwatched filtering description")];
		}
		if(dispFavorite)
		{
			[names addObject:BRLocalizedString(@"  Favorite Files", @"Display only Favorite Files")];
			[commands addObject:[NSNumber numberWithInt:COMMAND_PREDICATE_FAVORITE]];
			[dispDescriptions addObject:BRLocalizedString(@"Sapphire will filter files to display only favorite files", @"Favorite filtering description")];
		}
	}
	
	if([dir conformsToProtocol:@protocol(SapphireSortableDirectory)])
	{
		id <SapphireSortableDirectory> sortable = (id <SapphireSortableDirectory>)dir;
		NSArray *sortMechanisms = [sortable fileSorters];
		NSEnumerator *sortEnum = [sortMechanisms objectEnumerator];
		SapphireFileSorter *sorter;
		BOOL first = YES;
		while((sorter = [sortEnum nextObject]) != nil)
		{
			NSString *dispName = [sorter displayName];
			if(first)
			{
				dispName = [@"Sort " stringByAppendingString:dispName];
				[commands addObject:[NSNumber numberWithInt:COMMAND_SORT_NUM_BASE]];
				first = NO;
			}
			else
			{
				dispName = [@"  " stringByAppendingString:dispName];
				[commands addObject:[NSNumber numberWithInt:COMMAND_SORT_NUM_BASE + [sorter sortNumber]]];
			}
			[names addObject:dispName];
			[dispDescriptions addObject:[sorter displayDescription]];
		}
	}
	
	[[self list] setDatasource:self];
	
	return self;
}

- (void) dealloc
{
	[names release];
	[commands release];
	[dispDescriptions release];
	[dir release];
	[super dealloc];
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
	
	DisplayCommand command = [[commands objectAtIndex:row] intValue];
	switch (command) {
		case COMMAND_PREDICATE_NONE:
			if([SapphireApplianceController predicateType] == PREDICATE_TYPE_NONE)
				[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
			[SapphireFrontRowCompat setRightIcon:[[SapphireTheme sharedTheme] gem:RED_GEM_KEY] forMenu:result];
			break;
		case COMMAND_PREDICATE_UNWATCHED:
			if([SapphireApplianceController predicateType] == PREDICATE_TYPE_UNWATCHED)
				[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
			[SapphireFrontRowCompat setRightIcon:[[SapphireTheme sharedTheme] gem:BLUE_GEM_KEY] forMenu:result];
			break;
		case COMMAND_PREDICATE_FAVORITE:
			if([SapphireApplianceController predicateType] == PREDICATE_TYPE_FAVORITE)
				[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
			[SapphireFrontRowCompat setRightIcon:[[SapphireTheme sharedTheme] gem:YELLOW_GEM_KEY] forMenu:result];
			break;
		default:
			if(command - COMMAND_SORT_NUM_BASE == [(id <SapphireSortableDirectory>)dir sortMethodValue])
				[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
			break;
	}
	
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
	
	DisplayCommand command = [[commands objectAtIndex:row] intValue];
	switch (command) {
		case COMMAND_PREDICATE_NONE:
			[SapphireApplianceController setPredicateType:PREDICATE_TYPE_NONE];
			break;
		case COMMAND_PREDICATE_UNWATCHED:
			[SapphireApplianceController setPredicateType:PREDICATE_TYPE_UNWATCHED];
			break;
		case COMMAND_PREDICATE_FAVORITE:
			[SapphireApplianceController setPredicateType:PREDICATE_TYPE_FAVORITE];
			break;
		default:
			[(id <SapphireSortableDirectory>)dir setSortMethodValue:command - COMMAND_SORT_NUM_BASE];
			[dir reloadDirectoryContents];
			break;
	}
	
	[[self stack] popController];
}

- (id<BRMediaPreviewController>) previewControlForItem:(long)item
{
	return [self previewControllerForItem:item];
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
		NSString *markDescription=[dispDescriptions objectAtIndex:item];
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *markMeta=[[NSMutableDictionary alloc] init];
		[markMeta setObject:markName forKey:META_TITLE_KEY];
		[markMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[markMeta setObject:markDescription forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:markMeta];
		[markMeta release];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

@end
