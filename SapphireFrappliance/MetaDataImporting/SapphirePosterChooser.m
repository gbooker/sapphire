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
#import "SapphireFileMetaData.h"
#import	"SapphireSettings.h"
#import "SapphireMediaPreview.h"
#import "SapphireMedia.h"
#import "SapphireWaitDisplay.h"
#import "SapphireDirectoryMetaData.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireApplianceController.h"
#import "SapphireURLLoader.h"

#import "NSImage-Extensions.h"

NSData *CreateBitmapDataFromImage(CGImageRef image, unsigned int width, unsigned int height);

@interface BRListControl (definedin1_1)
- (double)renderSelection;
@end

@interface SapphirePosterChooser ()
- (BRBlurryImageLayer *)getPosterLayerForData:(NSData *)thePosterData;
- (void)loadPosters;
- (void)loadPosterWithURL:(int)index;
- (void)reloadPosterWithDataAtIndex:(int)intIndex;
@end

@implementation SapphirePosterChooser

- (id)initWithScene:(BRRenderScene *)scene
{
	self = [super initWithScene: scene];
	if(!self)
		return nil;
	selection = SapphireChooserChoiceCancel;
	
	// we want to know when the list selection changes, so we can pass
    // that information on to the icon march layer
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(selectionChanged:)
                                                 name: @"ListControlSelectionChangedNotification"
                                               object: [self list]];
	
	/* Set a control to display the fileName */
	fileInfoText = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:@"No File" withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileInfoText];
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f);
	NSString *defaultPosterPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PH" ofType:@"png"];
	NSData *defaultPosterData = [NSData dataWithContentsOfFile:defaultPosterPath];
	defaultImage = [[self getPosterLayerForData:defaultPosterData] retain];
	defaultNSImage = [[NSImage alloc] initWithContentsOfFile:defaultPosterPath];
	NSString *errorPosterPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
	NSData *errorPosterData = [NSData dataWithContentsOfFile:errorPosterPath];
	errorImage = [[self getPosterLayerForData:errorPosterData] retain];
	errorNSImage = [[NSImage alloc] initWithContentsOfFile:errorPosterPath];
	
	
	[fileInfoText setFrame: frame];
	[self addControl: fileInfoText];
	
	/* Setup posterMarch controls */
	posterMarch = [SapphireFrontRowCompat newMarchingIconLayerWithScene:scene];
	[SapphireLayoutManager setCustomLayoutOnControl:self];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [posterMarch removeFromSuperlayer];
//    [posterMarch setIconSource: nil];  //This throws an exception
	[posters release];
	[fileName release];
	[movieTitle release];
	[fileInfoText release];
	[posterMarch release];
	[defaultImage release];
	[defaultNSImage release];
	[errorImage release];
	[errorNSImage release];
	[meta release];
	[super dealloc];
}

#pragma mark Layout

