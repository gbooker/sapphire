//
//  SapphireMovieChooser.m
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMovieChooser.h"
#import "SapphireFrontRowCompat.h"
#import	"SapphireTheme.h"


@implementation SapphireMovieChooser

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	selection = -1;
	
	/* Set a control to display the fileName */
	fileNameText = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:@"File:" withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileNameText];
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	//	frame.size.height = frame.size.height / 16.0f;
	//	frame.size.width = frame.size.width * 2.0f / 3.0f;
	frame.origin.y = frame.size.height / 1.25f;
	frame.origin.x = (frame.size.width / 4.0f) ;
	[fileNameText setFrame: frame];
	
	[self addControl: fileNameText];	
	[[self list] setDatasource:self];
	
	return self;
}

- (void)dealloc
{
	[movies release];
	[fileName release];
	[super dealloc];
}

- (NSArray *)movies
{
	return movies;
}

- (void)setMovies:(NSArray *)movieList
{
	movies = [movieList retain];
	[[self list] reload];
	[SapphireFrontRowCompat addDividerAtIndex:1 toList:[self list]];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (void)setFileName:(NSString*)choosingForFileName
{
	fileName=[choosingForFileName retain] ;
	[SapphireFrontRowCompat setText:choosingForFileName withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileNameText];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileNameText setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [fileNameText renderedSize];
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.44f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
	frame.size = txtSize;
	[fileNameText setFrame:frame];
}

- (NSString *)fileName
{
	return fileName;
}

- (void)willBePushed
{
	[super willBePushed];
	[(BRListControl *)[self list] setSelection:1];
}

- (int)selection
{
	return selection - 1;
}

- (long) itemCount
{
	return [movies count] + 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser") forMenu:result];
	else
	{
		/*Put in the movie results*/
		[SapphireFrontRowCompat setTitle:[NSString stringWithFormat:@"  %@",[[movies objectAtIndex:row-1] objectForKey:@"name"]] forMenu:result];
		[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
	}
	return result;
}

- (NSString *) titleForRow: (long) row
{
	if(row > [movies count])
		return nil;
	
	if(row == 0)/*Put in the special "this is not a movie"*/
		return BRLocalizedString(@"<This is NOT a Movie>", @"Mark a file that is not a movie in the movie chooser");
	else
		/*Put in the movie*/
		return [[movies objectAtIndex:row-1] objectForKey:@"name"];
}


- (void) itemSelected: (long) row
{
	/*User made selection, let's exit*/
	selection = row;
	[[self stack] popController];
}

@end
