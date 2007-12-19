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

#import "SapphireMetaData.h"
#import "SapphireLayerController.h"

@protocol SapphireFileMetaDataProtocol;
@class SapphireImporterDataMenu;

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
 * @return YES if imported, NO otherwise
 */
- (BOOL)importMetaData:(id <SapphireFileMetaDataProtocol>)metaData;

/*!
 * @brief Sets the importer's data menu
 *
 * This is the text to display under the title, stating that the importer is done.
 *
 * @param theDataMenu The importer's menu
 */
- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu;

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
 * @param controller The Controller which was on top
 */
- (void) wasExhumedByPoppingController: (BRLayerController *) controller;
@end


/*!
 * @brief The importer UI
 *
 * This class creates the importer UI.  It handles all the user interaction and passes commands on to its subordinates.
 */
@interface SapphireImporterDataMenu : SapphireLayerController <SapphireMetaDataScannerDelegate, SapphireImporterBackgroundProtocol>
{
	BRHeaderControl					*title;					/*!< @brief The title*/
	BRButtonControl					*button;				/*!< @brief The button to press*/
	BRTextControl					*text;					/*!< @brief The informative text*/
	BRTextControl					*fileProgress;			/*!< @brief The progress text*/
	BRTextControl					*currentFile;			/*!< @brief The current file text*/
	BRProgressBarWidget				*bar;					/*!< @brief The progress bar*/

	SapphireMetaDataCollection		*metaCollection;		/*!< @brief The main collection*/
	NSMutableArray					*collectionDirectories;	/*!< @brief The directories to import*/
	int								collectionIndex;		/*!< @brief The current index in the directories*/
	NSMutableArray					*importItems;			/*!< @brief The items remaining to import*/
	NSTimer							*importTimer;			/*!< @brief The timer to do the next import (so we don't freeze the UI)*/
	float							max;					/*!< @brief The max number to import*/
	float							current;				/*!< @brief The current count of imported items*/
	float							updated ;				/*!< @brief The number of items with new data*/
	BOOL							suspended;				/*!< @brief YES if import is suspended, NO otherwise*/
	BOOL							canceled;				/*!< @brief YES if the import was cancelled, NO otherwise*/
	BOOL							backgrounded;			/*!< @brief YES if the current file is backgrounded, NO otherwise*/
	
	id <SapphireImporter>			importer;				/*!< @brief The importer who does the dirty work*/
}
/*!
 * @brief Creates a new Importer Data Menu
 *
 * @param scene The scene
 * @praam collection The metadata collection to browse
 * @return The Menu
 */
- (id) initWithScene: (BRRenderScene *) scene metaDataCollection:(SapphireMetaDataCollection *)collection  importer:(id <SapphireImporter>)import;
@end

/*!
 * @brief The importer UI protected API
 *
 * This category is for use by the SapphireImporter objects to control the overal import process.  It has the ability to pause, resume, and skip an item.
 */
@interface SapphireImporterDataMenu (protectedAccess)

/*!
 * @brief Pause the import process
 */
- (void)pause;

/*!
 * @brief Resume the import process
 */
- (void)resume;

/*!
 * @brief Say that the file's import is backgrounded
 */
- (void)itemImportBackgrounded;

/*!
 * @brief Skip the next item in the queue
 */
- (void)skipNextItem;
@end
