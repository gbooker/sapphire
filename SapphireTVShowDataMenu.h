//
//  SapphireTVShowDataMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireImporterDataMenu.h"
#include <regex.h>

@interface SapphireTVShowDataMenu : SapphireImporterDataMenu {
	NSMutableDictionary		*showTranslations;
	NSMutableDictionary		*showInfo;
	regex_t					letterMarking;
	regex_t					seasonByEpisode;	
}

@end
