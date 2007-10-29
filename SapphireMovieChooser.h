//
//  SapphireMovieChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 7/27/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireCenteredMenuController.h"

#define MOVIE_CHOOSE_CANCEL		-4
#define MOVIE_CHOOSE_TV_SHOW	-3
#define MOVIE_CHOOSE_OTHER		-2
#define MOVIE_CHOOSE_NOT_MOVIE	-1

@interface SapphireMovieChooser : SapphireCenteredMenuController {
	NSArray			*movies;
	NSString		*fileName;
	int				selection;
	BRTextControl	*fileNameText;
}

- (void)setMovies:(NSArray *)movieList;
- (void)setFileName:(NSString *)choosingForFileName;
- (NSArray *)movies;
- (NSString *)fileName;
- (int)selection;

@end