- (void)resetLayout
{
    [super resetLayout];
	[SapphireFrontRowCompat renderScene:[self scene]];
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

- (void)setRefreshInvokation:(NSInvocation *)invoke;
{
	[refreshInvoke release];
	refreshInvoke = [invoke retain];
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

#pragma mark Display

- (BOOL)okayToDisplay
{
	if([[self list] respondsToSelector:@selector(renderSelection)] || [SapphireFrontRowCompat usingLeopardOrATypeOfTakeTwo])
		return [[SapphireSettings sharedSettings] displayPosterChooser];
	else
		return NO;
}

#pragma mark List of posters

- (void)freePosterMarch
{
	[posterMarch release];
	posterMarch = nil;
}

- (void)setPosters:(NSArray *)posterList
{
	posters = [posterList mutableCopy];
	if([posters count] > 5)
		[self freePosterMarch];
	else
	{
		[posterMarch setIconSource: self];
	}
	[self loadPosters];
	[[self list] setDatasource:self];
}

- (void)setPosterImages:(NSArray *)posterList
{
	posters = [posterList retain];

	[self freePosterMarch];
	[[self list] setDatasource:self];
}

- (NSArray *)posters
{
	return posters;
}

- (void)loadPosters
{
	int i, count = [posters count];
	for(i=0; i<count; i++)
		[self loadPosterWithURL:i];
	[posterMarch reload];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

/*!
 * @brief load poster image layers
 *
 * @param The index of the poster to load
 */
- (void)loadPosterWithURL:(int)index;
{
	NSString *posterURL = [posters objectAtIndex:index];
	[[SapphireApplianceController urlLoader] loadDataURL:posterURL withTarget:self selector:@selector(gotPosterData:atIndex:) object:[NSNumber numberWithInt:index] withPriority:YES];
}

- (void)gotPosterData:(NSData *)data atIndex:(NSNumber *)index;
{
	if(data != nil)
		[posters replaceObjectAtIndex:[index intValue] withObject:data];
	else
		[posters replaceObjectAtIndex:[index intValue] withObject:[NSData data]];
	if(displayed && posterMarch)
		[self reloadPosterWithDataAtIndex:[index intValue]];
}

- (void)reloadPosterWithDataAtIndex:(int)intIndex;
{
	NSData *data = [posters objectAtIndex:intIndex];
	[posters replaceObjectAtIndex:intIndex withObject:[self getPosterLayerForData:data]];
	[posterMarch _updateIcons];
	if(intIndex == 0 || [self getSelection] == intIndex)
		[self resetPreviewController];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

#pragma mark Filename and file

- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain];
	if(movieTitle)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:fileName withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileInfoText];
}

- (NSString *)fileName
{
	return fileName;
}

- (void)setFile:(SapphireFileMetaData *)aMeta;
{
	[meta release];
	meta = [aMeta retain];
}

#pragma mark Title

- (void)setMovieTitle:(NSString *)theMovieTitle
{
	movieTitle = [theMovieTitle retain];
	if(fileName)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:movieTitle withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileInfoText];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:fileInfoText renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
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

- (SapphireChooserChoice)selection
{
	return selection;
}

#pragma mark Icon march

- (BRBlurryImageLayer *)getPosterLayerForData:(NSData *)thePosterData
{
	if(thePosterData == nil)
		return defaultImage;
	
	if([SapphireFrontRowCompat usingLeopardOrATypeOfTakeTwo])
	{
		/*The marching icons has changed, dramatically, so we do the changes here*/
		id ret = [SapphireFrontRowCompat imageFromData:thePosterData];
		if(ret != nil)
			return ret;
		else
			return errorImage;
	}
	CGImageRef posterImage=NULL;
	CGImageSourceRef  sourceRef;	
    sourceRef = CGImageSourceCreateWithData((CFDataRef)thePosterData, NULL);
    if(sourceRef) {
        posterImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
    if(posterImage==nil)
		return errorImage;
	
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
	
    return result;
}

- (void)hideIconMarch
{
	/* Might want to free memory here since posters won't be chosen again */
    [posterMarch removeFromSuperlayer];
}

- (void)showIconMarch
{
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
    frame.size.width *= 0.50f;
	if(![SapphireFrontRowCompat usingLeopardOrATypeOfTakeTwo])
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
- (long)iconCount
{
	return [posters count];
}

- (NSDictionary *)iconInfoAtIndex:(long)index
{
	id poster = [posters objectAtIndex:index];
	if([poster isKindOfClass:[NSString class]] || [poster isKindOfClass:[NSData class]])
		poster = defaultImage;
	return [NSDictionary dictionaryWithObject:poster forKey:@"icon"];
}

- (id)iconAtIndex:(long)index
{
    if ( index >= [posters count] )
        return nil;
	
    return [posters objectAtIndex:index];
}


- (long)itemCount
{
	if ( refreshInvoke != nil ) 
		return [posters count] + 1;
	
	return [posters count];
}

#pragma mark Preview display

- (id<BRMediaPreviewController>)previewControlForItem:(long)row
{
	if(posterMarch != nil)
		return nil;
	
	SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
	[preview setShowsMetadataImmediately:YES];
	
	if ( row < [posters count] )
	{
		[preview setMetaData:meta inMetaData:[meta parent]];
		[preview setImageOnly:YES];
		
		SapphireMedia *asset = [[SapphireMedia alloc] initWithMediaURL:[NSURL fileURLWithPath:@"none"]];
		id poster = [posters objectAtIndex:row];
		
		if([poster isKindOfClass:[NSImage class]])
			[asset setImage:poster];
		else if([poster isKindOfClass:[NSData class]])
		{
			NSImage *image = [[NSImage alloc] initWithData:poster];
			if(image)
			{
				[asset setImage:image];
				[image release];
			}
			else
				[asset setImage:errorNSImage];
		}
		else
			[asset setImage:defaultNSImage];
		
		[preview setAsset:asset];
		[asset release];
	}
	else if(row == [posters count])
	{
		NSMutableDictionary *refreshMeta = [NSMutableDictionary dictionary];
		[refreshMeta setObject: BRLocalizedString( @"Refresh the artwork selection", @"Refresh the artwork selection" ) forKey: META_TITLE_KEY];
		[preview setUtilityData: refreshMeta];
	}
	
	return [preview autorelease];
}

- (id<BRMediaPreviewController>)previewControllerForItem:(long)row
{
	return [self previewControlForItem:row];
}

#pragma mark Menu list

- (id)itemForRow:(long)row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	if ( refreshInvoke != nil && row == [posters count] )
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"Refresh", @"Reload images") forMenu:result];
	else
		[SapphireFrontRowCompat setTitle:[NSString stringWithFormat:@"Version %2d",row+1] forMenu:result];
	return result;
}

