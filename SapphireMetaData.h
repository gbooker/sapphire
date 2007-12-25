/*
 * SapphireMetaData.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 22, 2007.
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
#import "SapphirePredicates.h"

#define META_TVRAGE_IMPORT_KEY			@"TVRage Source"
#define META_IMDB_IMPORT_KEY			@"IMDB Source"
#define META_POSTER_IMPORT_KEY			@"Poster Source"
#define META_XML_IMPORT_KEY				@"XML Source"

//TV Show Specific Keys
#define META_TITLE_KEY					@"Title"
#define META_SEASON_NUMBER_KEY			@"Season"
#define META_EPISODE_NUMBER_KEY			@"Episode"
#define META_SHOW_NAME_KEY				@"Show Name"
#define META_DESCRIPTION_KEY			@"Show Description"
#define META_SHOW_AIR_DATE				@"Air Date"
#define META_RATING_KEY					@"Rating"
#define META_SUMMARY_KEY				@"Summary"
#define META_ABSOLUTE_EP_NUMBER_KEY		@"Episode Number"
#define META_SHOW_IDENTIFIER_KEY		@"Show ID"

//ATV Extra Info
#define META_SHOW_BROADCASTER_KEY		@"Broadcast Company"
#define META_SHOW_PUBLISHED_DATE_KEY	@"Published Date"
#define META_SHOW_AQUIRED_DATE			@"Date Aquired"
#define META_SHOW_RATING_KEY			@"Rating"
#define META_SHOW_FAVORITE_RATING_KEY	@"User Rating"
#define META_COPYRIGHT_KEY				@"Copyright"

//IMDB Type Info
#define META_MOVIE_TITLE_KEY				@"Title"
#define META_MOVIE_CAST_KEY					@"Cast"
#define META_MOVIE_RELEASE_DATE_KEY			@"Release Date"
#define	META_MOVIE_DIRECTOR_KEY				@"Director"
#define	META_MOVIE_WIRTERS_KEY				@"Writers"
#define	META_MOVIE_GENRES_KEY				@"Genres"
#define META_MOVIE_PLOT_KEY					@"Plot"
#define META_MOVIE_IMDB_RATING_KEY			@"IMDB Rating"
#define META_MOVIE_IMDB_250_KEY				@"IMDB Top 250"
#define META_MOVIE_MPAA_RATING_KEY			@"MPAA Rating"
#define META_MOVIE_OSCAR_KEY				@"Oscars"
#define META_MOVIE_IDENTIFIER_KEY			@"Movie ID"

//Special Display Only Info (MediaPreview)
#define META_EPISODE_AND_SEASON_KEY		@"S/E"
#define	META_MOVIE_IMDB_STATS_KEY		@"IMDB"
#define AUDIO_DESC_LABEL_KEY			@"Audio"
#define VIDEO_DESC_LABEL_KEY			@"Video"

//Sapphire Virtual Directory Movie Folders
#define VIRTUAL_DIR_ROOT_KEY			@"@MOVIES"
#define VIRTUAL_DIR_ALL_KEY				@"All Movies"
//#define VIRTUAL_DIR_PREMIER_KEY			@"By Premier Date"
#define VIRTUAL_DIR_CAST_KEY			@"By Cast"
#define VIRTUAL_DIR_DIRECTOR_KEY		@"By Director"
#define VIRTUAL_DIR_GENRE_KEY			@"By Genre"
#define VIRTUAL_DIR_TOP250_KEY			@"IMDB Top 250"
//#define VIRTUAL_DIR_IMDB_RATING_KEY		@"By IMDB User Rating"
#define VIRTUAL_DIR_OSCAR_KEY			@"Academy Award Winning"


#define META_DATA_FILE_INFO_KIND		@"MetaDataFileInfoKind"
#define FILE_CLASS_KEY					@"File Class"
#define FILE_CONTAINER_TYPE_KEY			@"File Container Type"
typedef enum {
	FILE_CLASS_NOT_FILE= -1,
	FILE_CLASS_UNKNOWN = 0,
	FILE_CLASS_TV_SHOW = 1,
	FILE_CLASS_MOVIE = 2,
	FILE_CLASS_AUDIO = 3,
	FILE_CLASS_IMAGE = 4,
	FILE_CLASS_OTHER = 5,
} FileClass;

typedef enum {
	FILE_CONTAINER_TYPE_QT_MOVIE = 0,
	FILE_CONTAINER_TYPE_VIDEO_TS = 1,
} FileContainerType;

#define META_DATA_FILE_ADDED_NOTIFICATION				@"MetaDataFileAdded"
#define META_DATA_FILE_REMOVED_NOTIFICATION				@"MetaDataFileRemoved"
#define META_DATA_FILE_INFO_WILL_CHANGE_NOTIFICATION	@"MetaDataFileInfoWillChange"
#define META_DATA_FILE_INFO_HAS_CHANGED_NOTIFICATION	@"MetaDataFileInfoHasChanged"
#define META_DATA_FILE_INFO_STARTED_LOADING				@"MetaDataFileInfoStartedLoading"
#define META_DATA_FILE_INFO_FINISHED_LOADING			@"MetaDataFileInfoFinishedLoading"

@class SapphireMetaData, SapphireMetaDataCollection, SapphireFileMetaData, SapphireDirectoryMetaData;

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
- (oneway void)informComplete:(BOOL)updated;
@end

/*!
 * @brief The base metadata protocol
 *
 * This protocol is designed for use with distributed objects.
 */
