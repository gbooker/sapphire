//
//  SapphireMovieDirectory.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"

@interface SapphireMovieDirectory : SapphireVirtualDirectoryOfDirectories {
	NSArray *keyOrder;
}
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

@interface SapphireMovieCastDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

@interface SapphireMovieDirectorDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end

@interface SapphireMovieGenreDirectory : SapphireVirtualDirectoryOfDirectories {
}
@end


@interface SapphireMovieCategoryDirectory : SapphireVirtualDirectory {
}
@end

@interface SapphireMovieOscarDirectory : SapphireMovieCategoryDirectory{
}
@end

@interface SapphireMovieTop250Directory : SapphireMovieCategoryDirectory{
}
@end
