/*
 * SapphirePosterChooser.m
 * Sapphire
 *
 * Created by Patrick Merrill on Oct. 11, 2007.
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

#import "SapphirePosterChooser.h"
#import "SapphireMetaData.h"
#import	"SapphireSettings.h"
#import "SapphireMediaPreview.h"
#import "SapphireMedia.h"
#import "SapphireMetaData.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

NSData *CreateBitmapDataFromImage(CGImageRef image, unsigned int width, unsigned int height);

@interface BRListControl (definedin1_1)
- (double)renderSelection;
@end

@interface SapphirePosterChooser (private)
- (BRBlurryImageLayer *) getPosterLayer: (NSString *) thePosterPath;
- (void) loadPoster:(int)index;
- (void) hideIconMarch;
- (void) showIconMarch;
- (void) selectionChanged: (NSNotification *) note;
@end

@implementation SapphirePosterChooser

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene: scene];
	if(!self)
		return nil;
	selectedPoster = -1;
	
	// we want to know when the list selection changes, so we can pass
    // that information on to the icon march layer
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(selectionChanged:)
                                                 name: @"ListControlSelectionChangedNotification"
                                               object: [self list]];
	
	/* Set a control to display the fileName */
	fileInfoText = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:@"No File" withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f) ;
	defaultImage = [[self getPosterLayer:[[NSBundle bundleForClass:[self class]] pathForResource:@"PH" ofType:@"png"]] retain];

	
	[fileInfoText setFrame: frame];
	[self addControl: fileInfoText];
	
	/* Setup posterMarch controls */
	posterMarch = [SapphireFrontRowCompat newMarchingIconLayerWithScene:scene];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [posterMarch removeFromSuperlayer];
//    [posterMarch setIconSource: nil];  //This throws an exception
	[posters release];
	[posterLayers release];
	[fileName release];
	[movieTitle release];
	[fileInfoText release];
	[posterMarch release];
	[defaultImage release];
	[meta release];
	[super dealloc];
}

- (void) resetLayout
{
    [super resetLayout];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (void) willBePushed
{
    // We're about to be placed on screen, but we're not yet there
    // add the icon march layer to the scene
    [self showIconMarch];
    
    // always call super
    [super willBePushed];
}

- (void)doMyLayout
{
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:fileInfoText renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.44f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileInfoText setFrame:frame];
}

- (void)wasPushed
{
	[self doMyLayout];
	[[self list] reload];
	[super wasPushed];
}

- (void) wasPopped
{
    // The user pressed Menu, removing us from the screen
    // always call super
    [super wasPopped];
    // remove the icon march from the scene
    [self hideIconMarch];
}

/*!
 * @brief Override the layout
 *
 */
- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master
{
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*= 0.45f;
	listFrame.origin.x = (master.size.width - listFrame.size.width) * 0.85f;
	listFrame.origin.y = (master.size.height * 0.3f - listFrame.size.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	return listFrame;
}

- (void) itemSelected: (long) row
{
	/*User made a selection*/
	//	if(selection==0)
	//	{
	/*User requested a menu refresh*/
	//		[self resetLayout];
	//	}
	//	else
	//	{
	selectedPoster = row;
	[[self stack] popController];
	//	}
}

- (BOOL)okayToDisplay
{
	if([[self list]respondsToSelector:@selector(renderSelection)] || [SapphireFrontRowCompat usingFrontRow])
		return [[SapphireSettings sharedSettings] displayPosterChooser];
	else
		return NO;
}

- (NSArray *)posters
{
	return posters;
}

- (void)setPosters:(NSArray *)posterList
{
	posters = [posterList retain];
	[self loadPosters];
    [posterMarch setIconSource: self];
	[[self list] setDatasource:self];
}

- (void)loadPosters
{
	int i, count = [posters count];
	posterLayers = [posters mutableCopy];
	for(i=0; i<count; i++)
		[self loadPoster:i];
	[posterMarch reload] ;
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (void)reloadPoster:(int)index
{
	[self loadPoster:index];
	[posterMarch _updateIcons] ;
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain];
	if(movieTitle)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:fileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
}

- (void)setFile:(SapphireFileMetaData *)aMeta;
{
	[meta release];
	meta = [aMeta retain];
}

- (NSString *)fileName
{
	return fileName;
}

- (void)setMovieTitle:(NSString *)theMovieTitle
{
	movieTitle = [theMovieTitle retain];
	if(fileName)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:movieTitle withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileInfoText setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [fileInfoText renderedSize];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.44f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileInfoText setFrame:frame];
}

- (NSString *)movieTitle
{
	return movieTitle;
}

- (long)selectedPoster
{
	return selectedPoster;
}

- (long) iconCount
{
	return [posterLayers count];
}

- (NSDictionary *) iconInfoAtIndex: (long) index
{
	return [NSDictionary dictionaryWithObject:[posterLayers objectAtIndex:index] forKey:@"icon"];
}

- (id) iconAtIndex: (long) index
{
    if ( index >= [posterLayers count] )
        return nil;
	
    return [posterLayers objectAtIndex:index];
}


- (long) itemCount
{
	return [posters count];
}


