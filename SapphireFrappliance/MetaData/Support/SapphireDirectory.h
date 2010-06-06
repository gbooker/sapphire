/*
 * SapphireDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Apr. 9, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

//Sapphire Virtual Directory Movie Folders
extern NSString *VIRTUAL_DIR_ROOT_PATH;
extern NSString *VIRTUAL_DIR_ALL_PATH;
extern NSString *VIRTUAL_DIR_CAST_PATH;
extern NSString *VIRTUAL_DIR_DIRECTOR_PATH;
extern NSString *VIRTUAL_DIR_GENRE_PATH;
extern NSString *VIRTUAL_DIR_TOP250_PATH;
extern NSString *VIRTUAL_DIR_OSCAR_PATH;

@class SapphireFileMetaData;
@protocol SapphireMetaData;

/*!
 * @brief A protocol for the SapphireMetaData to inform its delegate of updates to data
 *
 * This protocol provides a method by which metadata can send changes back to its delegate.
 */
@protocol SapphireMetaDataDelegate <NSObject>

/*!
 * @brief The import on a file completed
 *
 * If a import of metadata was progressing in the background, the delegate is informed when the process has completed for a file.
 *
 * @param file Filename to the file which completed
 */
- (void)updateCompleteForFile:(NSString *)file;

/*!
 * @brief The directory contents changed, update display
 *
 * A background import can add or remove files from a directory.  The delegate is informed that this has happened so it can update its UI or some other action
 */
- (void)directoryContentsChanged;
@end

/*!
 * @brief A protocol for the SapphireMetaDataScanner to request more data of its delegate
 *
 * Since the SapphireMetaDataScanner runs with the event loop, it needs a method to report back its progress and results.  It also provides a means for the scanner to know it should cancel its process.
 */
@protocol SapphireMetaDataScannerDelegate <NSObject>

/*!
 * @brief Finished scanning the dir
 *
 * The SapphireMetaDataScanner has finished scanning a directory and is ready to return its results.
 *
 * @param subs The subfiles found by the scanner
 */
- (void)gotSubFiles:(NSArray *)subs;

/*!
 * @brief Started Scanning a directory
 *
 * The SapphireMetaDataScanner has started scanning a directory.
 *
 * @param dir The current directory it is scanning
 */
- (void)scanningDir:(NSString *)dir;

/*!
 * @brief Check to see if the scan should be canceled
 *
 * If a delegate wishes to cancel the scan of a directory, then simply return YES to this function, and the scan will cease.
 *
 * @return YES if the scan should be canceled
 */
- (BOOL)getSubFilesCanceled;
@end

/*!
 * @brief The importer Backgrounding protocol
 *
 * This protocol is designed for use with distributed objects.
 */
@protocol SapphireImporterBackgroundProtocol <NSObject>
/*!
 * @brief Tells the importer of a background import
 *
 * This is for use with distributed objects
 */
- (oneway void)informComplete:(BOOL)updated onPath:(NSString *)path;
@end

/*!
 * @brief A protocol for a directory
 *
 * This protocol provides a method by which metadata directories can be used without regard as to whether they are real or virtual
 */
@protocol SapphireDirectory <SapphireMetaData>

/*!
 * @brief Get the delegate for the metadata
 *
 * @return The current delegate
 */
- (id <SapphireMetaDataDelegate>)delegate;

/*!
 * @brief Sets the delegate for the metadata
 *
 * @param newDelegate The new delegate
 */
- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;

/*!
 * @brief Reloads the directory contents
 *
 * This function examines the directory on the disk and reloads the objects contents from what it finds there.
 */
- (void)reloadDirectoryContents;

/*!
 * @brief Returns the path of the current metadata
 *
 * All metadata has a path associated with it; this function returns the path for this one.
 *
 * @return The path
 */
- (NSString *)path;

/*!
 * @brief Retrieve a list of all file names
 *
 * @return An NSArray of all file names
 */
- (NSArray *)files;

/*!
 * @brief Retrieve a list of all directory names
 *
 * @return An NSArray of all directory names
 */
- (NSArray *)directories;

/*!
 * @brief Get the metadata object for a file.
 *
 * @param file The file within this dir
 * @return The file's metadata, nil if one doesn't exist
 */
- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;