@protocol SapphireMetaDataProtocol <NSObject>
/*!
 * @brief Returns the path of the current metadata
 *
 * All metadata has a path associated with it; this function returns the path for this one.
 *
 * @return The path
 */
- (NSString *)path;

@end

/*!
 * @brief The base metadata class
 *
 * This is the base class for all metadata.  All metadata is based upon this class.
 */
@interface SapphireMetaData : NSObject <SapphireMetaDataProtocol>{
	NSMutableDictionary				*metaData;	/*!< @brief A basic dictionary which contains all persistent data*/
	SapphireMetaData				*parent;	/*!< @brief The parent metadata (not retained)*/
	NSString						*path;		/*!< @brief The path of this directory or file*/
	id <SapphireMetaDataDelegate>	delegate;	/*!< @brief The delegate to inform about changes(not retained)*/
}

/*!
 * @brief All the video extensions
 *
 * This function returns the set of all allowed video extensions
 *
 * @return The set of all video extensions
 */
+ (NSSet *)videoExtensions;

/*!
 * @brief All the audio extensions
 *
 * This function returns the set of all allowed audio extensions
 *
 * @return The set of all audio extensions
 */
+ (NSSet *)audioExtensions;

/*!
 * @brief the collection art parent path
 *
 * This function returns the path for the parent cover art directory
 *
 * @return The collection art path
 */
+ (NSString *)collectionArtPath;

/*!
 * @brief Creates a new metadata object
 *
 * This creates a new metadata object with a given parent and path.  It reads its data from the given dictionary and recreates a mutable copy of the dictionary.
 *
 * @param dict The configuration dictionary.  Note, this dictionary is copied and the copy is modified
 * @param myParent The parent metadata
 * @param myPath The path for this metadata
 * @return The metadata object
 */
- (id)initWithDictionary:(NSMutableDictionary *)dict parent:(SapphireMetaData *)myParent path:(NSString *)myPath;

/*!
 * @brief Sets the delegate for the metadata
 *
 * @param newDelegate The new delegate
 */
- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;

/*!
 * @brief Write all the metadata to a file.
 *
 * This function uses the parent to write the metadata up until it gets to the root.  Then the collection metadata is writen to the persistent store.
 */
- (void)writeMetaData;

/*!
 * @brief Gets the collection
 *
 * This function uses the parent to get the collection.  The root metadata is the collection
 *
 * @return The metadata collection
 */
- (SapphireMetaDataCollection *)collection;

/*!
 * @brief Get the metadata for display
 *
 * The metadata preview needs information about what data to display.  This function gets all the information for this metadata.
 *
 * @param order A pointer to an NSArray * in which to store the order in which the metadata is to be displayed
 * @return The display metadata with the titles as keys
 */
- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;

@end

