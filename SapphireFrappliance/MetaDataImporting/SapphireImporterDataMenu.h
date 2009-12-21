/*
 * SapphireImporterDataMenu.h
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

#import "SapphireDirectory.h"
#import <SapphireCompatClasses/SapphireCenteredMenuController.h>
#import <SapphireCompatClasses/SapphireLayoutManager.h>

@class SapphireImporterDataMenu, SapphireFileMetaData;
@protocol SapphireImporterDelegate, SapphireChooser;

/*!
 * @brief Status of an import
 */
typedef enum{
	ImportStateNotUpdated,		/*!< @brief The data was not updated*/
	ImportStateUpdated,			/*!< @brief The data was updated*/
	ImportStateSuspend,			/*!< @brief The data update has been suspended pending UI*/
	ImportStateBackground,		/*!< @brief The data was backgrounded*/
	ImportStateUserSkipped,		/*!< @brief The user asked to skip import*/
} ImportState;

/*!
 * @brief The importer protocol
 *
 * This protocol is the basic functionality that all importers must implement.  Through this, a common UI can implement all the importers.
 */
@protocol SapphireImporter <NSObject>

/*!
 * @brief Import a single File
 *
 * @param metaData The file to import
 * @param path The file path (not the same as metadata's path in the case of a symlink)
 * @return The state of the import
 */
- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path;

/*!
 * @brief Sets the importer's delegate
 *
 * This is the delegate for the importer, mostly telling it when import is complete
 *
 * @param delegate The delegate for the importer
 */
- (void)setDelegate:(id <SapphireImporterDelegate>)delegate;

/*!
 * @brief Cancel all pending imports
 */
- (void)cancelImports;

/*!
 * @brief The completion text to display
 *
 * @return The completion text to display
 */
- (NSString *)completionText;

/*!
 * @brief The initial text to display
 *
 * This is the initial text to display in the title.
 *
 * @return The initial text to display
 */
- (NSString *)initialText;

/*!
 * @brief The informative text to display
 *
 * This is the text to display under the title, describing what this importer will do.
 *
 * @return The informative text to display
 */
- (NSString *)informativeText;

/*!
 * @brief The button title
 *
 * This text is displayed in the button before the user starts.  The button is hidden after completion, so there are no other functions for this text.
 *
 * @return The button title
 */
- (NSString *)buttonTitle;

/*!
 * @brief The data menu was exhumed
 *
 * Some importers present the user with other choices, so this lets the importer know that the "dialog" has completed.
 *
 * @param chooser The chooser which was exhumed
 * @param context The context for this choice
 */
- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context;
@end

@protocol SapphireImporterDelegate <NSObject>

/*!
 * @brief Tells the delegate the importer completed a background import
 *
 * @param importer The importer which completed import
 * @param path The path on which the importer completed
 * @param state The final state of the import
 */
- (void)backgroundImporter:(id <SapphireImporter>)importer completedImportOnPath:(NSString *)path withState:(ImportState)state;

/*!
 * @brief Resume the import process
 *
 * @param The path at which the importer ran
 */
- (void)resumeWithPath:(NSString *)path;

/*!
 * @brief States whether a chooser can be displayed
 *
 * @return YES if a chooser can be displayed, NO otherwise
 */
- (BOOL)canDisplayChooser;

/*!
 * @brief The scene to use for the chooser
 *
 * @return The scene to use for the chooser
 */
- (id)chooserScene;

/*!
 * @brief Displays a chooser and calls the importers callback when done
 *
 * @param chooser The chooser to display
 * @param importer The importer wanting to display a chooser
 * @param context The context item for the chooser
 */
- (void)displayChooser:(BRLayerController <SapphireChooser> *)chooser forImporter:(id <SapphireImporter>)importer withContext:(id)context;

@end

@interface SapphireImportStateData : NSObject
{
@public
	SapphireFileMetaData	*file;
	NSString				*path;
	NSString				*lookupName;
}

- (id)initWithFile:(SapphireFileMetaData *)file atPath:(NSString *)path;
- (void)setLookupName:(NSString *)lookupName;
@end



/*!
 * @brief The importer UI
 *
 * This class creates the importer UI.  It handles all the user interaction and passes commands on to its subordinates.
 */
@interface SapphireImporterDataMenu : SapphireCenteredMenuController <SapphireMetaDataScannerDelegate, SapphireLayoutDelegate, SapphireImporterDelegate>
{
	BRTextControl					*text;					/*!< @brief The informative text*/
	BRTextControl					*fileProgress;			/*!< @brief The progress text*/
	BRTextControl					*currentFile;			/*!< @brief The current file text*/
	BRProgressBarWidget				*bar;					/*!< @brief The progress bar*/

	NSManagedObjectContext			*moc;					/*!< @brief The main context*/
	NSMutableArray					*collectionDirectories;	/*!< @brief The directories to import*/
	int								collectionIndex;		/*!< @brief The current index in the directories*/
	NSMutableArray					*importItems;			/*!< @brief The items remaining to import*/
	NSArray							*allItems;				/*!< @brief The list of all items imported*/
	NSMutableSet					*skipSet;				/*!< @brief The directories to skip*/
	NSTimer							*importTimer;			/*!< @brief The timer to do the next import (so we don't freeze the UI)*/
	float							max;					/*!< @brief The max number to import*/
	float							current;				/*!< @brief The current count of imported items*/
	float							updated ;				/*!< @brief The number of items with new data*/
	BOOL							suspended;				/*!< @brief YES if import is suspended, NO otherwise*/
	BOOL							canceled;				/*!< @brief YES if the import was cancelled, NO otherwise*/
	BOOL							backgrounded;			/*!< @brief YES if the current file is backgrounded, NO otherwise*/
	
	id <SapphireImporter>			importer;				/*!< @brief The importer who does the dirty work*/
	SEL								action;					/*!< @brief The action selector when the button is hit*/
	NSString						*buttonTitle;			/*!< @brief The fake button title*/
	BOOL							layoutDone;				/*!< @brief YES if layout already done, NO otherwise*/
	NSTimer							*updateTimer;			/*!< @brief Timer to aggregate updates to reduce CPU usage*/
	NSString						*currentFilename;		/*!< @brief The current file to display*/
	NSMutableArray					*choosers;				/*!< @brief The array of choosers to display*/
}
/*!
 * @brief Creates a new Importer Data Menu
 *
 * @param scene The scene
 * @praam context The metadata context to browse
 * @return The Menu
 */
- (id) initWithScene: (BRRenderScene *) scene context:(NSManagedObjectContext *)context  importer:(id <SapphireImporter>)import;

@end