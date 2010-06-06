#import "_SapphireFileMetaData.h"
#import "SapphireMetaData.h"

#define SapphireFileMetaDataName	@"FileMetaData"

//ATV Extra Info
extern NSString *META_SHOW_BROADCASTER_KEY;
extern NSString *META_SHOW_AQUIRED_DATE;
extern NSString *META_SHOW_RATING_KEY;
extern NSString *META_SHOW_FAVORITE_RATING_KEY;
extern NSString *META_COPYRIGHT_KEY;

//General Keys
extern NSString *META_TITLE_KEY;
extern NSString *META_DESCRIPTION_KEY;
extern NSString *META_SUMMARY_KEY;
extern NSString *META_RATING_KEY;
extern NSString *FILE_CLASS_KEY;

//IMDB Type Info
extern NSString *META_MOVIE_TITLE_KEY;
extern NSString *META_MOVIE_CAST_KEY;
extern NSString *META_MOVIE_RELEASE_DATE_KEY;
extern NSString *META_MOVIE_DIRECTOR_KEY;
extern NSString *META_MOVIE_WIRTERS_KEY;
extern NSString *META_MOVIE_GENRES_KEY;
extern NSString *META_MOVIE_PLOT_KEY;
extern NSString *META_MOVIE_IMDB_RATING_KEY;
extern NSString *META_MOVIE_IMDB_250_KEY;
extern NSString *META_MOVIE_MPAA_RATING_KEY;
extern NSString *META_MOVIE_OSCAR_KEY;
extern NSString *META_MOVIE_IDENTIFIER_KEY;
extern NSString *META_SEARCH_IMDB_NUMBER_KEY;
extern NSString	*META_MOVIE_SORT_TITLE_KEY;

//TV Show Specific Keys
extern NSString *META_SEASON_NUMBER_KEY;
extern NSString *META_EPISODE_NUMBER_KEY;
extern NSString *META_SHOW_NAME_KEY;
extern NSString *META_SHOW_AIR_DATE;
extern NSString *META_ABSOLUTE_EP_NUMBER_KEY;
extern NSString *META_EPISODE_2_NUMBER_KEY;
extern NSString *META_ABSOLUTE_EP_2_NUMBER_KEY;
extern NSString *META_SEARCH_SEASON_NUMBER_KEY;
extern NSString *META_SEARCH_EPISODE_NUMBER_KEY;
extern NSString *META_SEARCH_EPISODE_2_NUMBER_KEY;

//File Specific Keys
extern NSString *META_FILE_MODIFIED_KEY;
extern NSString *META_FILE_WATCHED_KEY;
extern NSString *META_FILE_FAVORITE_KEY;
extern NSString *META_FILE_RESUME_KEY;
extern NSString *META_FILE_SIZE_KEY;
extern NSString *META_FILE_DURATION_KEY;
extern NSString *META_FILE_AUDIO_DESC_KEY;
extern NSString *META_FILE_SAMPLE_RATE_KEY;
extern NSString *META_FILE_VIDEO_DESC_KEY;
extern NSString *META_FILE_AUDIO_FORMAT_KEY;
extern NSString *META_FILE_SUBTITLES_KEY;
extern NSString *META_FILE_JOINED_FILE_KEY;


typedef enum {
	IMPORT_TYPE_FILE_MASK = 1,
	IMPORT_TYPE_XML_MASK = 2,
	IMPORT_TYPE_TVSHOW_MASK = 4,
	IMPORT_TYPE_MOVIE_MASK = 8,
	IMPORT_TYPE_ALL_MASK = 0xf,
} ImportTypeMask;


typedef enum {
	FILE_CLASS_UTILITY= -2,
	FILE_CLASS_NOT_FILE= -1,
	FILE_CLASS_UNKNOWN = 0,
	FILE_CLASS_TV_SHOW = 1,
	FILE_CLASS_MOVIE = 2,
	FILE_CLASS_AUDIO = 3,
	FILE_CLASS_IMAGE = 4,
	FILE_CLASS_OTHER = 5,
} FileClass;

typedef enum FileContainerType {
	FILE_CONTAINER_TYPE_QT_MOVIE = 0,
	FILE_CONTAINER_TYPE_VIDEO_TS = 1,
} FileContainerType;

@class SapphireMetaDataUpgrading;

@interface SapphireFileMetaData : _SapphireFileMetaData <SapphireMetaData> {}
+ (SapphireFileMetaData *)fileWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireFileMetaData *)createFileWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc;
+ (SapphireFileMetaData *)createFileWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc;
+ (NSDictionary *)upgradeFilesVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc withMovies:(NSDictionary *)movieLookup directories:(NSDictionary *)dirLookup;

- (void)insertDictionary:(NSDictionary *)dict withDefer:(NSMutableDictionary *)defer;
- (NSComparisonResult) episodeCompare:(SapphireFileMetaData *)other;
- (NSComparisonResult) movieCompare:(SapphireFileMetaData *)other;

/*!
 * @brief See if any files need to be updated
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.
 *
 * @return YES if any files need an update, NO otherwise
 */
- (BOOL) needsUpdating;