- (NSString *)titleForRow:(long)row
{
	if(row > [posters count])
		return nil;
	
	if (refreshInvoke != nil && row == [posters count])
		return BRLocalizedString(@"Refresh", @"Reload images");
	
	return [NSString stringWithFormat:@"Version %2d",row+1];
}

- (long)rowForTitle:(NSString *)title
{
    long result = -1;
    long i, count = [self itemCount];
    for(i=0; i<count; i++)
    {
        if([title isEqualToString:[self titleForRow:i]])
		{
            result = i;
            break;
		}
    }
    return result;
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

- (void)selectionChanged:(NSNotification *)note
{
	/* ATV version 1.1 */
	if([(BRListControl *)[note object] respondsToSelector:@selector(renderSelection)])
		[self setSelectionForPoster:[(BRListControl *)[note object] renderSelection]];
	/* ATV version 1.0 */
	else
		[self setSelectionForPoster:[(BRListControl *)[note object] selection]];
}

- (BRLayerController *)doRefresh
{
	[refreshInvoke invoke];
	BRLayerController *ret = nil;
	[refreshInvoke getReturnValue:&ret];
	return ret;
}

- (void)itemSelected:(long)row
{
	/*User made a selection*/
	if ( refreshInvoke != nil && row == [posters count] )
	{
		NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector: @selector(doRefresh)]];
		[invoke setSelector: @selector(doRefresh)];
		[invoke setTarget:   self];
		
		SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene: [self scene]
																		 title: BRLocalizedString(@"Getting artwork selection", @"Getting artwork selection")
																	invokation: invoke];
		[[self stack] swapController:[wait autorelease]];
	}
	else
	{
		selection = row;
		SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
		NSEnumerator *posterEnum = [posters objectEnumerator];
		NSString *posterURL;
		while((posterURL = [posterEnum nextObject]) != nil)
		{
			if(![posterURL isKindOfClass:[NSString class]])
				continue;
			
			[loader cancelLoadOfURL:posterURL forTarget:self];
		}
		[[self stack] popController];
	}
}

#pragma mark Pushing and popping

- (void)willBePushed
{
	[self showIconMarch];
    // always call super
    [super willBePushed];
}

- (void)wasPushed
{
	[self doMyLayout];
	[[self list] reload];
	[super wasPushed];
	displayed = YES;
	if(posterMarch)
	{
		int i, count = [posters count];
		for(i=0; i<count; i++)
		{
			id obj = [posters objectAtIndex:i];
			if([obj isKindOfClass:[NSData class]])
				[self reloadPosterWithDataAtIndex:i];
		}
	}
}

- (void)wasPopped
{
    // The user pressed Menu, removing us from the screen
    // always call super
    [super wasPopped];
    // remove the icon march from the scene
    [self hideIconMarch];
}

@end
