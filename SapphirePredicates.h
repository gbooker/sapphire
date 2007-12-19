/*
 * SapphirePredicates.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 23, 2007.
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