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
#import "NSString-Extensions.h"

@interface BRLayerController (compatounth)
- (NSRect)controllerFrame;  /*technically wrong; it is really a CGRect*/
@end

@interface SapphireImporterDataMenu (private)
- (void)layoutFrame;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)pause;
- (void)itemImportBackgrounded;
@end

@implementation SapphireImporterDataMenu
- (id) initWithScene: (BRRenderScene *) scene metaDataCollection:(SapphireMetaDataCollection *)collection  importer:(id <SapphireImporter>)import
{
	if ( [super initWithScene: scene] == nil )
		return ( nil );
	metaCollection = [collection retain];
	importer = [import retain];
	[importer setImporterDataMenu:self];
	importItems = [[NSMutableArray alloc] init];
	/*Setup the Header Control with default contents*/
	[self setListTitle:BRLocalizedString(@"Populate Show Data", @"Do a file metadata import")];

	/*Setup the text entry control*/
	text = [SapphireFrontRowCompat newTextControlWithScene:scene];
	fileProgress = [SapphireFrontRowCompat newTextControlWithScene:scene];
	currentFile = [SapphireFrontRowCompat newTextControlWithScene:scene];
	
	/*Setup the progress bar*/
	bar = [SapphireFrontRowCompat newProgressBarWidgetWithScene:scene];
	[self layoutFrame];
	
	[[self list] setDatasource:self];
	
	/*add controls*/
	[self addControl: text];
	[self addControl: fileProgress] ;
	[self addControl: currentFile] ;
	[SapphireFrontRowCompat addSublayer:bar toControl:self];

    return ( self );
}

- (void) dealloc
{
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
	[buttonTitle release];
	[super dealloc];
}

- (void)layoutFrame
{
	/*title*/
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y += frame.size.height * 5.0f / 16.0f;
	frame.origin.x = frame.size.width / 6.0f;
	frame.size.height = frame.size.height / 16.0f;
	frame.size.width = frame.size.width * 2.0f / 3.0f;
	[bar setFrame: frame] ;
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
	NSSize txtSize = [SapphireFrontRowCompat textControl:text renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 0.4f)];
	
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
	NSSize progressSize = [SapphireFrontRowCompat textControl:fileProgress renderedSizeWithMaxSize:NSMakeSize(master.size.width * 1.0f/2.0f, master.size.height * 0.3f)];
	
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
	NSSize currentFileSize = [SapphireFrontRowCompat textControl:currentFile renderedSizeWithMaxSize:NSMakeSize(master.size.width * 9.0f/10.0f, master.size.height * 0.3f)];
	
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
	[meta getSubFileMetasWithDelegate:self skipDirectories:[NSMutableSet setWithSet:[metaCollection skipDirectories]]];
	collectionIndex++;
}

- (void)setButtonTitle:(NSString *)title
{
	if(title != nil)
	{
		[buttonTitle release];
		buttonTitle = [title retain];
	}
	BRListControl *list = [self list];
	
	[list setHidden:(title == nil)];
	
	[list reload];
}

/*!
 * @brief Start the import process
 */
- (void)import
{
	/*Change display*/
	[self setButtonTitle:BRLocalizedString(@"Cancel Import", @"Cancel the import process")];
	action = @selector(cancel);
	[self setFileProgress:BRLocalizedString(@"Initializing...", @"The import is starting")];
	[SapphireFrontRowCompat renderScene:[self scene]];
	/*Initialize the import process*/
	canceled = NO;
	suspended = NO;
	collectionIndex = 0;
	[collectionDirectories release];
	collectionDirectories = [[metaCollection collectionDirectories] retain];
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
		importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:NO];
}

/*!
 * @brief Metadata delegate method to inform on its scanning progress
 *
 * @param dir The current directory it is scanning
 */
- (void)scanningDir:(NSString *)dir
{
	[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Scanning Directory: %@", "Current scan import process format, directory"),[NSString stringByCroppingDirectoryPath:dir toLength:3]]];
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
		ImportState result = [importer importMetaData:[importItems objectAtIndex:0]];
		switch(result)
		{
			case IMPORT_STATE_UPDATED:
				ret = YES;
				break;
			case IMPORT_STATE_NEEDS_SUSPEND:
				[self pause];
				ret = NO;
				break;
			case IMPORT_STATE_BACKGROUND:
				[self itemImportBackgrounded];
				ret = NO;
				break;
		}
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
	[importTimer invalidate];
	importTimer = nil;
	if([importItems count])
	{
		/*Update the display*/
		SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
		NSString * fileName=[[fileMeta path] lastPathComponent] ;
		[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Fetching For: %@", "Current TV Show import process format, filename"),fileName]];
		
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
	else
		[self setCurrentFile:BRLocalizedString(@"Waiting for background import to complete", @"The import is complete, just waiting on background processes")];
	[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Finished Processing: %0.0f / %0.0f", @"Import progress format, current and the max"), current, max,updated]];
	[bar setPercentage:current/max * 100.0f];
	
	/*Check for completion*/
	if(current == max)
	{
		[metaCollection writeMetaData];
		/*Update display*/
		[self setButtonTitle:nil];
		action = NULL;
		[self setListTitle:BRLocalizedString(@"Import Complete", @"The import is complete")];
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Updated %0.0f Entries.", @"Import complete format with number updated"), updated]];
		[self setCurrentFile:@""];
		[self setCompletionText];
		[SapphireFrontRowCompat renderScene:[self scene]];
	}
	else
	{
		importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:NO];
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
}

- (void)resume
{
	/*Sanity checks*/
	[importTimer invalidate];
	/*Resume*/
	suspended = NO;
	importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:NO];
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
	if([importItems count] && !suspended)
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
	action = @selector(import);
	[self setListTitle:[importer initialText]];
	[self setText:[importer informativeText]];
	[self setButtonTitle:[importer buttonTitle]];
}

- (void)wasPushed
{
	[self layoutFrame];
	[self resetUIElements];
	[super wasPushed];
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

- (BOOL)brEventAction:(BREvent *)event{
	BREventPageUsageHash hashVal = [event pageUsageHash];
	
	if([(BRControllerStack *)[self stack] peekController] != self || action == NULL)
		hashVal = 0;
	
	switch(hashVal)
	{
		case kBREventTapPlayPause:
		case kBREventHoldPlayPause:
			[self performSelector:action];
			return YES;
			break;
	}
	return [super brEventAction:event];
}

- (long) itemCount
{
	return 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	[SapphireFrontRowCompat setTitle:buttonTitle forMenu:result];
	
	return result;
}

- (NSString *) titleForRow: (long) row
{
	
	if ( row >= 1 ) return ( nil );
	
	NSString *result = buttonTitle ;
	
	return [NSString stringWithFormat:@"  ????? %@", result];
}

- (long) rowForTitle: (NSString *) aTitle
{
    long result = -1;
    long i, count = [self itemCount];
    for ( i = 0; i < count; i++ )
    {
        if ( [aTitle isEqualToString: [self titleForRow: i]] )
        {
            result = i;
            break;
        }
    }
    
    return ( result );
}

- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master
{
	listFrame.size.height = master.size.height * 3.0f / 16.0f;
	listFrame.origin.y = master.size.height / 8.0f;
	listFrame.size.width = master.size.width / 3.0f;
	listFrame.origin.x = master.size.width / 3.0f;
	return listFrame;
}

@end
