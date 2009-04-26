/*
 * SapphireFrontRowCompat.m
 * Sapphire
 *
 * Created by Graham Booker on Oct. 29, 2007.
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

#import "SapphireFrontRowCompat.h"
#import <ExceptionHandling/NSExceptionHandler.h>
#import "SapphireButtonControl.h"

/*Yes, this is the wrong class, but otherwise gcc gripes about BRImage class not existing; this removes warnings so no harm*/
@interface SapphireFrontRowCompat (compat)
+ (id)imageWithPath:(NSString *)path;
- (id)downsampledImageForMaxSize:(NSSize)size;
+ (id)imageWithCGImageRef:(CGImageRef)ref;
- (CGImageRef)image;
@end

NSData *CreateBitmapDataFromImage(CGImageRef image, unsigned int width, unsigned int height);

/*Yes, wrong class and other wrong things, just to shut up warnings*/
@interface BRAdornedMenuItemLayer (compat)
+ (id)folderMenuItem;
+ (id)menuItem;
- (void)setTitle:(NSString *)title;
- (void)setTitle:(NSString *)title withAttributes:(NSDictionary *)attributes;
- (void)setRightJustifiedText:(NSString *)text;
- (void)setLeftIconInfo:(BRTexture *)icon;
- (void)setRightIconInfo:(BRTexture *)icon;
@end

@interface BRThemeInfo (compat)
- (id)selectedSettingImage;
- (id)unplayedPodcastImage;
- (id)returnToImage;
@end

@interface BRButtonControl (compat)
- (id)initWithMasterLayerSize:(NSSize)fp8;
@end

@interface BRTextControl (compat)
- (void)setText:(NSString *)text withAttributes:(NSDictionary *)attr;
- (NSRect)controllerFrame;  /*technically wrong; it is really a CGRect*/
- (NSSize)renderedSizeWithMaxSize:(NSSize)maxSize; /*technically wrong; it is really a CGSize*/
@end

@interface NSException (compat)
- (NSArray *)callStackReturnAddresses;
@end

@interface BRAlertController (compat)
+ (BRAlertController *)alertOfType:(int)type titled:(NSString *)title primaryText:(NSString *)primaryText secondaryText:(NSString *)secondaryText;
@end

@interface BROptionDialog (compat)
- (void)setPrimaryInfoText:(NSString *)text withAttributes:(NSDictionary *)attributes;
@end

@interface BRTextWithSpinnerController (compat)
- (BRTextWithSpinnerController *)initWithTitle:(NSString *)title text:(NSString *)text isNetworkDependent:(BOOL)networkDependent;
@end

@interface BRControl (compat)
- (void)insertControl:(id)control atIndex:(long)index;
@end

@interface BRWaitSpinnerControl (compat)
- (void)setSpins:(BOOL)spin;
@end

@interface BRTextEntryControl (compat)
- (id)initWithTextEntryStyle:(int)style;
@end


@implementation SapphireFrontRowCompat

static BOOL usingFrontRow = NO;
static BOOL usingTakeTwo = NO;
static BOOL usingTakeTwoDotTwo = NO;
static BOOL usingTakeTwoDotThree = NO;

+ (void)initialize
{
	if(NSClassFromString(@"BRAdornedMenuItemLayer") == nil)
		usingFrontRow = YES;
	
	if(NSClassFromString(@"BRBaseAppliance") != nil)
		usingTakeTwo = YES;
	
	if(NSClassFromString(@"BRVideoPlayerController") == nil)
		usingTakeTwoDotTwo = YES;
	
	if([(Class)NSClassFromString(@"BRController") instancesRespondToSelector:@selector(wasExhumed)])
		usingTakeTwoDotThree = YES;
}

+ (BOOL)usingFrontRow
{
	return usingFrontRow;
}

+ (BOOL)usingTakeTwo
{
	return usingTakeTwo;
}

+ (BOOL)usingTakeTwoDotTwo
{
	return usingTakeTwoDotTwo;
}

+ (BOOL)usingTakeTwoDotThree
{
	return usingTakeTwoDotThree;
}

+ (id)imageAtPath:(NSString *)path
{
  if(usingFrontRow) {
    Class cls = NSClassFromString(@"BRImage");
    return [cls imageWithPath:path];
  } else {
    // this returns a CGImageRef
    NSURL             *url      = [NSURL fileURLWithPath:path];
    CGImageRef        imageRef  = NULL;
    CGImageSourceRef  sourceRef;
    
    sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if(sourceRef) {
      imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
      CFRelease(sourceRef);
    }
    
    return [(id)imageRef autorelease];
	}
}

+ (id)imageAtPath:(NSString *)path scene:(BRRenderScene *)scene
{
  if(usingFrontRow) {
    return [self imageAtPath:path];
  } else {
    CGImageRef imageRef  = (CGImageRef)[self imageAtPath:path];
    BRTexture  *ret      = nil;
    
    if(imageRef != NULL) {
      /*Create a texture*/
      ret = [BRBitmapTexture textureWithImage:imageRef context:[scene resourceContext] mipmap:YES];
    }
    
    return ret;
  }
}

