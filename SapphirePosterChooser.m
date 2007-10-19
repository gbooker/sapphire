//
//  SapphirePosterChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphirePosterChooser.h"
#import "BackRowUtils.h"
#import <BackRow/BackRow.h>


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
	fileInfoText = [[BRTextControl alloc] initWithScene: scene];
	[fileInfoText setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileInfoText setText:@"No File"];
	NSRect 	frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f) ;
	
	[fileInfoText setFrame: frame];
	[self addControl: fileInfoText];
	
	/* Setup posterMarch controls */
	posterMarch = [[BRMarchingIconLayer alloc] initWithScene: scene];
    [posterMarch setIconSource: self];
	
	[[self list] setDatasource:self];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[posters release];
	[posterLayers release];
	[fileName release];
	[movieTitle release];
	[fileInfoText release];
    [posterMarch setIconSource: nil];
    [posterMarch removeFromSuperlayer];
	[posterMarch release];
	[super dealloc];
}

- (void) resetLayout
{
    [super resetLayout];
	
    // reset the frame for the icon march layer
    NSRect marchFrame = [[self masterLayer] frame];
    marchFrame.size.width *= 0.56f;
    [posterMarch setFrame: marchFrame];
//	[self loadPosters];
//	[posterMarch _updateIcons];
    [[self scene] renderScene];
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
	listFrame.origin.y *= 2.0f;
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
	[posterMarch _updateIcons] ;
	[[self scene] renderScene];
}

/*!
* @brief Sets the filename to display
 *
 * @param choosingForFileName The filename being choosen for
 */
- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain];
	[fileInfoText setTextAttributes: [[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	if(movieTitle)
	{
		[fileInfoText setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName]];
	}
	else
		[fileInfoText setText:fileName];	
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
	[fileInfoText setTextAttributes: [[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	if(fileName)
	{
		[fileInfoText setText:[NSString stringWithFormat:@"%@ (%@)",movieTitle,fileName]];
	}
	else
		[fileInfoText setText:movieTitle];		
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
	BRAdornedMenuItemLayer *result = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	//	if(row==0)
	//		[[result textItem] setTitle:BRLocalizedString(@"< Refresh Posters >", @"Reload poster images")];
	//	else
	[[result textItem] setTitle:[NSString stringWithFormat:@"Version %2d",row+1]];
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
 */
- (void) loadPosters
{
	NSMutableArray * results = [NSMutableArray array];
//	NSFileManager *fileAgent=[NSFileManager defaultManager];
	if([posters count])
	{
		/*Get each result*/
		NSEnumerator *resultEnum = [posters objectEnumerator];
		NSString *result = nil;
		while((result = [resultEnum nextObject]) != nil)
		{
			NSString *posterPath=[NSString stringWithFormat:@"%@/%@",
				[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/Poster_Buffer"],
				[result lastPathComponent]];
//			BOOL wait=YES ;
//			while(wait)
//			{
//				wait=![fileAgent fileExistsAtPath:posterPath] ;
//			}
			[results addObject:[self getPosterLayer:posterPath]];
		}
	}
	posterLayers=[results copy];
}

- (BRBlurryImageLayer *) getPosterLayer: (NSString *) thePosterPath
{	
    NSURL * posterURL = [NSURL fileURLWithPath: thePosterPath];
    if (posterURL==nil)
        return nil;
	
    CGImageRef posterImage = CreateImageForURL( posterURL );
    if(posterImage==nil)
        return nil;
	
    struct BRBitmapDataInfo info;
    info.internalFormat = GL_RGBA;
    info.dataFormat = GL_BGRA;
    info.dataType = GL_UNSIGNED_INT_8_8_8_8_REV;
    info.width = 510;
    info.height = 755;
	
    BRRenderContext * context = [[self scene] resourceContext];
	
	
    NSData * data = CreateBitmapDataFromImage( posterImage, info.width, info.height );
    BRBitmapTexture * lucid = [[BRBitmapTexture alloc] initWithBitmapData: data
															   bitmapInfo: &info context: context mipmap: YES];
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
    [posterMarch removeFromSuperlayer];
}

- (void) showIconMarch
{
    NSRect frame = [[self masterLayer] frame];
    frame.size.width *= 0.56f;
//	frame.size.height *= 0.80f;
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
