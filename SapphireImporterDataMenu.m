/*
 * SapphireImporterDataMenu.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 24, 2007.
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

#import "SapphireImporterDataMenu.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireImportHelper.h"
#import "SapphireApplianceController.h"

@interface SapphireImporterDataMenu (private)
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
@end

@implementation SapphireImporterDataMenu
- (id) initWithScene: (BRRenderScene *) scene metaDataCollection:(SapphireMetaDataCollection *)collection  importer:(id <SapphireImporter>)import
{
	if ( [super initWithScene: scene] == nil )
		return ( nil );
	metaCollection = [collection retain];
	collectionDirectories = [[collection collectionDirectories] retain];
	importer = [import retain];
	[importer setImporterDataMenu:self];
	importItems = [[NSMutableArray alloc] init];
	/*Setup the Header Control with default contents*/
	title = [SapphireFrontRowCompat newHeaderControlWithScene:scene];
	[title setTitle:BRLocalizedString(@"Populate Show Data", @"Do a file metadata import")];
	/*Set the size*/
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y += frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[title setFrame: frame];
	
	/*Setup the button control*/
	frame = [SapphireFrontRowCompat frameOfController:self];
	button = [SapphireFrontRowCompat newButtonControlWithScene:scene masterLayerSize:frame.size];
	[button setYPosition: frame.origin.y + (frame.size.height * (1.0f / 8.0f))];

	/*Setup the text entry control*/
	text = [SapphireFrontRowCompat newTextControlWithScene:scene];
	fileProgress = [SapphireFrontRowCompat newTextControlWithScene:scene];
	currentFile = [SapphireFrontRowCompat newTextControlWithScene:scene];
	
	/*Setup the progress bar*/
	bar = [SapphireFrontRowCompat newProgressBarWidgetWithScene:scene];
	frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y += frame.size.height * 5.0f / 16.0f;
	frame.origin.x = frame.size.width / 6.0f;
	frame.size.height = frame.size.height / 16.0f;
	frame.size.width = frame.size.width * 2.0f / 3.0f;
	[bar setFrame: frame] ;
	
	/*Setup the names*/
	[self resetUIElements];
	
	/*add controls*/
	[self addControl: button];
	[self addControl: title];
	[self addControl: text];
	[self addControl: fileProgress] ;
	[self addControl: currentFile] ;
	[SapphireFrontRowCompat addSublayer:bar toControl:self];

    return ( self );
}

- (void) dealloc
{
	[title release];
	[button release];
	[text release];
	[fileProgress release];
	[currentFile release];
	[bar release];
	[metaCollection release];
	[collectionDirectories release];
	[importItems release];
	[importTimer invalidate];
	[importer setImporterDataMenu:nil];
	[importer release];
	[super dealloc];
}

/*!
 * @brief Sets the informative text
 *
 * @param theText The text to set
 */
- (void)setText:(NSString *)theText
{
	[SapphireFrontRowCompat setText:theText withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:text];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[text setMaximumSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	NSSize txtSize = [text renderedSize];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 0.4f - txtSize.height) + master.size.height * 0.3f/0.8f + master.origin.y;
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
	[SapphireFrontRowCompat setText:theFileProgress withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:fileProgress];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[fileProgress setMaximumSize:NSMakeSize(master.size.width * 1.0f/2.0f, master.size.height * 0.3f)];
	NSSize progressSize = [fileProgress renderedSize];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.12f) + master.origin.y;
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
	[SapphireFrontRowCompat setText:theCurrentFile withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:currentFile];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	[currentFile setMaximumSize:NSMakeSize(master.size.width * 9.0f/10.0f, master.size.height * 0.3f)];
	NSSize currentFileSize = [currentFile renderedSize];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.09f) + master.origin.y;
	frame.size = currentFileSize;
	[currentFile setFrame:frame];
}

/*!
 * @brief Get the list of all files to process
 */
- (void)getItems
{
	NSString *path = [collectionDirectories objectAtIndex:collectionIndex];
	if([metaCollection skipCollection:path])
	{
		collectionIndex++;
		[self performSelector:@selector(gotSubFiles:) withObject:[NSArray array] afterDelay:0.0];
		return;
	}
	SapphireDirectoryMetaData *meta = [metaCollection directoryForPath:path];
	[meta getSubFileMetasWithDelegate:self skipDirectories:[NSMutableSet set]];
	collectionIndex++;
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
	[SapphireFrontRowCompat renderScene:[self scene]];
	/*Initialize the import process*/
	canceled = NO;
	suspended = NO;
	collectionIndex = 0;
	[self getItems];
}

