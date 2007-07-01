//
//  SapphireShowChooser.h
//  Sapphire
//
//  Created by Graham Booker on 7/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BRCenteredMenuController.h>

#define SHOW_CHOOSE_CANCEL -2
#define SHOW_CHOOSE_NOT_SHOW -1

@interface SapphireShowChooser : BRCenteredMenuController {
	NSArray			*shows;
	NSString		*searchStr;
	int				selection;
}

- (void)setShows:(NSArray *)showList;
- (NSArray *)shows;
- (void)setSearchStr:(NSString *)search;
- (NSString *)searchStr;
- (int)selection;

@end
