//
//  SapphirePopulateDataMenu.m
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphirePopulateDataMenu.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"

@interface SapphirePopulateDataMenu (private)
- (void)setText:(NSString *)theText;
- (void)resetUIElements;
@end

@implementation SapphirePopulateDataMenu
- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData
{
	if ( [super initWithScene: scene] == nil )
	return ( nil );
	meta = [metaData retain];
	// Setup the Header Control with default contents
	title = [[BRHeaderControl alloc] initWithScene: scene];
	[title setTitle: @"Populate Show Data"];
	NSRect frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[title setFrame: frame];
	
	
	// Setup the Header Control with default contents
//	_warning = [[BRTextWithSpinnerController alloc] initWithScene: scene title:@"Test" text:@"Body" showBack:TRUE];
//	[_warning setTitle: @"Depending on the size of your TV show collection, this could take several minutes."];
//	[_warning setTitle:@"This can take several minutes"];
//	[_warning showProgress:TRUE ] ;
//	NSRect frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
//	[_warning setFrame: frame];
	
	

	// setup the button control
	frame = [[self masterLayer] frame];
	button = [[BRButtonControl alloc] initWithScene: scene masterLayerSize: frame.size];
	[button setYPosition: frame.origin.y + (frame.size.height * (1.0f / 8.0f))];

	// setup the text entry control
	text = [[BRTextControl alloc] initWithScene: scene];
	
	bar = [[BRProgressBarWidget alloc] initWithScene: scene];
	frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 5.0f / 16.0f;
	frame.origin.x = frame.size.width / 6.0f;
	frame.size.height = frame.size.height / 16.0f;
	frame.size.width = frame.size.width * 2.0f / 3.0f;
	[bar setFrame: frame] ;
	
	[self resetUIElements];
	
	// add controls

	[self addControl: title];
	[self addControl: text];
	[[self masterLayer] addSublayer:bar];
	[self addControl: button];

    return ( self );
}

- (void)setText:(NSString *)theText
{
	[text setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[text setText:theText];
	
	NSRect master = [[self masterLayer] frame];
	[text setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [text renderedSize];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.4f - txtSize.height) + master.size.height * 0.3f/0.8f;
	frame.size = txtSize;
	[text setFrame:frame];
}

- (void) dealloc
{
    [title release];
    [text release];
	[bar release];
    [button release];
	[meta release];
	[importTimer invalidate];

    [super dealloc];
}

- (void)import
{
	current = 0;
	importItems = [[meta subFileMetas] mutableCopy];
	max = [importItems count];
	[button setTitle:@"Cancel Import"];
	[button setAction:@selector(cancel)];
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

- (void)importNextItem:(NSTimer *)timer
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	[fileMeta updateMetaData];
	[importItems removeObjectAtIndex:0];
	current++;
	[bar setPercentage:current/max * 100.0f];
	
	if(![importItems count])
	{
		[importTimer invalidate];
		importTimer = nil;
		[meta writeMetaData];
		[button setHidden:YES];
		[button setTarget:nil];
		[self setText:@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported"];
	}
	[[self scene] renderScene];
}

- (void)cancel
{
	[importTimer invalidate];
	importTimer = nil;
	[self resetUIElements];
	[meta writeMetaData];
}

- (void)resetUIElements
{
	[self setText:@"This will populate Sapphire's Meta data.  This proceedure may take a while, but you may cancel at any time"];
	[bar setPercentage:0.0f];
	[button setTitle: @"Import Meta Data"];
	[button setTarget:self];
	[button setAction: @selector(import)];
	[button setHidden:NO];
}

- (void)wasPopped
{
	[self cancel];
	[super wasPopped];
}

@end
