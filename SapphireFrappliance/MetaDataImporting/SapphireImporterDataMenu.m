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
#import "SapphireDirectoryMetaData.h"
#import "SapphireFileMetaData.h"
#import "SapphireCollectionDirectory.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireImportHelper.h"
#import "SapphireApplianceController.h"
#import "NSString-Extensions.h"
#import "SapphireMetaDataSupport.h"
#import "NSManagedObject-Extensions.h"
#import "SapphireFileSymLink.h"
#import "SapphireChooser.h"

#define updateFreq 0.05

@interface SapphireImportChooserQueueItem : NSObject
{
	BRLayerController <SapphireChooser>	*chooser;
	id <SapphireImporter>				importer;
	id									context;
}
- (id)initWithChooser:(BRLayerController <SapphireChooser> *)chooser forImporter:(id <SapphireImporter>)importer withContext:(id)context;
- (BRLayerController <SapphireChooser> *)chooser;
- (id <SapphireImporter>)importer;
- (id)context;
@end

@implementation SapphireImportChooserQueueItem

- (id)initWithChooser:(BRLayerController <SapphireChooser>*)aChooser forImporter:(id <SapphireImporter>)aImporter withContext:(id)aContext
{
	self = [super init];
	if(!self)
		return self;
	
	chooser = [aChooser retain];
	importer = [aImporter retain];
	context = [aContext retain];
	
	return self;
}

- (void) dealloc
{
	[chooser release];
	[importer release];
	[context release];
	[super dealloc];
}

- (BRLayerController <SapphireChooser> *)chooser
{
	return chooser;
}

- (id <SapphireImporter>)importer
{
	return importer;
}

- (id)context
{
	return context;
}

@end

@implementation SapphireImportStateData

- (id)initWithFile:(SapphireFileMetaData *)aFile atPath:(NSString *)aPath
{
	self = [super init];
	if(!self)
		return self;
	
	file = [aFile retain];
	path = [aPath retain];
	
	return self;
}

- (void) dealloc
{
	[file release];
	[path release];
	[lookupName release];
	[super dealloc];
}

- (void)setLookupName:(NSString *)aName
{
	[lookupName autorelease];
	lookupName = [aName retain];
}

@end


@interface BRLayerController (compatounth)
- (NSRect)controllerFrame;  /*technically wrong; it is really a CGRect*/
@end

@interface SapphireImporterDataMenu ()
- (void)layoutFrame;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)itemImportBackgrounded;
- (void)updateDisplay;
@end

@implementation SapphireImporterDataMenu
- (id) initWithScene: (BRRenderScene *) scene context:(NSManagedObjectContext *)context  importer:(id <SapphireImporter>)import;
{
	self = [super initWithScene:scene];
	if(self == nil)
		return self;
	
	moc = [context retain];
	importer = [import retain];
	[importer setDelegate:self];
	importItems = [[NSMutableArray alloc] init];
	allItems = nil;
	skipSet = nil;
	choosers = [[NSMutableArray alloc] init];
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
	
	[SapphireLayoutManager setCustomLayoutOnControl:self];
	
    return self;
}

- (void) dealloc
{
	[text release];
	[fileProgress release];
	[currentFile release];
	[bar release];
	[moc release];
	[collectionDirectories release];
	[skipSet release];
	[importItems release];
	[importTimer invalidate];
	[importer setDelegate:nil];
	[importer release];
	[buttonTitle release];
	[allItems release];
	[updateTimer invalidate];
	[currentFilename release];
	[choosers release];
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
	[SapphireFrontRowCompat setText:theText withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:text];
	
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
	[SapphireFrontRowCompat setText:theFileProgress withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:fileProgress];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize progressSize = [SapphireFrontRowCompat textControl:fileProgress renderedSizeWithMaxSize:NSMakeSize(master.size.width * 1.0f/2.0f, master.size.height * 0.3f)];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.12f) + master.origin.y;
	frame.size = progressSize;
	[fileProgress setFrame:frame];
}

- (void)realSetCurrentFile:(NSString *)theCurrentFile
{
	[SapphireFrontRowCompat setText:theCurrentFile withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:currentFile];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize currentFileSize = [SapphireFrontRowCompat textControl:currentFile renderedSizeWithMaxSize:NSMakeSize(master.size.width * 9.0f/10.0f, master.size.height * 0.3f)];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.09f) + master.origin.y;
	frame.size = currentFileSize;
	[currentFile setFrame:frame];
}

- (void)updateDisplayOfCurrentFile
{
	updateTimer = nil;
	[self realSetCurrentFile:currentFilename];
}

/*!
 * @brief Sets the display of the current file being processed
 *
 * @param theCurrentFile The current file being proccessed
 */
- (void)setCurrentFile:(NSString *)theCurrentFile
{
	[currentFilename release];
	currentFilename = [theCurrentFile retain];
	if(updateTimer == nil)
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateFreq target:self selector:@selector(updateDisplayOfCurrentFile) userInfo:nil repeats:NO];
}

/*!
 * @brief Get the list of all files to process
 */
