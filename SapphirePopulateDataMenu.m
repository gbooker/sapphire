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
- (void)setFileProgress:(NSString *)updateFileProgress;
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
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];

	// setup the button control
	frame = [[self masterLayer] frame];
	button = [[BRButtonControl alloc] initWithScene: scene masterLayerSize: frame.size];
	[button setYPosition: frame.origin.y + (frame.size.height * (1.0f / 8.0f))];

	// setup the text entry control
	text = [[BRTextControl alloc] initWithScene: scene];
	fileProgress = [[BRTextControl alloc] initWithScene: scene];
	currentFile = [[BRTextControl alloc] initWithScene: scene];
	
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
	[self addControl: fileProgress] ;
	[self addControl: currentFile] ;
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

- (void)setFileProgress:(NSString *)theFileProgress
{
	[fileProgress setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[fileProgress setText:theFileProgress];
	
	NSRect master = [[self masterLayer] frame];
	[fileProgress setMaximumSize:NSMakeSize(master.size.width * 1.0f/2.0f, master.size.height * 0.3f)];
	NSSize progressSize = [fileProgress renderedSize];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.05f;
	frame.origin.y = (master.size.height * 0.1f - progressSize.height) ;
	frame.size = progressSize;
	[fileProgress setFrame:frame];
}

- (void)setCurrentFile:(NSString *)theCurrentFile
{
	[currentFile setTextAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	[currentFile setText:theCurrentFile];
	
	NSRect master = [[self masterLayer] frame];
	[currentFile setMaximumSize:NSMakeSize(master.size.width * 9.0f/10.0f, master.size.height * 0.3f)];
	NSSize currentFileSize = [currentFile renderedSize];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.05f;
	frame.origin.y = (master.size.height * 0.07f - currentFileSize.height) ;
	frame.size = currentFileSize;
	[currentFile setFrame:frame];
}

- (void) dealloc
{
	[title release];
	[text release];
	[fileProgress release] ;
	[bar release];
	[button release];
	[meta release];
	[importTimer invalidate];
	[super dealloc];
}

- (void)import
{
	[button setTitle:@"Cancel Import"];
	[button setAction:@selector(cancel)];
	[self setFileProgress:@"Initializing..."];
	[[self scene] renderScene];
	importItems = [[meta subFileMetas] mutableCopy];
	updated = 0 ;
	current = 0;
	max = [importItems count];
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

- (void)importNextItem:(NSTimer *)timer
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	NSString * fileName=[[fileMeta path] lastPathComponent] ;
	current++ ;
	[self setCurrentFile:[NSString stringWithFormat:@"Current File: %@",fileName]];
	[self setFileProgress:[NSString stringWithFormat:@"File Progress: %0.0f / %0.0f", current, max,updated]];
	if([fileMeta updateMetaData])updated++;
	
	[importItems removeObjectAtIndex:0];
	[bar setPercentage:current/max * 100.0f];
	
	if(![importItems count])
	{
		[importTimer invalidate];
		importTimer = nil;
		[meta writeMetaData];
		[button setHidden:YES];
		[button setTarget:nil];
		[title setTitle: @"Import Complete"];
		[self setFileProgress:[NSString stringWithFormat:@"Updated %0.0f Entries.", updated]];
		[self setCurrentFile:@""];
		[self setText:@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported"];
		[[self scene] renderScene];
	}
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
	[title setTitle: @"Populate Show Data"];
	[self setText:@"This will populate Sapphire's Meta data.  This proceedure may take a while, but you may cancel at any time"];
	[self setFileProgress:@" "];
	[self setCurrentFile:@" "] ;
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