/*!
 * @brief The metadata collection
 *
 * This is the root of all the metadata.  Everything is stems from this class
 */
@interface SapphireMetaDataCollection : SapphireMetaData {
	NSMutableDictionary			*directories;		/*!< @brief The root directory metadata objects*/
	NSMutableDictionary			*skipCollection;	/*!< @brief The list of collections to skip, YES if is should be skipped, NO otherwise*/
	NSMutableDictionary			*hideCollection;	/*!< @brief The list of collections to hide, YES if is should be hidden, NO otherwise*/
	NSMutableArray				*collectionDirs;	/*!< @brief The list of extra collections to add to the list*/
	NSString					*dictionaryPath;	/*!< @brief The path of the persistent store*/
	NSTimer						*writeTimer;		/*!< @brief The timer to consolodate all writes into a single write (not retained)*/
}

/*!
 * @brief Create a collection from a file and browsing a directory
 *
 * This creates a metadata collection from a persistent store.  It also remembers the location of the persistent store so that it can be saved in the future.
 *
 * @param dictionary The path to the dictionary storing the metadata
 * @param myPath The path to browse for the metadata
 * @return The metadata collection
 */
- (id)initWithFile:(NSString *)dictionary;

/*!
 * @brief Returns the metadata for a particular path
 *
 * Given a particular path, this function returns the metadata at that path.
 *
 * @param path The path to find
 * @return The directory metadata for the path, or nil if none exists
 */
- (SapphireMetaData *)dataForPath:(NSString *)path;

/*!
 * @brief Returns the metadata for a particular path with data
 *
 * Given a particular path, this function returns the metadata at that path.  If the found metadata contains no data, the inserted metadata is used instead.  This is used for symbolic link resolution.
 *
 * @param path The path to find
 * @param data The metadata to use in place of the source's data
 * @return The directory metadata for the path, or nil if none exists
 */
- (SapphireMetaData *)dataForPath:(NSString *)path withData:(NSDictionary *)data;

/*!
 * @brief just like dataForPath: but specific to directories
 *
 * @param path The path to find
 * @return The directory metadata for the path, or nil if none exists
 */
- (SapphireDirectoryMetaData *)directoryForPath:(NSString *)path;

/*!
 * @brief Gets a listing of all valid collection directories.
 * 
 * This is the list of all valid collections.  It contains the list of all mounted disks plus homedir/Movies.  These collections are displayed in the main menu (if not hidden).
 *
 * @return All the collection locations
 */
- (NSArray *)collectionDirectories;

/*!
 * @brief Returns whether the collection is hidden or not
 *
 * If a collection is hidden, then it is not displayed in the main menu
 *
 * @return YES if the collection is hidden, NO otherwise
 */
- (BOOL)hideCollection:(NSString *)collection;

/*!
 * @brief Set whether to hide the collection or not
 *
 * If a collection is hidden, then it is not displayed in the main menu
 *
 * @param hide YES to hide this collection, NO otherwise
 */
- (void)setHide:(BOOL)hide forCollection:(NSString *)collection;

/*!
 * @brief Returns whether the collection is skipped or not
 *
 * If a collection is skipped, it will not be imported
 *
 * @return YES if the collection is skipped, NO otherwise
 */
- (BOOL)skipCollection:(NSString *)collection;

/*!
 * @brief Set whether to skip the collection or not
 *
 * If a collection is skipped, it will not be imported
 *
 * @param skip YES to skip this collection, NO otherwise
 */
- (void)setSkip:(BOOL)skip forCollection:(NSString *)collection;

/*!
 * @brief Add a collection
 *
 * This function adds a directory to the list of collections.
 *
 * @param dir The directory to add to the collection list
 */
- (void)addCollectionDirectory:(NSString *)dir;

/*!
 * @brief Checks to see if a dir is a collection
 *
 * This function checks a directory to see if it is in the list of collections.
 *
 * @param dir The directory to check
 * @return YES if it is a collection, NO otherwise
 */
- (BOOL)isCollectionDirectory:(NSString *)dir;

/*!
 * @brief Remove a collection
 *
 * This function removes a directory frome the list of collections.  This has no effect on mount points.
 *
 * @param dir The directory to remove from the collection list
 */