+ (id)coverartAsImage: (CGImageRef)imageRef
{
	// Non-FR - return CGImageRef
	if (!usingFrontRow)
		return (id)imageRef;

	// FR - return BRImage
	Class cls = NSClassFromString(@"BRImage");
	return (id)[cls imageWithCGImageRef:imageRef];
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

+ (void)setTitle:(NSString *)title withAttributes:(NSDictionary *)attributes forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		[menu setTitle:title withAttributes:attributes];
	else
		[[menu textItem] setTitle:title withAttributes:attributes];
}

+ (NSString *)titleForMenu:(BRAdornedMenuItemLayer *)menu {
  if(usingFrontRow)
    return [menu title];
  else
    return [[menu textItem] title];
}
+ (void)setRightJustifiedText:(NSString *)text forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		[menu setRightJustifiedText:text];
	else
		[[menu textItem] setRightJustifiedText:text];
}

+ (void)setLeftIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		[menu setLeftIconInfo:[NSDictionary dictionaryWithObjectsAndKeys:
							   icon, @"BRMenuIconImageKey",
							   nil]];
	else
		[menu setLeftIcon:icon];
}

+ (void)setRightIcon:(BRTexture *)icon forMenu:(BRAdornedMenuItemLayer *)menu
{
	if(usingFrontRow)
		 [menu setRightIconInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								 icon, @"BRMenuIconImageKey",
								 nil]];
	else
		[menu setRightIcon:icon];
}

+ (id)selectedSettingImageForScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
		return [[BRThemeInfo sharedTheme] selectedSettingImage];
	else
		return [[BRThemeInfo sharedTheme] selectedSettingImageForScene:scene];
}

+ (id)unplayedPodcastImageForScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
		return [[BRThemeInfo sharedTheme] unplayedPodcastImage];
	else
		return [[BRThemeInfo sharedTheme] unplayedPodcastImageForScene:scene];
}

+ (id)returnToImageForScene:(BRRenderScene *)scene {
  if(usingFrontRow)
    return [[BRThemeInfo sharedTheme] returnToImage];
  else
    return [[BRThemeInfo sharedTheme] returnToImageForScene:scene];
}

+ (NSRect)frameOfController:(id)controller
{
	if(usingTakeTwo)
		// ATV2
		return [controller frame];
	else if(usingFrontRow)
		// 10.5
		return [controller controllerFrame];
	else
		return [[controller masterLayer] frame];
}

+ (void)setText:(NSString *)text withAtrributes:(NSDictionary *)attributes forControl:(BRTextControl *)control
{
	if(usingFrontRow)
		[control setText:text withAttributes:attributes];
	else
	{
		if(attributes != nil)
			[control setTextAttributes:attributes];
		[control setText:text];
	}
}

+ (NSSize)textControl:(BRTextControl *)text renderedSizeWithMaxSize:(NSSize)maxSize
{
	if(usingTakeTwo)
		return [text renderedSizeWithMaxSize:maxSize];
	
	[text setMaximumSize:maxSize];
	return [text renderedSize];
}

+ (void)addDividerAtIndex:(int)index toList:(BRListControl *)list
{
	if(usingFrontRow)
		[list addDividerAtIndex:index withLabel:@""];
	else
		[list addDividerAtIndex:index];
}

+ (void)addSublayer:(id)sub toControl:(id)controller
{
	if(usingFrontRow) {
    // ATV2
    if(NSClassFromString(@"BRPanel") == nil)
      [controller addControl:sub];
    // 10.5
    else
      [[controller layer] addSublayer:sub];
  }
	else
		[[controller masterLayer] addSublayer:sub];
}

+ (void)insertSublayer:(id)sub toControl:(id)controller atIndex:(long)index {
  if(usingFrontRow) {
    // ATV2
    if(NSClassFromString(@"BRPanel") == nil)
      [controller insertControl:sub atIndex:index];
    // 10.5
    else
      [[controller layer] insertSublayer:sub atIndex:index];
  } else
    [[controller masterLayer] insertSublayer:sub atIndex:index];
}

+ (BRHeaderControl *)newHeaderControlWithScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
		return [[BRHeaderControl alloc] init];
	else
		return [[BRHeaderControl alloc] initWithScene:scene];
}

+ (BRButtonControl *)newButtonControlWithScene:(BRRenderScene *)scene  masterLayerSize:(NSSize)size;
{
	if(usingFrontRow)
		return [[SapphireButtonControl alloc] initWithMasterLayerSize:size];
	else
		return [[BRButtonControl alloc] initWithScene:scene masterLayerSize:size];
}

+ (BRTextControl *)newTextControlWithScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
		return [[BRTextControl alloc] init];
	else
		return [[BRTextControl alloc] initWithScene:scene];
}

