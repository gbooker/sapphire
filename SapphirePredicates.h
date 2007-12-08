//
//  SapphirePredicates.h
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@class SapphireFileMetaData;

/*!
 * @brief A class which returns a YES or NO on a per file basis stating whether the file matches the predicate or not.
 *
 * This class is the basis for filtering in all of Sapphire.  Predicates either match files or not which determines if they are displayed or hidden.
 */
@interface SapphirePredicate : NSObject {
}

/*!
 * @brief States whether we should accept this file or not
 *
 * If there is a metadata for the file, it is passed in, otherwise nil is used.  A predicate must be able to return a YES or NO based upon the path and/or the metadata.
 *
 * @param path The file's path
 * @param metaData The file's metadata if it exists, nil otherwise
 * @return YES if the file is accepted by the predicate, NO otherwise
 */
- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData;

@end

/*!
 * @brief A subclass of SapphirePredicate for unwatched files
 *
 * This class returns YES if the file is unwatched or no metadata exists, NO otherwise.
 */
@interface SapphireUnwatchedPredicate : SapphirePredicate {
}
@end

/*!
 * @brief A subclass of SapphirePredicate for favorite files
 *
 * This class returns YES if the file is a favorite, NO otherwise.
 */
@interface SapphireFavoritePredicate : SapphirePredicate {
}
@end

/*!
 * @brief A subclass of SapphirePredicate for top shows
 *
 * This class returns YES if the file is a top show, NO otherwise.
 *
 * Not yet implemented.
 */
@interface SapphireTopShowPredicate : SapphirePredicate {
}
@end