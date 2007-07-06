//
//  SapphireImporterDataMenu.m
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphirePopulateDataMenu.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"

@interface SapphireImporterDataMenu (private)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
@end

@implementation SapphireImporterDataMenu
- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData
{
	if ( [super initWithScene: scene] == nil )
	return ( nil );
	meta = [metaData retain];
	// Setup the Header Control with default contents
	title = [[BRHeaderControl alloc] initWithScene: scene];
	[title setTitle:BRLocalizedString(@"Populate Show Data", @"Do a file metadata import")];
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
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.12f) ;
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
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.09f) ;
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

- (void)getItems
{
	[meta getSubFileMetasWithDelegate:self];
}

- (void)import
{
	[button setTitle:BRLocalizedString(@"Cancel Import", @"Cancel the import process")];
	[button setAction:@selector(cancel)];
	[self setFileProgress:BRLocalizedString(@"Initializing...", @"The import is starting")];
	[[self scene] renderScene];
	[self getItems];
}

- (void)gotSubFiles:(NSArray *)subs
{
	importItems = [subs mutableCopy];
	updated = 0 ;
	current = 0;
	max = [importItems count];
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

- (BOOL)getSubFilesCanceled
{
	return canceled;
}

- (BOOL)doImport
{
	return NO;
}

- (void)setCompletionText
{
}

- (void)importNextItem:(NSTimer *)timer
{
	current++ ;
	[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"File Progress: %0.0f / %0.0f", @"Import progress format, current and the max"), current, max,updated]];
	if([self doImport])updated++;
	
	if(suspended)
	{
		current--;
		return;
	}
	
	[importItems removeObjectAtIndex:0];
	[bar setPercentage:current/max * 100.0f];
	
	if(![importItems count])
	{
		[importTimer invalidate];
		importTimer = nil;
		[meta writeMetaData];
		[button setHidden:YES];
		[button setTarget:nil];
		[title setTitle:BRLocalizedString(@"Import Complete", @"The import is complete")];
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Updated %0.0f Entries.", @"Import complete format with number updated"), updated]];
		[self setCurrentFile:@""];
		[self setCompletionText];
		[[self scene] renderScene];
	}
}

- (void)cancel
{
	canceled = YES;
	[importTimer invalidate];
	importTimer = nil;
	[self resetUIElements];
	[meta writeMetaData];
}

- (void)pause
{
	suspended = YES;
	[importTimer invalidate];
	importTimer = nil;
}

- (void)resume
{
	suspended = NO;
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

- (void)skipNextItem
{
	if([importItems count])
		[importItems removeObjectAtIndex:0];
}

- (void)resetUIElements
{
	[self setFileProgress:@" "];
	[self setCurrentFile:@" "] ;
	[bar setPercentage:0.0f];
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