+ (BRTextEntryControl *)newTextEntryControlWithScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
	{
		if(usingTakeTwoDotTwo)
			return [[BRTextEntryControl alloc] initWithTextEntryStyle:1];
		return [[BRTextEntryControl alloc] initWithTextEntryStyle:0];
	}
	else
		return [[BRTextEntryControl alloc] initWithScene:scene];
}

+ (BRProgressBarWidget *)newProgressBarWidgetWithScene:(BRRenderScene *)scene
{
	if(usingFrontRow)
		return [[BRProgressBarWidget alloc] init];
	else
		return [[BRProgressBarWidget alloc] initWithScene:scene];
}

+ (BRMarchingIconLayer *)newMarchingIconLayerWithScene:(BRRenderScene *)scene
{
	if(usingTakeTwo)
		return nil;
	if(usingFrontRow)
		return [[BRMarchingIconLayer alloc] init];
	else
		return [[BRMarchingIconLayer alloc] initWithScene:scene];
}

+ (BRImageLayer *)newImageLayerWithScene:(BRRenderScene *)scene {
  // 10.5
  if(usingFrontRow && NSClassFromString(@"BRImageLayer") != nil) 
    return [[BRImageLayer alloc] init];
  // ATV2
  else if(usingFrontRow)
    return [[NSClassFromString(@"BRImageControl") alloc] init];
  else
    return [BRImageLayer layerWithScene:scene];
}

+ (void)setImage:(id)image forLayer:(BRImageLayer *)layer {
  if(usingFrontRow)
    // this cast is not proper, it just makes a warning disappear.
    [layer setImage:(CGImageRef)image];
  else
    [layer setTexture:image];
}

+ (BRImageLayer *)newImageLayerWithImage:(id)image scene:(BRRenderScene *)scene {
  BRImageLayer *result = [self newImageLayerWithScene:scene];
  [self setImage:image forLayer:result];
  return result;
}

+ (void)renderScene:(BRRenderScene *)scene
{
	if(!usingFrontRow)
		[scene renderScene];
}

+ (BRAlertController *)alertOfType:(int)type titled:(NSString *)title primaryText:(NSString *)primaryText secondaryText:(NSString *)secondaryText withScene:(BRRenderScene *)scene {
  if(usingFrontRow)
    return [BRAlertController alertOfType:type
                                   titled:title
                              primaryText:primaryText
                            secondaryText:secondaryText];
  else
    return [BRAlertController alertOfType:type
                                   titled:title
                              primaryText:primaryText
                            secondaryText:secondaryText
                                    withScene:scene];
}

+ (BROptionDialog *)newOptionDialogWithScene:(BRRenderScene *)scene {
  if(usingFrontRow)
    return [[BROptionDialog alloc] init];
  else
    return [[BROptionDialog alloc] initWithScene:scene];
}

+ (void)setOptionDialogPrimaryInfoText:(NSString *)primaryInfoText withAttributes:(NSDictionary *)attributes optionDialog:(BROptionDialog *)dialog {
  if(usingFrontRow) {
    [dialog setPrimaryInfoText:primaryInfoText withAttributes:attributes];
  } else {
    [dialog setPrimaryInfoText:primaryInfoText];
    [dialog setPrimaryInfoTextAttributes:attributes];
  }
}

+ (BRTextWithSpinnerController *)newTextWithSpinnerControllerTitled:(NSString *)title text:(NSString *)text isNetworkDependent:(BOOL)networkDependent scene:(BRRenderScene *)scene {
  if(usingFrontRow)
    return [[BRTextWithSpinnerController alloc] initWithTitle:title text:text isNetworkDependent:networkDependent];
  else
    return [[BRTextWithSpinnerController alloc] initWithScene:scene title:title text:text showBack:NO isNetworkDependent:NO];
}

+ (void)setSpinner:(BRWaitSpinnerControl *)spinner toSpin:(BOOL)spin
{
	if([spinner respondsToSelector:@selector(setSpins:)])
		[spinner setSpins:spin];
	else if([spinner respondsToSelector:@selector(startSpinning)])
	{
		if(spin)
			[spinner startSpinning];
		else
			[spinner stopSpinning];
	}
}

+ (NSArray *)callStackReturnAddressesForException:(NSException *)exception
{
	if([exception respondsToSelector:@selector(callStackReturnAddresses)])
	{
		NSArray *ret = [exception callStackReturnAddresses];
		if([ret count])
			return ret;
	}
	return [[exception userInfo] objectForKey:NSStackTraceKey];
}

+ (RUIPreferences *)sharedFrontRowPreferences {
  Class preferencesClass = NSClassFromString(@"RUIPreferences");
  if(!preferencesClass) preferencesClass = NSClassFromString(@"BRPreferences");
  
  if(preferencesClass)
    return [preferencesClass sharedFrontRowPreferences];
  else
    return nil;
}

@end
