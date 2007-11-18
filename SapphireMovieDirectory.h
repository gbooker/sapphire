//
//  SapphireMovieDirectory.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"

@interface SapphireMovieDirectory : SapphireVirtualDirectory {
}
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

@interface SapphireMovieGenreDirectory : SapphireVirtualDirectory {
}
@end

@interface SapphireMovieCategoryDirectory : SapphireVirtualDirectory {
}
@end