- (void)getItems
{
	SapphireCollectionDirectory *collection = [collectionDirectories objectAtIndex:collectionIndex];
	if([collection isDeleted] || [collection skipValue])
	{
		collectionIndex++;
		[self performSelector:@selector(gotSubFiles:) withObject:[NSArray array] afterDelay:0.0];
		return;
	}
	SapphireDirectoryMetaData *meta = [collection directory];
	//Prefetch
/*	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"path BEGINSWITH %@", [[meta path] stringByAppendingString:@"/"]];
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"path" ascending:YES];
	doSortedFetchRequest(SapphireDirectoryMetaDataName, moc, fetchPredicate, sort);
	doSortedFetchRequest(SapphireFileMetaDataName, moc, fetchPredicate, sort);
	doSortedFetchRequest(SapphireDirectorySymLinkName, moc, fetchPredicate, sort);
	doSortedFetchRequest(SapphireFileSymLinkName, moc, fetchPredicate, sort);
	[sort release];*/

	[meta getSubFileMetasWithDelegate:self skipDirectories:skipSet];
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
	@try {
		/*Change display*/
		[self setButtonTitle:BRLocalizedString(@"Cancel Import", @"Cancel the import process")];
		action = @selector(cancel);
		[self setFileProgress:BRLocalizedString(@"Initializing...", @"The import is starting")];
		[SapphireFrontRowCompat renderScene:[self scene]];
		/*Initialize the import process*/
		SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
		[loader addDelegate:self];
		pendingURLCount = [loader loadingURLCount];
		canceled = NO;
		collectionIndex = 0;
		[collectionDirectories release];
		collectionDirectories = [[SapphireCollectionDirectory availableCollectionDirectoriesInContext:moc includeHiddenOverSkipped:YES] retain];
		NSArray *skipCol = [SapphireCollectionDirectory skippedCollectionDirectoriesInContext:moc];
		[skipSet release];
		skipSet = [[NSMutableSet alloc] initWithSet:[skipCol valueForKeyPath:@"directory.path"]];
		if([collectionDirectories count])
			[self getItems];
		else
			[self gotSubFiles:[NSArray array]];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
		[e raise];
	}
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
	[SapphireMetaDataSupport save:moc];
	[allItems release];
	allItems = [importItems copy];
	updated = 0 ;
	current = 0;
	max = [importItems count];
	if(!canceled)
	{
		/*Update the display*/
		[self updateDisplay];
		importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:NO];		
	}
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
	id meta = [importItems objectAtIndex:0];
	SapphireFileMetaData *file;
	if([meta isKindOfClass:[SapphireFileSymLink class]])
		file = [(SapphireFileSymLink *)meta file];
	else
		file = (SapphireFileMetaData *)meta;
	if(file.joinedToFile != nil)
		return NO;
	@try {
		ImportState result = [importer importMetaData:file path:[meta path]];
		switch(result)
		{
			case ImportStateUpdated:
				ret = YES;
				SapphireLog(SAPPHIRE_LOG_IMPORT, SAPPHIRE_LOG_LEVEL_DETAIL, @"Updated %@", [file path]);
				break;
			case ImportStateMultipleSuspend:
			case ImportStateBackground:
				[self itemImportBackgrounded];
				ret = NO;
				break;
			case ImportStateNotUpdated:
			case ImportStateUserSkipped:
				break;
		}
		if(ret)
			[SapphireMetaDataSupport save:moc];
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

- (void)realUpdateDisplay
{
	updateTimer = nil;
	/*Check for completion*/
	if(current == max)
	{
		[self setListTitle:BRLocalizedString(@"Import Complete", @"The import is complete")];
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Updated %0.0f Entries.", @"Import complete format with number updated"), updated]];
		[self realSetCurrentFile:@""];
		[self setCompletionText];
		[bar setPercentage:100.0f];
		[self setButtonTitle:nil];
		action = NULL;

		[SapphireMetaDataSupport save:moc];
		
		NSManagedObject *obj;
		NSEnumerator *objEnum = [allItems objectEnumerator];
		while((obj = [objEnum nextObject]) != nil)
			[obj faultOjbectInContext:moc];
		[allItems release];
		allItems = nil;
	}
	else
	{
		if([importItems count])
		{
			SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
			NSString * fileName=[[fileMeta path] lastPathComponent] ;
			[self realSetCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Fetching For: %@", "Current TV Show import process format, filename"),fileName]];		
		}
		else
		{
			[self realSetCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Waiting for background import to complete: %d URLs remaining to load", @"The import is complete, just waiting on background processes, parameter is number of URLs remaining to load"), pendingURLCount]];
		}
		[self setFileProgress:[NSString stringWithFormat:BRLocalizedString(@"Finished Processing: %0.0f / %0.0f", @"Import progress format, current and the max"), current, max,updated]];
		[bar setPercentage:current/max * 100.0f];
	}
	[SapphireFrontRowCompat renderScene:[self scene]];		
}

- (void)updateDisplay
{
	if(updateTimer == nil)
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateFreq target:self selector:@selector(realUpdateDisplay) userInfo:nil repeats:NO];
}

/*!
 * @brief Timer function to start the import of the next file
 *
 * @param timer The timer that triggered this
 */
- (void)importNextItem:(NSTimer *)timer
{
	@try
	{
		importTimer = nil;

		if([importItems count])
		{
			current++ ;
			/*Update the imported count*/
			if([self doImport] && !backgrounded)
				updated++;		
			
			/*Check for a background import*/
			if(backgrounded)
			{
				backgrounded = NO;
				current--;
			}
			
			/*Start with the first item*/
			[importItems removeObjectAtIndex:0];
			importTimer = [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(importNextItem:) userInfo:nil repeats:NO];
		}
		/*Update the display*/
		[self updateDisplay];
	}
	@catch(NSException *e)
	{
		[SapphireApplianceController logException:e];
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
	[importer cancelImports];
	[choosers removeAllObjects];
	/*Reset the display and write data*/
	[[SapphireApplianceController urlLoader] removeDelegate:self];
	[self resetUIElements];
	[SapphireMetaDataSupport save:moc];
}

- (void)itemImportBackgrounded
{
	backgrounded = YES;
}

- (void)skipNextItem
{
	/*Remove the next item from the queue*/
	if([importItems count])
		[importItems removeObjectAtIndex:0];
	current++;
}

- (void)backgroundImporter:(id <SapphireImporter>)aImporter completedImportOnPath:(NSString *)path withState:(ImportState)state
{
	if(state == ImportStateUpdated)
		updated++;

	current++;
	[self updateDisplay];
}

- (void)urlLoaderFinisedResource:(SapphireURLLoader *)loader
{
	pendingURLCount = [loader loadingURLCount];
	[self updateDisplay];
}

- (void)urlLoaderCancelledResource:(SapphireURLLoader *)loader
{
	pendingURLCount = [loader loadingURLCount];
	[self updateDisplay];
}

- (void)urlLoaderAddedResource:(SapphireURLLoader *)loader
{
	pendingURLCount = [loader loadingURLCount];
	[self updateDisplay];
}

- (BOOL)canDisplayChooser
{
	return YES;
}

- (id)chooserScene
{
	return [self scene];
}

static SapphireImportChooserQueueItem *findNextChooser(NSMutableArray *choosers)
{
	SapphireImportChooserQueueItem *candidate = [choosers objectAtIndex:0];
	while(![[candidate importer] stillNeedsDisplayOfChooser:[candidate chooser] withContext:[candidate context]])
	{
		[choosers removeObjectAtIndex:0];
		if(![choosers count])
			return nil;
		candidate = [choosers objectAtIndex:0];
	}
	return candidate;
}

- (void)displayNextChooser
{
	if(![choosers count])
		return;
	
	SapphireImportChooserQueueItem *queueItem = findNextChooser(choosers);
	if(queueItem)
		[[self stack] pushController:[queueItem chooser]];
}

- (void)displayChooser:(BRLayerController <SapphireChooser> *)chooser forImporter:(id <SapphireImporter>)aImporter withContext:(id)context
{
	SapphireImportChooserQueueItem *queueItem = [[SapphireImportChooserQueueItem alloc] initWithChooser:chooser forImporter:aImporter withContext:context];
	[choosers addObject:queueItem];
	[queueItem release];
	if([choosers count] == 1)
		[[self stack] pushController:chooser];
}

/*!
 * @brief Reset the UI after an import completion or cancel
 */
- (void)resetUIElements
{
	[self setFileProgress:@" "];
	[self realSetCurrentFile:@" "] ;
	[bar setPercentage:0.0f];
	action = @selector(import);
	[self setListTitle:[importer initialText]];
	[self setText:[importer informativeText]];
	[self setButtonTitle:[importer buttonTitle]];
}

- (void)doMyLayout
{
	if(!layoutDone)
	{
		[self layoutFrame];
		[self resetUIElements];
		layoutDone = YES;
	}
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

- (void)wasExhumed
{
	SapphireImportChooserQueueItem *queueItem = [choosers objectAtIndex:0];
	BRLayerController <SapphireChooser> *chooser = [queueItem chooser];
	[[queueItem importer] exhumedChooser:chooser withContext:[queueItem context]];
	[choosers removeObjectAtIndex:0];
	if([choosers count])
	{
		if([chooser selection] == SapphireChooserChoiceCancel)
			[self performSelector:@selector(displayNextChooser) withObject:nil afterDelay:0.5];
		else
			[self displayNextChooser];
	}
	[super wasExhumed];
}

- (BOOL)brEventAction:(BREvent *)event{
	BREventRemoteAction remoteAction = [SapphireFrontRowCompat remoteActionForEvent:event];
	
	if([(BRControllerStack *)[self stack] peekController] != self || action == NULL)
		remoteAction = 0;
	
	switch(remoteAction)
	{
		case kBREventRemoteActionPlay:
		case kBREventRemoteActionPlayHold:
			[self performSelector:action];
			return YES;
			break;
		case kBREventRemoteActionMenu:
			[self cancel];
			break;
		default:
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
