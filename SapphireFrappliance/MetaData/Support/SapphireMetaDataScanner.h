/*
 * SapphireMetaDataScanner.h
 * Sapphire
 *
 * Created by Graham Booker on Jul. 6, 2007.
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

@class SapphireDirectoryMetaData;

/*!
 * @brief The metadata scanning class
 *
 * This class is a helper class to allow the directory metadata to deep scan the contents of a directory.
 */
@interface SapphireMetaDataScanner : NSObject <SapphireMetaDataScannerDelegate> {
	SapphireDirectoryMetaData				*metaDir;			/*!< @brief The scanning directory*/
	NSMutableArray							*remaining;			/*!< @brief The reaming directories to scan*/
	NSMutableArray							*results;			/*!< @brief The current results of the scan*/
	NSMutableSet							*skipDirectories;	/*!< @brief The directories to skip*/
	id <SapphireMetaDataScannerDelegate>	delegate;			/*!< @brief The delegate to inform about the results*/
	NSTimer									*nextFileTimer;		/*!< @brief The timer to get the next file*/
	
	NSMutableArray							*dirs;				/*!< @brief The list of dirs in this directory*/
	NSMutableArray							*files;				/*!< @brief The list of files in this directory*/
	NSMutableArray							*symDirs;			/*!< @brief The list of symbolic linked dirs in this directory*/
	NSMutableArray							*symFiles;			/*!< @brief The list of symbolic linked files in this directory*/
	NSMutableArray							*dirsComp;			/*!< @brief The list of dirs in this directory in path components*/
	NSMutableArray							*filesComp;			/*!< @brief The list of files in this directory in path components*/
	NSMutableArray							*symDirsComp;		/*!< @brief The list of symbolic linked dirs in this directory in path components*/
	NSMutableArray							*symFilesComp;		/*!< @brief The list of symbolic linked files in this directory in path components*/
	
	NSMutableDictionary						*subScanners;		/*!< @brief The sub-scanners of this scanner*/
	int										depth;				/*!< @brief The directory depth of this scanner*/
}

/*!
 * @brief Create a new scanner on a directory
 *
 * @param meta The metadata's directory to scan
 * @param newDelegate The delegate to ask and tell about the scan
 * @return The scanner
 */
- (id)initWithDirectoryMetaData:(SapphireDirectoryMetaData *)meta delegate:(id <SapphireMetaDataScannerDelegate>)newDelegate;

/*!
 * @brief Sets a list of directories to skip.
 *
 * This ensures that a directory doesn't get scanned twice.  Every directory that is being scanned is added to this list.
 *
 * @param skip The set of directories to skip.  Note, this set *is* modified
 */
- (void)setSkipDirectories:(NSMutableSet *)skip;

/*!
 * @brief Set the prefetched subdirs/files/etc for this scanner
 *
 * @param subDirs The prefetched dirs contained within this directory
 * @param subFiles The prefetched files contained within this directory
 * @param subSymDirs The prefetched symbolic linked dirs contained within this directory
 * @param subSymFiles The prefetched symbolic linked files contained within this directory
 */
- (void)setSubDirs:(NSArray *)subDirs files:(NSArray *)subFiles symDirs:(NSArray *)subSymDirs symFiles:(NSArray *)subSymFiles;

/*!
 * @brief Sets whether we wish results
 *
 * If the delegate doesn't want results, the result array isn't used.  If the results are desired, the results will be sent to the delegate when finished.  Calling this function starts the scan.
 *
 * @param givesResults YES if the delegate wants results, NO otherwise
 */
- (void)setGivesResults:(BOOL)givesResults;

@end
