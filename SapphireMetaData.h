//
//  SapphireMetaData.h
//  Sapphire
//
//  Created by Graham Booker on 6/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
#define VIRTUAL_DIR_CAST_KEY			@"By Cast"
#define VIRTUAL_DIR_DIRECTOR_KEY		@"By Director"
#define VIRTUAL_DIR_GENRE_KEY			@"By Genre"
#define VIRTUAL_DIR_TOP250_KEY			@"IMDB Top 250"
#define VIRTUAL_DIR_OSCAR_KEY			@"Academy Award Winning"

#define META_DATA_FILE_INFO_KIND						@"MetaDataFileInfoKind"
#define FILE_CLASS_KEY				@"File Class"
typedef enum {
	FILE_CLASS_NOT_FILE= -1,
	FILE_CLASS_UNKNOWN = 0,
	FILE_CLASS_TV_SHOW = 1,
	FILE_CLASS_MOVIE = 2,
	FILE_CLASS_AUDIO = 3,
	FILE_CLASS_IMAGE = 4,
	FILE_CLASS_OTHER = 5,
} FileClass;

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

@interface SapphireMetaData : NSObject {
	NSMutableDictionary				*metaData;
	SapphireMetaData				*parent;
	/* These two are not retained */
	NSString						*path;
	id <SapphireMetaDataDelegate>	delegate;
}

+ (NSSet *)videoExtensions;
+ (NSSet *)audioExtensions;
- (NSString *)path;

- (void)setDelegate:(id <SapphireMetaDataDelegate>)newDelegate;
- (void)writeMetaData;
- (SapphireMetaDataCollection *)collection;
- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;

@end

@interface SapphireMetaDataCollection : SapphireMetaData {
	NSMutableDictionary			*directories;
	NSMutableDictionary			*skipCollection;
	NSMutableDictionary			*hideCollection;
	NSString					*dictionaryPath;
	NSTimer						*writeTimer;
}
- (id)initWithFile:(NSString *)dictionary;
- (SapphireMetaData *)dataForPath:(NSString *)path;
- (SapphireDirectoryMetaData *)directoryForPath:(NSString *)path;
- (SapphireMetaData *)dataForPath:(NSString *)path withData:(NSDictionary *)data;
- (NSArray *)collectionDirectories;
- (BOOL)hideCollection:(NSString *)collection;
- (void)setHide:(BOOL)hide forCollection:(NSString *)collection;
- (BOOL)skipCollection:(NSString *)collection;
- (void)setSkip:(BOOL)skip forCollection:(NSString *)collection;

@end

@interface SapphireDirectoryMetaData : SapphireMetaData {
	/*These two are not retained*/
	NSMutableDictionary			*metaFiles;
	NSMutableDictionary			*metaDirs;
	
	NSMutableDictionary			*cachedMetaFiles;
	NSMutableDictionary			*cachedMetaDirs;

	NSMutableArray				*files;
	NSMutableArray				*directories;
	
	NSTimer						*importTimer;
	NSMutableArray				*importArray;
	BOOL						scannedDirectory;
	
	/*This is not retained*/
	SapphireMetaDataCollection	*collection;
}

- (void)reloadDirectoryContents;
- (NSString *)coverArtPath;
- (NSArray *)files;
- (NSArray *)directories;
- (NSArray *)predicatedFiles:(SapphirePredicate *)predicate;
- (NSArray *)predicatedDirectories:(SapphirePredicate *)predicate;

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file;
- (SapphireDirectoryMetaData *)metaDataForDirectory:(NSString *)dir;

- (BOOL)pruneMetaData;
- (BOOL)updateMetaData;

- (void)cancelImport;
- (void)resumeImport;
- (void)resumeDelayedImport;

- (SapphireMetaData *)metaDataForSubPath:(NSString *)path;
- (void)getSubFileMetasWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;
- (void)scanForNewFilesWithDelegate:(id <SapphireMetaDataScannerDelegate>)subDelegate skipDirectories:(NSMutableSet *)skip;
- (void)loadMetaData;

- (BOOL)watchedForPredicate:(SapphirePredicate *)predicate;
- (void)setWatched:(BOOL)watched forPredicate:(SapphirePredicate *)predicate;
- (BOOL)favoriteForPredicate:(SapphirePredicate *)predicate;
- (void)setFavorite:(BOOL)favorite forPredicate:(SapphirePredicate *)predicate;
- (void)setToImportFromSource:(NSString *)source forPredicate:(SapphirePredicate *)predicate;
- (void)setFileClass:(FileClass)fileClass forPredicate:(SapphirePredicate *)predicate;
- (void)clearMetaDataForPredicate:(SapphirePredicate *)predicate;

@end

@interface SapphireFileMetaData : SapphireMetaData {
	NSDictionary		*combinedInfo;
}

- (NSString *)coverArtPath;

- (BOOL) updateMetaData;

- (int)modified;
- (BOOL)watched;
- (void)setWatched:(BOOL)watched;
- (BOOL)favorite;
- (void)setFavorite:(BOOL)favorite;
- (long)importedTimeFromSource:(NSString *)source;
- (void)setToImportFromSource:(NSString *)source;
- (void)importInfo:(NSMutableDictionary *)newMeta fromSource:(NSString *)source withTime:(long)modTime;
- (void)clearMetaData;
- (unsigned int)resumeTime;
- (void)setResumeTime:(unsigned int)resumeTime;
- (FileClass)fileClass;
- (void)setFileClass:(FileClass)fileClass;
- (NSString *)joinedFile;
- (void)setJoinedFile:(NSString *)join;

- (long long)size;
- (float)duration;
- (Float64)sampleRate;
- (UInt32)audioFormatID;
- (BOOL)hasVideo;
- (int)episodeNumber;
- (int)seasonNumber;
- (int)oscarsWon;
- (int)imdbTop250;
- (NSString *)episodeTitle;
- (NSString *)movieTitle;
- (NSDate *)movieReleaseDate;
- (NSString *)movieStatsOscar;
- (NSString *)movieStatsTop250;
- (NSString *)movieID;
- (NSString *)showID;
- (NSString *)showName ;
- (NSArray *)movieGenres;
- (NSArray *)movieCast;
- (NSArray *)movieDirectors;
- (NSString *)sizeString;

@end