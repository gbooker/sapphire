//
//  SapphireTVDirectory.h
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"

/*!
 * @brief The base TV shows virtual directory
 *
 * This class stores the main TV shows directory.  There are several SapphireShowDirectory objects within this directory.
 */
@interface SapphireTVDirectory : SapphireVirtualDirectoryOfDirectories {
}
/*!
 * @brief create the top virtual directory
 *
 * @param myCollection The main collection so that a write works
 */
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

/*!
 * @brief The TV show virtual directory
 *
 * This class stores a TV show's directory.  There are several SapphireSeasonDirectory objects within this directory.
 */
@interface SapphireShowDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

/*!
 * @brief The virtual directory of episodes
 *
 * This class stores a list of episodes.  It will add every episode it is told to add without any filters.
 */
@interface SapphireSeasonDirectory : SapphireVirtualDirectory {
}
@end