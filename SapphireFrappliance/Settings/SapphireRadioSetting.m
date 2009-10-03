/*
 * SapphireRadioSetting.m
 * Sapphire
 *
 * Created by Graham Booker on Mar. 27, 2008.
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

#import "SapphireRadioSetting.h"
#import "SapphireFileMetaData.h"
#import "SapphireMediaPreview.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SapphireRadioSetting

- (id)initWithScene:(BRRenderScene *)scene choices:(NSArray *)selectionChoices target:(NSObject *)aTarget
{
	self = [super initWithScene:scene];
	if (self != nil) {
		choices = [selectionChoices retain];
		[[self list] setDatasource:self];
		target = [aTarget retain];
	}
	return self;
}

- (void) dealloc
{
	[choices release];
	[gettingInvokation release];
	[settingInvokation release];
	[super dealloc];
}

- (void)setSettingSelector:(SEL)setter
{
	[settingInvokation release];
	settingInvokation = [[NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:setter]] retain];
	[settingInvokation setTarget:target];
	[settingInvokation setSelector:setter];
}

- (void)setGettingSelector:(SEL)getter
{
	[gettingInvokation release];
	gettingInvokation = [[NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:getter]] retain];
	[gettingInvokation setTarget:target];
	[gettingInvokation setSelector:getter];
	
	[gettingInvokation invoke];
	[gettingInvokation getReturnValue:&selected];
	[[self list] reload];
}

- (void)setChoiceDescriptions:(NSArray *)choiceDescriptions
{
	[choiceDesc release];
	choiceDesc = [choiceDescriptions retain];
}

- (long)itemCount
{
    // return the number of items in your menu list here
	return [choices count];
}

- (id<BRMenuItemLayer>)itemForRow:(long)row
{
	if(row > [choices count])
		return nil;
	
	BRAdornedMenuItemLayer *result = nil ;
	NSString *name = [choices objectAtIndex:row];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	if(row == selected)
		[SapphireFrontRowCompat setLeftIcon:[SapphireFrontRowCompat selectedSettingImageForScene:[self scene]] forMenu:result];
	
	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
	
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [choices count])
		return nil;
	
	NSString *result = [choices objectAtIndex:row];
	return result;
}

- (long) rowForTitle: (NSString *) title
{
    long result = -1;
    long i, count = [self itemCount];
    for(i = 0; i < count; i++)
    {
        if([title isEqualToString:[self titleForRow:i]])
        {
            result = i;
            break;
        }
    }
    
    return result;
}

- (void) itemSelected: (long) row
{
    // This is called when the user changed a setting
	[settingInvokation setArgument:&row atIndex:2];
	[settingInvokation invoke];
	
	/*Redraw*/
	[[self list] reload];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (id<BRMediaPreviewController>)previewControllerForItem:(long)item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(item >= [choiceDesc count])
		return nil;
	else
	{
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *settingMeta=[[NSMutableDictionary alloc] init];
		[settingMeta setObject:[choices objectAtIndex:item] forKey:META_TITLE_KEY];
		[settingMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[settingMeta setObject:[choiceDesc objectAtIndex:item] forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:settingMeta];
		[settingMeta release];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return nil;
}

@end
