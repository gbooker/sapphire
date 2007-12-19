/*
 * SapphireBrowser.h
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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