/*!
 * @brief Get the metadata object for a directory.
 *
 * @param dir The directory within this dir
 * @return The directory's metadata, nil if one doesn't exist
 */
- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory;

/*!
 * @brief Check to see if any filtered files match the predicate
 *
 * @param pred The predicate to check
 */
- (BOOL)containsFileMatchingPredicate:(NSPredicate *)pred;

/*!
 * @brief Checks to see if directory contains any files with filter
 *
 * @param filter The filter predicate to test
 */
- (BOOL)containsFileMatchingFilterPredicate:(NSPredicate *)pred;

/*!
 * @brief Invoke a command on all files contained within this directory within filter
 *
 * @param fileInv The invocation to invoke
 */
- (void)invokeOnAllFiles:(NSInvocation *)fileInv;

/*!
 * @brief Gets the filter predicate in use for filtering in this directory
 *
 * @return The predict in use
 */
- (NSPredicate *)filterPredicate;

/*!
 * @brief Sets the filter predicate to use for filtering in this directory
 *
 * @param predicate The predict to use
 */
- (void)setFilterPredicate:(NSPredicate *)predicate;

/*!
 * @brief Resume the import process
 */
- (void)resumeImport;

/*!
 * @brief Cancel the import process
 */
- (void)cancelImport;

/*!
 * @brief Get the metadata for all the files contained within this directory tree
 *
 * @param subDelegate The delegate to inform when scan is complete
 * @param skip A set of directories to skip.  Note, this set is modified
 */
- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;

/*!
 * @brief Scan for all files contained within this directory tree
 *
 * @param subDelegate The delegate to inform when scan is complete
 * @param skip A set of directories to skip.  Note, this set is modified
 */
- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path for this show
 *
 * @return The path for the cover art, nil if none found
 */
- (NSString *)coverArtPath;

/*!
 * @brief Clear the watched/favorite cache for this dir and its parents
 *
 * The watched and favorite values for all dirs is cached for speed reasons.  If this value changes, the cache needs to be invalidated
 */
- (void)clearPredicateCache;

/*!
 * @brief The managed object context
 *
 * @return The managed object context for the metadata
 */
- (NSManagedObjectContext *)managedObjectContext;

/*!
 * @brief Turn all managed objects directly in this directory into faults
 *
 * This function turns the managed objects into faults.  This means when they are next referenced,
 * they will refetch data from the store.  It is also used to allow core data to free memory
 */
- (void)faultAllObjects;

/*!
 * @brief Returns whether the managed object is deleted
 *
 * @return YES if the current directory is deleted, NO otherwise
 */
- (BOOL)objectIsDeleted;

@end

@protocol SapphireSortableDirectory <SapphireDirectory>

/*!
 * @brief Gets the available file sorters, default first
 *
 * @return The available file sorters, default first
 */
- (NSArray *)fileSorters;

/*!
 * @brief Gets the sort method used
 *
 * @return The sort method used
 */
- (int)sortMethodValue;

/*!
 * @brief Sets the sort method to use
 *
 * @param value_ The sort method to use
 */
- (void)setSortMethodValue:(int)value_;

@end


/*!
 * @brief Set subtree to watched or unwatched with restriction as to predicate.  Does not follow symlinks
 *
 * @param dir The subtree
 * @param watched YES if watched, NO otherwise
 */
void setSubtreeToWatched(id <SapphireDirectory> dir, BOOL watched);

/*!
 * @brief Set subtree to favorite or not favorite with restriction as to predicate.  Does not follow symlinks
 *
 * @param dir The subtree
 * @param favorite YES if favorite, NO otherwise
 */
void setSubtreeToFavorite(id <SapphireDirectory> dir, BOOL favorite);

/*!
 * @brief Set subtree to re-import from the specified source with restriction as to predicate.  Does not follow symlinks
 *
 * @param dir The subtree
 * @param mask The source(s) on which to re-import
 */
void setSubtreeToReimportFromMask(id <SapphireDirectory> dir, int mask);

/*!
 * @brief Clear metadata for an entire subtree with restriction as to predicate.  Does not follow symlinks
 */
void setSubtreeToClearMetaData(id <SapphireDirectory> dir);

/*!
 * @brief Reset import decisions for this file (also mark to re-import) for an entire subtree with restriction as to predicate.  Does not follow symlinks
 */
void setSubtreeToResetImportDecisions(id <SapphireDirectory> dir);
