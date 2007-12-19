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

#import <Cocoa/Cocoa.h>

#import "SapphireMetaData.h"

/*!
 * @brief The metadata scanning class
 *
 * This class is a helper class to allow the directory metadata to deep scan the contents of a directory.
 */
@interface SapphireMetaDataScanner : NSObject <SapphireMetaDataScannerDelegate> {
	SapphireDirectoryMetaData				*metaDir;			/*!< @brief The scanning directory*/
	NSMutableArray							*remaining;			/*!< @brief The reaming objects to scan*/
	NSMutableArray							*results;			/*!< @brief The current results of the scan*/
	NSMutableSet							*skipDirectories;	/*!< @brief The directories to skip*/
	id <SapphireMetaDataScannerDelegate>	delegate;			/*!< @brief The delegate to inform about the results*/
	NSTimer									*nextFileTimer;		/*!< @brief The timer to get the next file*/
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
 * @brief Sets whether we wish results
 *
 * If the delegate doesn't want results, the result array isn't used.  If the results are desired, the results will be sent to the delegate when finished.  Calling this function starts the scan.
 *
 * @param givesResults YES if the delegate wants results, NO otherwise
 */
- (void)setGivesResults:(BOOL)givesResults;

@end
