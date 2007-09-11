//
//  SapphireShowChooser.h
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#define SHOW_CHOOSE_CANCEL -2
#define SHOW_CHOOSE_NOT_SHOW -1

@interface SapphireShowChooser : BRCenteredMenuController {
	NSArray			*shows;
	NSString		*searchStr;
	int				selection;
	BRTextControl	*fileName;
}

- (void)setShows:(NSArray *)showList;
- (void)setFileName:(NSString *)choosingForFileName;
- (NSArray *)shows;
- (void)setSearchStr:(NSString *)search;
- (NSString *)searchStr;
- (int)selection;

@end
