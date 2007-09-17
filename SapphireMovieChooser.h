//
//  SapphireMovieChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#define MOVIE_CHOOSE_CANCEL		-4
#define MOVIE_CHOOSE_TV_SHOW	-3
#define MOVIE_CHOOSE_OTHER		-2
#define MOVIE_CHOOSE_NOT_MOVIE	-1

@interface SapphireMovieChooser : BRCenteredMenuController {
	NSArray			*movies;
	NSString		*searchStr;
	int				selection;
	BRTextControl	*fileName;
}

- (void)setMovies:(NSArray *)movieList;
- (void)setFileName:(NSString *)choosingForFileName;
- (NSArray *)movies;
- (void)setSearchStr:(NSString *)search;
- (NSString *)searchStr;
- (int)selection;

@end
