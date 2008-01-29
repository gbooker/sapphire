/*
 * SapphireCollectionSettings.m
 * Sapphire
 *
 * Created by Graham Booker on Sep. 3, 2007.
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

#import "SapphireCollectionSettings.h"
#import "SapphireMetaData.h"
#import "SapphireMediaPreview.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SapphireCollectionSettings

- (id) initWithScene: (BRRenderScene *) scene collection:(SapphireMetaDataCollection *)collection
{
	self = [super initWithScene:scene];
	if(self == nil)
		return nil;
	
	metaCollection = [collection retain];
	names = [[metaCollection collectionDirectories] retain];
	[[self list] setDatasource:self];

	return self;
}

- (void) dealloc
{
	[metaCollection release];
	[names release];
	[super dealloc];
}

- (void)setSettingSelector:(SEL)selector
{
	[setInv release];
	setInv = [[NSInvocation invocationWithMethodSignature:[metaCollection methodSignatureForSelector:selector]] retain];
	[setInv setTarget:metaCollection];
	[setInv setSelector:selector];
	[[self list] reload];
}
- (void)setGettingSelector:(SEL)selector
{
	[getInv release];
	getInv = [[NSInvocation invocationWithMethodSignature:[metaCollection methodSignatureForSelector:selector]] retain];
	[getInv setTarget:metaCollection];
	[getInv setSelector:selector];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	return ( [ names count]);
}

- (BOOL)checkedForName:(NSString *)name
{
	[getInv setArgument:&name atIndex:2];
	[getInv invoke];
	BOOL checked = NO;
	[getInv getReturnValue:&checked];
	return checked;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	/*
	 // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
	 // return that object, it will be used to display the list item.
	 return ( nil );
	 */
	if( row > [names count] ) return ( nil ) ;
	
	BRAdornedMenuItemLayer * result = nil ;
	NSString *name = [names objectAtIndex:row];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	if([self checkedForName:name])
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	
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
    // This is called when the user changed a setting
	
	NSString *name = [names objectAtIndex:row];
	BOOL setting = [self checkedForName:name];
	setting = !setting;
	[setInv setArgument:&setting atIndex:2];
	[setInv setArgument:&name atIndex:3];
	[setInv invoke];
	
	/*Redraw*/
	[metaCollection writeMetaData];
	[[self list] reload] ;
	[SapphireFrontRowCompat renderScene:[self scene]];
	
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(item >= [names count])
		return nil;
	else
	{
		NSString *settingName = (NSString *)[self listTitle];
		NSString *settingDescription=nil;
		if([settingName hasPrefix:@"Hide"])
		{
			settingName = [NSString stringWithFormat:@"Hide Collection \"%@\"",[names objectAtIndex:item]];
			settingDescription=BRLocalizedString(@"tells Sapphire to hide this collection on the main menu.", @"Hide collections setting description");
		}
		else
		{
			settingName = [NSString stringWithFormat:@"Don't Import \"%@\"",[names objectAtIndex:item]];
			settingDescription=BRLocalizedString(@"tells Sapphire to ignore this collection when running any import tool.", @"Import collections setting description");
		}
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *settingMeta=[[NSMutableDictionary alloc] init];
		[settingMeta setObject:settingName forKey:META_TITLE_KEY];
		[settingMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[settingMeta setObject:settingDescription forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:settingMeta];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

@end