- (void)removeCollectionDirectory:(NSString *)dir;

@end

/*!
 * @brief A metadata directory
 *
 * This class is designed to be a directory, virtual or real.  It contains other directories and files.
 */
@interface SapphireDirectoryMetaData : SapphireMetaData <SapphireImporterBackgroundProtocol>{
	NSMutableDictionary			*metaFiles;				/*!< @brief The metadata persistent store for files (not retained)*/
	NSMutableDictionary			*metaDirs;				/*!< @brief The metadata persistent store for directories (not retained)*/
	
	NSMutableDictionary			*cachedMetaFiles;		/*!< @brief Metadata objects for files*/
	NSMutableDictionary			*cachedMetaDirs;		/*!< @brief Metadata objects for directories*/

	NSMutableArray				*files;					/*!< @brief	File keys in sorted order*/
	NSMutableArray				*directories;			/*!< @brief Directory keys in sorted order*/
	
	int							importing;				/*!< @brief bit 0 is set if background importing of data, bit 1 if awaiting data*/
	NSMutableArray				*importArray;			/*!< @brief Array of objects left to import*/
	BOOL						scannedDirectory;		/*!< @brief YES if the directory has already been examined on disk, NO if just using cached information*/
	
	SapphireMetaDataCollection	*collection;			/*!< @brief The root collection (not retained)*/
	NSTimer						*loadTimer;				/*!< @brief The timer to load this metadata*/
}

/*!
 * @brief Reloads the directory contents
 *
 * This function examines the directory on the disk and reloads the objects contents from what it finds there.
 */
- (void)reloadDirectoryContents;

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path.  It will also examine up in the directory structure in order to find the cover art.  It examines both the current directory, the "cover art" subdirectory, and the same for parent directories up to 2 levels.
 *
 * @return The path for the cover art, nil if none found
 */
- (NSString *)coverArtPath;

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
 * @brief Get a listing of predicate files
 *
 * @param predicate The predicate to match
 * @return An NSArray of matches
 */
- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate;

/*!
 * @brief Get a listing of predicated directories
 *
 * @param predicate The predicate to match
 * @return An NSArray of matches
 */
- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate;


/*!
 * @brief Get the metadata object for a file.  Creates one if it doesn't already exist
 *
 * @param file The file within this dir
 * @return The file's metadata
 */
- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;

/*!
 * @brief Get the metadata object for a directory.  Creates one if it doesn't alreay exist
 *
 * @param dir The directory within this dir
 * @return The directory's metadata
 */
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)dir;


/*!
 * @brief Prunes off old data
 *
 * This function prunes off non-existing files and directories from the metadata.  This does not prune a directory's content if it contains no files and directories.  In addition, broken sym links are also not pruned.  The theory is these may be the signs of missing mounts.
 *
 * @return YES if any data was pruned, NO otherwise
 */
- (BOOL)pruneMetaData;

/*!
 * @brief Update any files that need to be updated
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.
 *
 * @return YES if any files were updated, NO otherwise
 */
- (BOOL)updateMetaData;


/*!
 * @brief Cancel the import process
 */
- (void)cancelImport;

/*!
 * @brief Resume the import process
 */
- (void)resumeImport;

/*!
 * @brief Get the metadata for some file or directory beneath this one
 *
 * @param subPath The subpath to get the metadata
 * @return The metadata object
 */
- (SapphireMetaData *)metaDataForSubPath:(NSString *)path;

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
 * @brief Load all the cached metadata so that dynamic directories can build
 */
- (void)loadMetaData;


/*!
 * @brief Returns if directory contains any unwatched files
 *
 * @param predicate The predicate to match on
 * @return YES if all files are watched, NO otherwise
 */
- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Set subtree as watched
 *
 * @param watched YES if set to watched, NO if set to unwatched
 * @param predicate The predicate which to restrict setting
 */
- (void)setWatched:(BOOL)watched forPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Returns if directory contains any favorite files
 *
 * @param predicate The predicate to match on
 * @return YES if at least one exists, NO otherwise
 */
- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Set subtree as favorite
 *
 * @param watched YES if set to favorite, NO if set to not favorite
 * @param predicate The predicate which to restrict setting
 */
