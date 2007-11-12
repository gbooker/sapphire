//
//  SapphireMovieDirectory.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/22/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMetaData.h"

@interface SapphireMovieBaseDirectory : SapphireDirectoryMetaData {
	NSMutableDictionary		*directory;
	NSTimer					*reloadTimer;
}
- (void)processFile:(SapphireFileMetaData *)file;
- (void)removeFile:(SapphireFileMetaData *)file;
@end

@interface SapphireMovieDirectory : SapphireMovieBaseDirectory {
}
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

@interface SapphireMovieGenreDirectory : SapphireMovieBaseDirectory {
}
@end

@interface SapphireMovieCategoryDirectory : SapphireMovieBaseDirectory {
}
@end
