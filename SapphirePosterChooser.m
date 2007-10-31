//
//  SapphirePosterChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphirePosterChooser.h"
#import "SapphireFrontRowCompat.h"

NSData *CreateBitmapDataFromImage(CGImageRef image, unsigned int width, unsigned int height);

@interface BRListControl (definedin1_1)
- (double)renderSelection;
@end

@implementation SapphirePosterChooser

/*!
* @brief Creates a new poster chooser
 *
 * @param scene The scene
 * @return The chooser
 */
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
	defaultImage = [[self getPosterLayer:[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingString:@"/Contents/Resources/PH.png"]] retain];

	
	[fileInfoText setFrame: frame];
	[self addControl: fileInfoText];
	
	/* Setup posterMarch controls */
	posterMarch = [SapphireFrontRowCompat newMarchingIconLayerWithScene:scene];
    [posterMarch setIconSource: self];
	
	[[self list] setDatasource:self];
	
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
- (void)_doLayout
{
	//Shrink the list frame to make room for displaying the filename
	[super _doLayout];
	NSRect listFrame = [[_listControl layer] frame];
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*= 0.45f;
	listFrame.origin.y *= 2.0f;
	listFrame.origin.x *= 1.4f;
	[[_listControl layer] setFrame:listFrame];
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

/*!
* @brief The list of movies to choose from
 *
 * @return The list of movies to choose from
 */
- (NSArray *)posters
{
	return posters;
}

/*!
* @brief Sets the posters to choose from
 *
 * @param posterList The list of movies to choose from
 */
- (void)setPosters:(NSArray *)posterList
{
	posters = [posterList retain];
	[self loadPosters];
}

/*!
 * @brief Loads the posters from disk
 */
- (void)loadPosters
{
	int i, count = [posters count];
	posterLayers = [posters mutableCopy];
	for(i=0; i<count; i++)
		[self loadPoster:i];
	[posterMarch _updateIcons] ;
	[SapphireFrontRowCompat renderScene:[self scene]];
}

/*!
 * @brief Reloads a poster from disk
 *
 * @param index The index of the poster to reload
 */
- (void)reloadPoster:(int)index
{
	[self loadPoster:index];
	[posterMarch _updateIcons] ;
	[SapphireFrontRowCompat renderScene:[self scene]];
}

/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain];
	if(movieTitle)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:fileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
}

/*!
* @brief The filename we searched for
 *
 * @return The file name we searched for
 */
- (NSString *)fileName
{
	return fileName;
}

/*!
* @brief Sets the string we searched for
 *
 * @param search The string we searched for
 */
- (void)setMovieTitle:(NSString *)theMovieTitle
{
	movieTitle = [theMovieTitle retain];
	if(fileName)
		[SapphireFrontRowCompat setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName] withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
	else
		[SapphireFrontRowCompat setText:movieTitle withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileInfoText];
}

/*!
* @brief The string we searched for
 *
 * @return The string we searched for
 */
- (NSString *)movieTitle
{
	return movieTitle;
}

/*!
* @brief The item the user selected.  Special values are in the header file
 *
 * @return The user's selection
 */
- (long)selectedPoster
{
	return selectedPoster;
}
@end


@implementation SapphirePosterChooser (IconDataSource)

- (long) iconCount
{
		return [posterLayers count];
}

- (BRRenderLayer *) iconAtIndex: (long) index
{
    if ( index >= [posterLayers count] )
        return ( nil );
	
    return [posterLayers objectAtIndex:index];
}

@end

@implementation SapphirePosterChooser (ListDataSource)

- (long) itemCount
{
	return [posters count];
}


- (id<BRMenuItemLayer>) itemForRow: (long) row
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

@end

@implementation SapphirePosterChooser (IconListManagement)

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
    NSRect frame = [[self masterLayer] frame];
    frame.size.width *= 0.50f;
	frame.size.height *= 1.7f;
	frame.origin.y=-200.0f;
    [posterMarch setFrame: frame];	
    [[[self scene] root] insertSublayer: posterMarch below: [self masterLayer]];
}

- (void) selectionChanged: (NSNotification *) note
{
	/* ATV version 1.1 */
	if([(BRListControl *)[note object] respondsToSelector:@selector(renderSelection)])
		[posterMarch setSelection: [(BRListControl *)[note object] renderSelection]];
	/* ATV version 1.0 */
	else
		[posterMarch setSelection: [(BRListControl *)[note object] selection]];
}
@end
