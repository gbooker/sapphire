#import "_SapphireEpisode.h"

#define SapphireEpisodeName		@"Episode"

@interface SapphireEpisode : _SapphireEpisode {
	NSArray			*sortedSubEpisodes;
}
+ (SapphireEpisode *)episode:(int)ep inSeason:(int)season forShow:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc;
+ (SapphireEpisode *)episodeTitle:(NSString *)title inSeason:(int)season forShow:(NSString *)show withPath:(NSString *)showPath inContext:(NSManagedObjectContext *)moc;
+ (SapphireEpisode *)episodeWithDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)moc;
+ (void)upgradeV1EpisodesFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup;

- (int)episodeNumberValue;
- (int)lastEpisodeNumberValue;
- (NSString *)episodeTitle;
- (NSComparisonResult)compare:(SapphireEpisode *)other;
- (NSComparisonResult)airDateCompare:(SapphireEpisode *)other;

- (void)insertAdditionalEpisode:(NSDictionary *)dict;

/*!
 * @brief Get the virtual path
 *
 * @return The path of this episode in the virtual directory
 */
- (NSString *)path;

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path for this episode
 *
 * @return The path for the cover art, nil if none found
 */
- (NSString *)coverArtPath;

/*!
 * @brief Insert preview metadata for a movie
 *
 * @param dict The dictionary to store the metadata
 */
- (void)insertDisplayMetaData:(NSMutableDictionary *)dict;

/*!
 * @brief Clear the watched/favorite cache for this dir and its parents
 *
 * The watched and favorite values for all dirs is cached for speed reasons.  If this value changes, the cache needs to be invalidated
 */
- (void)clearPredicateCache;

@end
