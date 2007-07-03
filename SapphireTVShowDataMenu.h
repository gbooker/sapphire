//
//  SapphireTVShowDataMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireImporterDataMenu.h"
#include <regex.h>

@interface SapphireTVShowDataMenu : SapphireImporterDataMenu {
	NSMutableDictionary		*showTranslations;
	NSMutableDictionary		*showInfo;
	NSString				*settingsPath;
	regex_t					letterMarking;
	regex_t					seasonByEpisode;
	regex_t					seasonEpisodeTriple;
}

- (id) initWithScene: (BRRenderScene *) scene metaData:(SapphireDirectoryMetaData *)metaData savedSetting:(NSString *)path;

@end
