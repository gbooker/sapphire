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
#import "SapphireCollectionDirectory.h"
#import "SapphireFileMetaData.h"
#import "SapphireMediaPreview.h"
#import "SapphireMetaDataSupport.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "NSString-Extensions.h"

@implementation SapphireCollectionSettings

- (id) initWithScene: (BRRenderScene *) scene context:(NSManagedObjectContext *)context;
{
	self = [super initWithScene:scene];
	if(self == nil)
		return nil;
	
	moc = [context retain];
	//Scan collections
	[SapphireCollectionDirectory availableCollectionDirectoriesInContext:moc includeHiddenOverSkipped:NO];
	collections = [[SapphireCollectionDirectory allCollectionsInContext:moc] retain];
	
	[[self list] setDatasource:self];

	return self;
}

- (void) dealloc
{
	[moc release];
	[collections release];
	[super dealloc];
}

- (void)setSettingSelector:(SEL)selector
{
	[setInv release];
	setInv = [[NSInvocation invocationWithMethodSignature:[SapphireCollectionDirectory instanceMethodSignatureForSelector:selector]] retain];
	[setInv setSelector:selector];
	[[self list] reload];
}

- (void)setGettingSelector:(SEL)selector
{
	[getInv release];
	getInv = [[NSInvocation invocationWithMethodSignature:[SapphireCollectionDirectory instanceMethodSignatureForSelector:selector]] retain];
	[getInv setSelector:selector];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	return ( [ collections count]);
}

- (BOOL)checkedForCollection:(SapphireCollectionDirectory *)col
{
	[getInv setTarget:col];
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
	if(row > [collections count])
		return nil;
	
	BRAdornedMenuItemLayer * result = nil ;
	SapphireCollectionDirectory *collection = [collections objectAtIndex:row];
	NSString *name = [[collection directory] path];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	if([self checkedForCollection:collection])
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	
	// add text
	[SapphireFrontRowCompat setTitle:[NSString stringByCroppingDirectoryPath:name toLength:3] forMenu:result];
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{
	
	if(row > [collections count])
		return nil;
	
	SapphireCollectionDirectory *collection = [collections objectAtIndex:row];
	return [[collection directory] path];
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
	
	SapphireCollectionDirectory *collection = [collections objectAtIndex:row];
	BOOL setting = [self checkedForCollection:collection];
	setting = !setting;
	[setInv setArgument:&setting atIndex:2];
	[setInv setTarget:collection];
	[setInv invoke];
	
	/*Redraw*/
	[SapphireMetaDataSupport save:moc];
	[[self list] reload] ;
	[SapphireFrontRowCompat renderScene:[self scene]];	
}

- (id<BRMediaPreviewController>) previewControlForItem: (long) row
{
	return [self previewControllerForItem:row];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(item >= [collections count])
		return nil;

	NSString *settingName = (NSString *)[self listTitle];
	NSString *settingDescription=nil;
	SapphireCollectionDirectory *collection = [collections objectAtIndex:item];
	NSString *name = [[collection directory] path];
	if([settingName hasPrefix:@"Hide"])
	{
		
		settingName = [NSString stringWithFormat:@"Hide Collection \"%@\"",[NSString stringByCroppingDirectoryPath:name toLength:3]];
		settingDescription=BRLocalizedString(@"Tells Sapphire to hide this collection on the main menu.", @"Hide collections setting description");
	}
	else if([settingName hasPrefix:@"Skip"])
	{
		settingName = [NSString stringWithFormat:@"Don't Import \"%@\"",[NSString stringByCroppingDirectoryPath:name toLength:3]];
		settingDescription=BRLocalizedString(@"Tells Sapphire to ignore this collection when running any import tool.", @"Import collections setting description");
	}
	else if([settingName hasPrefix:@"Delete"])
	{
		settingName = [NSString stringWithFormat:@"Delete Collection \"%@\"",[NSString stringByCroppingDirectoryPath:name toLength:3]];
		settingDescription=BRLocalizedString(@"Tells Sapphire to erase all knowledge of files in this collection.", @"Delete collections setting description");
	}
	/* Construct a gerneric metadata asset for display */
	NSMutableDictionary *settingMeta=[[NSMutableDictionary alloc] init];
	[settingMeta setObject:settingName forKey:META_TITLE_KEY];
	[settingMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
	[settingMeta setObject:settingDescription forKey:META_DESCRIPTION_KEY];
	SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
	[preview setUtilityData:settingMeta];
	[settingMeta release];
	[preview setShowsMetadataImmediately:YES];
	/*And go*/
	return [preview autorelease];
}

- (void) wasPopped
{
	//The collections may be modified greatly when we are done, so don't keep them around.
	[collections release];
	collections = nil;
	
    // always call super
    [super wasPopped];
}

@end
