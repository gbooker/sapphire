#import "_SapphireMovie.h"

#define SapphireMovieName		@"Movie"
extern NSString *MOVIE_DID_CHANGE_PREDICATE_MATCHING;

@interface SapphireMovie : _SapphireMovie {}
+ (SapphireMovie *)movieWithIMDB:(int)imdbNumber inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovie *)createMovieWithIMDB:(int)imdbNumber inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovie *)movieWithDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovie *)movieWithDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)moc lookup:(NSDictionary *)lookup;
+ (SapphireMovie *)movieWithTitle:(NSString *)title inContext:(NSManagedObjectContext *)moc;
+ (SapphireMovie *)createMovieWithTitle:(NSString *)title inContext:(NSManagedObjectContext *)moc;
+ (int)imdbNumberFromString:(NSString *)imdbStr;
+ (NSDictionary *)upgradeMoviesVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc withCast:(NSDictionary *)cast directors:(NSDictionary *)directors genres:(NSDictionary *)genres;

- (NSArray *)orderedCast;
- (void)setOrderedCast:(NSArray *)ordered;
- (NSArray *)orderedGenres;
- (void)setOrderedGenres:(NSArray *)ordered;
- (NSArray *)orderedDirectors;
- (void)setOrderedDirectors:(NSArray *)ordered;

- (void)checkOrderedCast;
- (void)checkOrderedGenres;
- (void)checkOrderedDirectors;

- (BOOL)castMemberHasMajorRoleStatus:(SapphireCast *)cast;

/*!
 * @brief Compare two movie's release date
 *
 * @param other The other movie to compare to this one
 * @return The result of the compare
 */
- (NSComparisonResult)releaseDateCompare:(SapphireMovie *)other;

/*!
 * @brief Compare two movie's titles
 *
 * @param other The other movie to compare to this one
 * @return The result of the compare
 */
- (NSComparisonResult)titleCompare:(SapphireMovie *)other;

/*!
 * @brief Compare two movie's imdb rank
 *
 * @param other The other movie to compare to this one
 * @return The result of the compare
 */
- (NSComparisonResult)imdbTop250RankingCompare:(SapphireMovie *)other;

/*!
 * @brief Compare two movie's oscars won
 *
 * @param other The other movie to compare to this one
 * @return The result of the compare
 */
- (NSComparisonResult)oscarsWonCompare:(SapphireMovie *)other;

/*!
 * @brief Compare two movie's imdb rating
 *
 * @param other The other movie to compare to this one
 * @return The result of the compare
 */
- (NSComparisonResult)imdbRatingCompare:(SapphireMovie *)other;

/*!
 * @brief Get the cover art Path
 *
 * Returns the cover art path for this movie
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
