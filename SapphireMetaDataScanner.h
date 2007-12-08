//
//  SapphireMetaDataScanner.h
//  Sapphire
//
//  Created by Graham Booker on 7/6/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
