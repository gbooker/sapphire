//
//  SapphirePosterChooser.h
//  Sapphire
//
//  Created by Patrick Merrill on 10/11/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#define POSTER_CHOOSE_CANCEL		-1


@interface SapphirePosterChooser : BRCenteredMenuController {
	NSArray			*posters;
	NSString		*fileName ;
	NSString		*movieTitle;
	int				selection;
	BRTextControl	*fileNameText;
}
- (void)setPosters:(NSArray *)posterList;
- (void)setFileName:(NSString *)choosingForFileName;
- (NSArray *)posters;
- (void)setMovieTitle:(NSString *)theMovieTitle;
- (NSString *)movieTitle;
- (int)selection;

@end