/*!
 * @brief See if the file needs some sort of importing
 *
 * This function determins that a file needs some sort of importing.  This import could either be a file, XML, TV, or Movie import.
 *
 * @return YES if the file should have an importer run, NO otherwise
 */
- (BOOL)needsImporting;

/*!
 * @brief Update any files that need to be updated
 *
 * This function determines that a file needs to be updated if its modification time does not match the time remembered in the persistent store.
 *
 * @return YES if any files were updated, NO otherwise
 */
- (BOOL)updateMetaData;

/*!
 * @brief Get the file metadata
 *
 * @param path The path to import
 * @param type The container type of the file
 *
 * @return The file metadata info
 */
NSDictionary *fileMetaData(NSString *path, FileContainerType type);


/*!
 * @brief Adds File data read from the file
 *
 * @param fileMeta The new file metadata.
 */
- (oneway void)addFileData:(bycopy NSDictionary *)fileMeta;

/*!
 * @brief Returns the imports we have done in the past
 *
 * @return A mask of imports done
 */
- (ImportTypeMask)importTypeValue;

/*!
 * @brief Sets the file has having done an import, usually with no data
 *
 * @param The type of import done
 */
- (void)didImportType:(ImportTypeMask)type;

/*!
 * @brief Returns the time of import from a source (file and xml only)
 *
 * @param source The source to check
 * @return The seconds since 1970 of the import
 */
- (long)importedTimeFromSource:(int)source;

/*!
 * @brief Sets the file to re-import from some sources
 *
 * @param mask The sources to reimport on
 */
- (void)setToReimportFromMask:(NSNumber *)mask;

/*!
 * @brief Sets the file to re-import from some sources
 *
 * @param mask The sources to reimport on
 */
- (void)setToReimportFromMaskValue:(int)mask;

/*!
 * @brief Reset import decisions for this file (also mark to re-import)
 */
- (void)setToResetImportDecisions;

/*!
 * @brief Get the file's pretty name based on episode/movie
 *
 * This function returns a pretty name, such as "House S05E15 Unfaithful"
 *
 * @return the file's pretty name, nil if none exists
 */
- (NSString *)prettyName;

/*!
 * @brief Rename a file to it's pretty name
 *
 * @return Move error, if one occurs
 */
- (NSString *)renameToPrettyName;

/*!
 * @brief Return the filename, minus the path extension
 */
- (NSString *)fileName;

/*!
 * @brief Return the path, minus the path extension
 */
- (NSString *)extensionlessPath;

/*!
 * @brief Get the overridden show name
 *
 * Sometimes TVRage's information is horribly wrong (such as Firefly) and it would be a pain to correct.  This allows the user to provide a show name to override what is in the filename.
 *
 * @return the show name to use, nil if none exists
 */
- (NSString *)searchShowName;

/*!
 * @brief Get the overridden season number
 *
 * Sometimes TVRage's information is horribly wrong (such as Firefly) and it would be a pain to correct.  This allows the user to provide a season number to override what is in the filename while not interferring with the number stored in the real season number.
 *
 * @return the season number to use, -1 if none exists
 */
- (int)searchSeasonNumber;

/*!
 * @brief Get the overridden episode number
 *
 * Sometimes TVRage's information is horribly wrong (such as Firefly) and it would be a pain to correct.  This allows the user to provide a episode number to override what is in the filename while not interferring with the number stored in the real episode number.
 *
 * @return the episode number to use, -1 if none exists
 */
- (int)searchEpisodeNumber;

/*!
 * @brief Get the overridden second episode number
 *
 * Sometimes TVRage's information is horribly wrong (such as Firefly) and it would be a pain to correct.  This allows the user to provide a second episode number to override what is in the filename while not interferring with the number stored in the real second episode number.
 *
 * @return the second episode number to use, -1 if none exists
 */
- (int)searchLastEpisodeNumber;

/*!
 * @brief Get the overridden IMDB number
 *
 * Sometimes IMDB can be a pain to search, or gives bad results.  This allows the user to provide an IMDB number and let sapphire fetch the rest of the data.
 *
 * @return the IMDB number to use, -1 if none exists
 */
- (int)searchIMDBNumber;

/*!
 * @brief Returns the size as a string
 *
 * This will format the size in a human readable format.  It uses strings like 2.1GB and the like.  It always has one decimal number.
 *
 * @return The Size as a string.
 */
- (NSString *)sizeString;

/*!
 * @brief Clear the metadata
 *
 * Removes all metadata for this file.  Useful if the user misidentified the file and wishes to start over on it.
 */
- (void)clearMetaData;

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path.  It will also examine up in the directory structure in order to find the cover art.  It examines both the current directory, the "cover art" subdirectory, and the same for parent directories up to 2 levels.
 *
 * @return The path for the cover art, nil if none found
 */
- (NSString *)coverArtPath;

/*!
 * @brief Get the duration as a string
 */
- (NSString *)durationString;

/*!
 * @brief Moves a file to a new directory and updates metadata
 *
 * @param dir The new directory for the file
 */
- (NSString *)moveToDir:(SapphireDirectoryMetaData *)dir;

@end