- (id) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	//	if(row==0)
	//		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"< Refresh Posters >", @"Reload poster images") forMenu:result];
	//	else
	[SapphireFrontRowCompat setTitle:[NSString stringWithFormat:@"Version %2d",row+1] forMenu:result];
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [posters count])
		return nil;
	else
		return [NSString stringWithFormat:@"Version %2d",row+1];
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

/*!
 * @brief load poster image layers
 *
 * @param The index of the poster to load
 */
- (void) loadPoster:(int)index;
{
	NSString *poster = [posters objectAtIndex:index];
	NSString *posterDest=[NSString stringWithFormat:@"%@/%@",
		[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"],
		[poster lastPathComponent]];
	[posterLayers replaceObjectAtIndex:index withObject:[self getPosterLayer:posterDest]];
}

- (BRBlurryImageLayer *) getPosterLayer: (NSString *) thePosterPath
{
	if([SapphireFrontRowCompat usingFrontRow])
	{
		/*The marching icons has changed, dramatically, so we do the changes here*/
		id ret = [SapphireFrontRowCompat imageAtPath:thePosterPath];
		if(ret != nil)
			return ret;
		else
			return defaultImage;
	}
    NSURL * posterURL = [NSURL fileURLWithPath: thePosterPath];
	
    if (posterURL==nil)
		return nil;
	CGImageRef posterImage=NULL;
	CGImageSourceRef  sourceRef;	
    sourceRef = CGImageSourceCreateWithURL((CFURLRef)posterURL, NULL);
    if(sourceRef) {
        posterImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
    if(posterImage==nil)
		return defaultImage;
	
    struct BRBitmapDataInfo info;
    info.internalFormat = GL_RGBA;
    info.dataFormat = GL_BGRA;
    info.dataType = GL_UNSIGNED_INT_8_8_8_8_REV;
    info.width = 510;
    info.height = 755;
	
    BRRenderContext * context = [[self scene] resourceContext];
		
    NSData * data = CreateBitmapDataFromImage(posterImage,info.width,info.height );
    BRBitmapTexture * lucid = [[BRBitmapTexture alloc] initWithBitmapData: data
															   bitmapInfo: &info 
																  context: context 
																   mipmap: YES];
    [data release];
	
    BRBitmapTexture * blur = [BRBlurryImageLayer blurredImageForImage: posterImage
                                                            inContext: context
                                                                 size: NSMakeSize(510.0f, 755.0f)];
	
    CFRelease( posterImage );
	
    BRBlurryImageLayer * result = [BRBlurryImageLayer layerWithScene: [self scene]];
	
    [result setLucidImage: lucid withReflection: nil];
    [result setBlurryImage: blur withReflection: nil];
	
    [lucid release];
	
    return ( result );
}

- (void) hideIconMarch
{
	/* Might want to free memory here since posters won't be chosen again */
    [posterMarch removeFromSuperlayer];
}

- (void) showIconMarch
{
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
    frame.size.width *= 0.50f;
	if(![SapphireFrontRowCompat usingFrontRow])
	{
		frame.size.height *= 1.7f;
		frame.origin.y=-200.0f;
	}
	else
		frame.size.height = ([fileInfoText frame].origin.y - frame.origin.y) * 1.2f;
    [posterMarch setFrame: frame];
	if(posterMarch != nil)
		[SapphireFrontRowCompat addSublayer:posterMarch toControl:self];
}

- (void)setSelectionForPoster:(double)sel
{
	if(posterMarch == nil)
		return;
	NSMethodSignature *signature = [posterMarch methodSignatureForSelector:@selector(setSelection:)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(setSelection:)];
	if(strcmp([signature getArgumentTypeAtIndex:2], "l"))
	{
		double dvalue = sel;
		[selInv setArgument:&dvalue atIndex:2];
	}
	else
	{
		long lvalue = sel;
		[selInv setArgument:&lvalue atIndex:2];
	}
	[selInv invokeWithTarget:posterMarch];
}

- (void) selectionChanged: (NSNotification *) note
{
	/* ATV version 1.1 */
	if([(BRListControl *)[note object] respondsToSelector:@selector(renderSelection)])
		[self setSelectionForPoster:[(BRListControl *)[note object] renderSelection]];
	/* ATV version 1.0 */
	else
		[self setSelectionForPoster:[(BRListControl *)[note object] selection]];
}

- (id<BRMediaPreviewController>) previewControlForItem: (long) row
{
	if(posterMarch != nil)
		return nil;
	NSLog(@"Requested preview");
	SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
	SapphireMedia *asset = [[SapphireMedia alloc] initWithMediaURL:[NSURL fileURLWithPath:@"none"]];
	NSString *poster = [posters objectAtIndex:row];
	NSString *posterDest=[NSString stringWithFormat:@"%@/%@",
						  [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"],
						  [poster lastPathComponent]];
	[preview setShowsMetadataImmediately:NO];
	SapphireDirectoryMetaData *parent = (SapphireDirectoryMetaData *)[[meta collection] dataForPath:[[meta path] stringByDeletingLastPathComponent]];
	[preview setMetaData:meta inMetaData:parent];
	[asset setImagePath:posterDest];
	[preview setAsset:asset];
	[asset release];
	NSLog(@"Path is %@", posterDest);
	
	return preview;
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) row
{
	return [self previewControlForItem:row];
}


@end
