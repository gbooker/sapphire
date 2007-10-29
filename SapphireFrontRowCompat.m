//
//  SapphireFrontRowCompat.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireFrontRowCompat.h"

/*Yes, this is the wrong class, but otherwise gcc gripes about BRImage class not existing; this removes warnings so no harm*/
@interface SapphireFrontRowCompat (compat)
+ (id)imageWithPath:(NSString *)path;
@end

/*Yes, wrong class and other wrong things, just to shut up warnings*/
@interface BRAdornedMenuItemLayer (compat)
+ (id)folderMenuItem;
+ (id)menuItem;
- (void)setTitle:(NSString *)title;
- (void)setLeftIconInfo:(BRTexture *)icon;
@end

@implementation SapphireFrontRowCompat

static BOOL usingFrontRow = NO;

+ (void)initialize
{
	if(NSClassFromString(@"BRAdornedMenuItemLayer") == nil)
		usingFrontRow = YES;
}

+ (BOOL)usingFrontRow
{
	return usingFrontRow;
}

+ (id)imageAtPath:(NSString *)path
{
/*	Class cls = NSClassFromString(@"BRImage");
	id img = [cls imageWithPath:path];
	Class layercls = NSClassFromString(@"BRImageLayer");
	id layer = [[layercls alloc] init];
	[layer setImage:img];
	return [layer autorelease];*/
	return nil;
}

+ (BRAdornedMenuItemLayer *)textMenuItemForScene:(BRRenderScene *)scene folder:(BOOL)folder
{
	if(usingFrontRow)
	{
		if(folder)
			return [NSClassFromString(@"BRTextMenuItemLayer") folderMenuItem];
		else
			return [NSClassFromString(@"BRTextMenuItemLayer") menuItem];		
	}
	else
	{
		if(folder)
			return [NSClassFromString(@"BRAdornedMenuItemLayer") adornedFolderMenuItemWithScene:scene];
		else
			return [NSClassFromString(@"BRAdornedMenuItemLayer") adornedMenuItemWithScene:scene];		
	}
}

+ (void)setTitle:(NSString *)title forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		[menu setTitle:title];
	else
		[[menu textItem] setTitle:title];
}

+ (void)setLeftIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		;//[menu setLeftIconInfo:icon];
	else
		[menu setLeftIcon:icon];
}
@end
