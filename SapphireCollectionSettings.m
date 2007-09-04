//
//  SapphireCollectionSettings.m
//  Sapphire
//
//  Created by Graham Booker on 9/3/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireCollectionSettings.h"
#import "SapphireMetaData.h"

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
	result = [BRAdornedMenuItemLayer adornedMenuItemWithScene: [self scene]] ;
	
	if([self checkedForName:name])
		[result setLeftIcon:[[BRThemeInfo sharedTheme] selectedSettingImageForScene:[self scene]]];
	
	// add text
	[[result textItem] setTitle: name] ;
				
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
	[[self list] reload] ;
	[[self scene] renderScene];
	
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
    return ( nil );
}

@end