- (void)setFavorite:(BOOL)favorite forPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Set subtree to re-import from the specified source
 *
 * @param source The source on which to re-import
 * @param predicate The predicate which to restrict setting
 */
- (void)setToImportFromSource:(NSString *)source forPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Set subtree to the specified class
 *
 * @param fileClass The file class
 * @param predicate The predicate which to restrict setting
 */
- (void)setFileClass:(FileClass)fileClass forPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Clear metadata for an entire subtree
 *
 * @param predicate The predicate which to restrict setting
 */
- (void)clearMetaDataForPredicate:(SapphirePredicate *)predicate;

@end

/*!
 * @brief The metadata file protocol
 *
 * This protocol is designed for use with distributed objects.
 */
@protocol SapphireFileMetaDataProtocol <SapphireMetaDataProtocol>
/*!
 * @brief See if any files need to be updated
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.
 *
 * @return YES if any files need an update, NO otherwise
 */
- (BOOL) needsUpdating;

/*!
 * @brief Adds File data read from the file
 *
 * @param fileMeta The new file metadata.
 */
- (oneway void)addFileData:(bycopy NSDictionary *)fileMeta;

/*!
 * @brief Returns the time of import from a source
 *
 * @param source The source to check
 * @return The seconds since 1970 of the import
 */
- (long)importedTimeFromSource:(NSString *)source;

/*!
 * @brief Add data to import from a source
 *
 * This data will be combined in the combined info to display in the preview.
 *
 * @param newMeta The new metadata
 * @param source The source we imported from
 * @param modTime The modification time of the source
 */
- (oneway void)importInfo:(bycopy NSMutableDictionary *)newMeta fromSource:(bycopy NSString *)source withTime:(long)modTime;


/*!
 * @brief The file type
 *
 * @return The file type
 */
- (FileClass)fileClass;

/*!
 * @brief Sets the file type
 *
 * @param fileClass The file type
 */
- (void)setFileClass:(FileClass)fileClass;

/*!
 * @brief The file container type
 *
 * This indicates if the file is a QT movie or other (such as VIDEO_TS)
 *
 * @return The file container type
 */
- (FileContainerType)fileContainerType;

/*!
 * @brief Sets the file container type
 *
 * This indicates if the file is a QT movie or other (such as VIDEO_TS)
 *
 * @param fileContainerType The file container type
 */
- (void)setFileContainerType:(FileContainerType)fileContainerType;


@end

/*!
 * @brief See if the file need to be updated and do so
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.  If it does, the update is performed.  It is intended to only be used in distributed objects.
 *
 * @return YES if file was updated, NO otherwise
 */
BOOL updateMetaData(id <SapphireFileMetaDataProtocol> file);

/*!
 * @brief A metadata file
 *
 * This class is designed to be a file.  It contains information about a specific file.
 */
@interface SapphireFileMetaData : SapphireMetaData <SapphireFileMetaDataProtocol> {
	NSDictionary		*combinedInfo;	/*!< @brief The combined preview info from multiple sources*/
}

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path.  It will also examine up in the directory structure in order to find the cover art.  It examines both the current directory, the "cover art" subdirectory, and the same for parent directories up to 2 levels.
 *
 * @return The path for the cover art, nil if none found
 */
- (NSString *)coverArtPath;

/*!
 * @brief See if the file need to be updated and do so
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.  If it does, the update is performed.
 *
 * @return YES if file was updated, NO otherwise
 */
- (BOOL) updateMetaData;


/*!
 * @brief Get date of last modification of the file
 *
 * @return Seconds since 1970 of last modification
 */
- (int)modified;

/*!
 * @brief Returns whether the file has been watched
 *
 * @return YES if watched, NO otherwise
 */
- (BOOL)watched;

/*!
 * @brief Sets the file as watch or not watched
 *
 * @param watched YES if set to watched, NO if set to unwatched
 */
- (void)setWatched:(BOOL)watched;

/*!
 * @brief Returns whether the file is favorite
 *
 * @return YES if favorite, NO otherwise
 */
- (BOOL)favorite;

