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
/*!
 * @brief Creates a new Importer Data Menu
 *
 * @param scene The scene
 * @praam meta The metadata for the directory to browse
 * @return The Menu
 */
- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData
{
	if ( [super initWithScene: scene] == nil )
	return ( nil );
	meta = [metaData retain];
	/*Setup the Header Control with default contents*/
	title = [[BRHeaderControl alloc] initWithScene: scene];
	[title setTitle:BRLocalizedString(@"Populate Show Data", @"Do a file metadata import")];
	/*Set the size*/
	NSRect frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[title setFrame: frame];
	
	/*Setup the Header Control with default contents*/
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];

	/*Setup the button control*/
	frame = [[self masterLayer] frame];
	button = [[BRButtonControl alloc] initWithScene: scene masterLayerSize: frame.size];
	[button setYPosition: frame.origin.y + (frame.size.height * (1.0f / 8.0f))];

	/*Setup the text entry control*/
	text = [[BRTextControl alloc] initWithScene: scene];
	fileProgress = [[BRTextControl alloc] initWithScene: scene];
	currentFile = [[BRTextControl alloc] initWithScene: scene];
	
	/*Setup the progress bar*/
	bar = [[BRProgressBarWidget alloc] initWithScene: scene];
	frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 5.0f / 16.0f;
	frame.origin.x = frame.size.width / 6.0f;
	frame.size.height = frame.size.height / 16.0f;
	frame.size.width = frame.size.width * 2.0f / 3.0f;
	[bar setFrame: frame] ;
	
	/*Setup the names*/
	[self resetUIElements];
	
	/*add controls*/
	[self addControl: title];
	[self addControl: text];
	[self addControl: fileProgress] ;
	[self addControl: currentFile] ;
	[[self masterLayer] addSublayer:bar];
	[self addControl: button];

    return ( self );
}

/*!
 * @brief Sets the informative text
 *
 * @param theText The text to set
 */
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

/*!
 * @brief Sets the file progress string
 *
 * @param theFileProgress The file progress string to display
 */
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

/*!
 * @brief Sets the display of the current file being processed
 *
 * @param theCurrentFile The current file being proccessed
 */
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

/*!
 * @brief Get the list of all files to process
 */
- (void)getItems
{
	[meta getSubFileMetasWithDelegate:self skipDirectories:[NSMutableSet set]];
}

/*!
 * @brief Start the import process
 */
- (void)import
{
	/*Change display*/
	[button setTitle:BRLocalizedString(@"Cancel Import", @"Cancel the import process")];
	[button setAction:@selector(cancel)];
	[self setFileProgress:BRLocalizedString(@"Initializing...", @"The import is starting")];
	[[self scene] renderScene];
	/*Initialize the import process*/
	[self getItems];
}

/*!
 * @brief Meta data delegate method to return final list of files
 *
 * @param subs The files which are children of the current directory
 */
- (void)gotSubFiles:(NSArray *)subs
{
	importItems = [subs mutableCopy];
	updated = 0 ;
	current = 0;
	max = [importItems count];
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

/*!
 * @brief Ask if we should cancel the fetching of file listing
 *
 * @return YES if the file listing should be canceled, NO otherwise
 */
- (BOOL)getSubFilesCanceled
{
	return canceled;
}

/*!
 * @brief Import a single item
 *
 * @return YES if any data was imported, NO otherwise
 */
- (BOOL)doImport
{
	return NO;
}

/*!
 * @brief Change the display to show the completion text
 */
- (void)setCompletionText
{
}

/*!
 * @brief Timer function to start the import of the next file
 *
 * @param timer The timer that triggered this
 */
- (void)importNextItem:(NSTimer *)timer
{
	/*Update the display*/
	current++ ;
	[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"File Progress: %0.0f / %0.0f", @"Import progress format, current and the max"), current, max,updated]];
	/*Update the imported count*/
	if([self doImport])
		updated++;
	
	/*Check for a suspend and reimport afterwards*/
	if(suspended)
	{
		current--;
		return;
	}
	
	/*Start with the first item*/
	[importItems removeObjectAtIndex:0];
	[bar setPercentage:current/max * 100.0f];
	
	/*Check for completion*/
	if(![importItems count])
	{
		[importTimer invalidate];
		importTimer = nil;
		[meta writeMetaData];
		/*Update display*/
		[button setHidden:YES];
		[button setTarget:nil];
		[title setTitle:BRLocalizedString(@"Import Complete", @"The import is complete")];
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Updated %0.0f Entries.", @"Import complete format with number updated"), updated]];
		[self setCurrentFile:@""];
		[self setCompletionText];
		[[self scene] renderScene];
	}
}

/*!
 * @brief Cancel the import process
 */
- (void)cancel
{
	/*Kill the timer*/
	canceled = YES;
	[importTimer invalidate];
	importTimer = nil;
	/*Reset the display and write data*/
	[self resetUIElements];
	[meta writeMetaData];
}

/*!
 * @brief Pause the import process
 */
- (void)pause
{
	/*Kil lthe timer*/
	suspended = YES;
	[importTimer invalidate];
	importTimer = nil;
}

/*!
 * @brief Resume the import process
 */
- (void)resume
{
	/*Sanity checks*/
	[importTimer invalidate];
	/*Resume*/
	suspended = NO;
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

/*!
 * @brief Skip the next item in the queue
 */
- (void)skipNextItem
{
	/*Remove the next item from the queue*/
	if([importItems count])
		[importItems removeObjectAtIndex:0];
}

/*!
 * @brief Reset the UI after an import completion or cancel
 */
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
	/*Someone hit menu, so cancel*/
	[self cancel];
	[super wasPopped];
}

@end