/*!
 * @brief Metadata delegate method to return final list of files
 *
 * @param subs The files which are children of the current directory
 */
- (void)gotSubFiles:(NSArray *)subs
{
	[importItems addObjectsFromArray:subs];
	if(collectionIndex != [collectionDirectories count])
	{
		[self getItems];
		return;
	}
	updated = 0 ;
	current = 0;
	max = [importItems count];
	if(!canceled)
		importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

/*!
 * @brief Metadata delegate method to inform on its scanning progress
 *
 * @param dir The current directory it is scanning
 */
- (void)scanningDir:(NSString *)dir
{
	[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Scanning Directory: %@", "Current scan import process format, directory"),dir]];
	[SapphireFrontRowCompat renderScene:[self scene]];
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
	BOOL ret = NO;
	@try {
		ret = [importer importMetaData:[importItems objectAtIndex:0]];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
		[e raise];
	}
	@finally {
		return ret;
	}
}

/*!
 * @brief Change the display to show the completion text
 */
- (void)setCompletionText
{
	[self setText:[importer completionText]];
}

/*!
 * @brief Timer function to start the import of the next file
 *
 * @param timer The timer that triggered this
 */
- (void)importNextItem:(NSTimer *)timer
{
	if([importItems count])
	{
		/*Update the display*/
		SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
		NSString * fileName=[[fileMeta path] lastPathComponent] ;
		[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Current File: %@", "Current TV Show import process format, filename"),fileName]];
		
		current++ ;
		/*Update the imported count*/
		if([self doImport] && !backgrounded)
			updated++;		
		
		/*Check for a suspend and reimport afterwards*/
		if(suspended || backgrounded)
		{
			backgrounded = NO;
			current--;
			return;
		}
		
		/*Start with the first item*/
		[importItems removeObjectAtIndex:0];
	}
	[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"File Progress: %0.0f / %0.0f", @"Import progress format, current and the max"), current, max,updated]];
	[bar setPercentage:current/max * 100.0f];
	
	/*Check for completion*/
	if(current == max)
	{
		[importTimer invalidate];
		importTimer = nil;
		[metaCollection writeMetaData];
		/*Update display*/
		[button setHidden:YES];
		[button setTarget:nil];
		[title setTitle:BRLocalizedString(@"Import Complete", @"The import is complete")];
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Updated %0.0f Entries.", @"Import complete format with number updated"), updated]];
		[self setCurrentFile:@""];
		[self setCompletionText];
		[SapphireFrontRowCompat renderScene:[self scene]];
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
	[importItems removeAllObjects];
	[[SapphireImportHelper sharedHelper] removeObjectsWithInform:self];
	/*Reset the display and write data*/
	[self resetUIElements];
	[metaCollection writeMetaData];
}

- (void)pause
{
	/*Kil lthe timer*/
	suspended = YES;
	[importTimer invalidate];
	importTimer = nil;
}

- (void)resume
{
	/*Sanity checks*/
	[importTimer invalidate];
	/*Resume*/
	suspended = NO;
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:YES];
}

- (oneway void)informComplete:(BOOL)fileUpdated
{
	if(fileUpdated)
		updated++;
	current++;
	[self importNextItem:nil];
}

- (void)itemImportBackgrounded
{
	if([importItems count])
		[importItems removeObjectAtIndex:0];
	backgrounded = YES;
}

- (void)skipNextItem
{
	/*Remove the next item from the queue*/
	if([importItems count])
		[importItems removeObjectAtIndex:0];
	current++;
}

/*!
 * @brief Reset the UI after an import completion or cancel
 */
- (void)resetUIElements
{
	[self setFileProgress:@" "];
	[self setCurrentFile:@" "] ;
	[bar setPercentage:0.0f];
	[button setAction: @selector(import)];
	[button setHidden:NO];
	[title setTitle:[importer initialText]];
	[self setText:[importer informativeText]];
	[button setTitle:[importer buttonTitle]];
}

- (void)willBePushed
{
	[button setTarget:self];
}

- (void)wasPopped
{
	/*Someone hit menu, so cancel*/
	[self cancel];
	[super wasPopped];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	[importer wasExhumedByPoppingController:controller];
	[super wasExhumedByPoppingController:controller];
}

@end