/*!
 * @brief Sets the file as favorite or not favorite
 *
 * @param watched YES if set to favorite, NO if set to not favorite
 */
- (void)setFavorite:(BOOL)favorite;

/*!
 * @brief Sets the file to re-import from source
 *
 * @param source The source to re-import
 */
- (void)setToImportFromSource:(NSString *)source;

/*!
 * @brief Clear the metadata
 *
 * Removes all metadata for this file.  Useful if the user misidentified the file and wishes to start over on it.
 */
- (void)clearMetaData;

/*!
 * @brief The resume time of the file
 *
 * @return The number of seconds from the begining of the file to resume
 */
- (unsigned int)resumeTime;

/*!
 * @brief Sets the resume time of the file
 *
 * @param resumeTime The number of seconds from the beginning of the file to resume
 */
- (void)setResumeTime:(unsigned int)resumeTime;

/*!
 * @brief The file this has been joined to
 *
 * The file is hidden from display as long as its joined file exists
 *
 * @return The file this has been joined to
 */
- (NSString *)joinedFile;

/*!
 * @brief Sets the file this has been joined to
 *
 * Remember which file a file has been joined to so if the resulting file disappears, the original can be shown again
 *
 * @param fileClass The file this has been joined to
 */
- (void)setJoinedFile:(NSString *)join;


/*!
 * @brief Returns the file size
 *
 * Important:  An int isn't big enough.  This is stored internally using NSNumber, so the size can be much bigger than 4G.
 *
 * @return The file size
 */
- (long long)size;

/*!
 * @brief Returns the file's duration in seconds
 *
 * @return The file's duration
 */
- (float)duration;

/*!
 * @brief Returns the sample rate of the file
 *
 * @return The sample rate of the file
 */
- (Float64)sampleRate;

/*!
 * @brief Returns the audio format of the file
 *
 * This is a fourcc code.  AC3 would be 'ac-3' or 0x6D732000
 *
 * @return The audio format of the file
 */
- (UInt32)audioFormatID;

/*!
 * @brief Returns whether the file has video
 *
 * @return YES if the file has video, NO otherwise
 */
- (BOOL)hasVideo;


/*!
 * @brief Returns the epsiode number of the file
 *
 * @return The episode number of the file
 */
- (int)episodeNumber;

/*!
 * @brief Returns the season number of the file
 *
 * @return The season number of the file
 */
- (int)seasonNumber;

/*!
 * @brief Returns the number of oscars for a movie
 *
 * @return The number of oscars won
 */
- (int)oscarsWon;

/*!
 * @brief Returns the rank for a movie in the imdb 250
 *
 * @return The number of oscars won
 */
- (int)imdbTop250;

/*!
 * @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSString *)episodeTitle;

/*!
 * @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSString *)movieTitle;

/*!
 * @brief Returns the title of the file
 *
 * @return The title of the file
 */
- (NSDate *)movieReleaseDate;

/*!
 * @brief Returns movie oscar stats to be used for RightJustifiedText
 *
 * @return The desired stat based on availible info
 */
- (NSString *)movieStatsOscar;

/*!
 * @brief Returns movie top250 stats to be used for RightJustifiedText
 *
 * @return The desired stat based on availible info
 */
- (NSString *)movieStatsTop250;

/*!
 * @brief Returns the Movie ID of the file
 *
 * @return The Movie ID of the file
 */
- (NSString *)movieID;

/*!
 * @brief Returns the show ID of the file
 *
 * @return The show ID of the file
 */
- (NSString *)showID;

/*!
 * @brief Returns the show name of the file
 *
 * @return The show name of the file
 */
- (NSString *)showName ;

/*!
 * @brief Returns the genre of the movie file
 *
 * @return The genre type of the movie file
 */
- (NSArray *)movieGenres;

/*!
 * @brief Returns the cast of the movie file
 *
 * @return The cast of the movie file
 */
- (NSArray *)movieCast;

- (NSArray *)movieDirectors;

/*!
 * @brief Returns the size as a string
 *
 * This will format the size in a human readable format.  It uses strings like 2.1GB and the like.  It always has one decimal number.
 *
 * @return The Size as a string.
 */
- (NSString *)sizeString;

@end