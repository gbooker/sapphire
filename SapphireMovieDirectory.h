//
//  SapphireMovieDirectory.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"

@class SapphireMovieCategoryDirectory, SapphireMovieActorDirectory, SapphireMovieDirectorDirectory, SapphireMovieGenreDirectory;

@interface SapphireMovieDirectory : SapphireVirtualDirectoryOfDirectories {
	SapphireMovieCategoryDirectory	*allMovies;
	SapphireMovieActorDirectory		*actors;
	SapphireMovieDirectorDirectory	*directors;
	SapphireMovieGenreDirectory		*genres;
}
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

@interface SapphireMovieActorDirectory : SapphireVirtualDirectoryOfDirectories {
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
