//
//  SapphireBrowser.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMetaData.h"
#import "SapphireMediaMenuController.h"
@class SapphireSettings, BRSegmentedSortControl, SapphirePredicate;

/*!
 * @brief A subclass of SapphireMediaMenuController for browsing metadata
 *
 * This class is designed to browse through the metadata.  It is important to note that nothing in this class is tied to physical directory structure except for the files themselves.  This allows this class to browse virtual directory structures through the metadata it is provided.
 */
@interface SapphireBrowser : SapphireMediaMenuController <SapphireMetaDataDelegate, SapphireMetaDataScannerDelegate>
{
	NSMutableArray					*_names;			/*!< @brief Names in the menu display*/
	NSMutableArray					*items;				/*!< @brief Chached BRAdornedMenuItemLayer for menu items*/
	SapphireDirectoryMetaData		*metaData;			/*!< @brief The directory for the browser*/
	SapphirePredicate				*predicate;			/*!< @brief Predicate to determine which files are matched*/
	SapphireFileMetaData			*currentPlayFile;	/*!< @brief If we are the browser to actually play something, the file we are playing*/
	int								dirCount;			/*!< @brief The number of directories in this directory*/
	int								fileCount;			/*!< @brief The number of files in this directory*/
	BOOL							cancelScan;			/*!< @brief Cancel the background importer for this directory*/
	BOOL							soundsWereEnabled;	/*!< @brief Were sounds enabled before we played the current file*/
}

/*!
 * @brief Creates a new predicated browser
 *
 * This creates a new browser with a metadata directory.  The resulting class can then be pushed onto the screen.
 *
 * @param scene The scene
 * @praam meta The metadata for the directory to browse
 * @param newPredicate The predicate to use
 * @return The Browser
 */
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta;

/*!
 * @brief The current directory metadata
 *
 * This function gets the metadata directory that this browser is currently in
 *
 * @return The directory metadata
 */
- (SapphireDirectoryMetaData *)metaData;
@end
