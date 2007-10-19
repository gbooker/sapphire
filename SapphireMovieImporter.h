//
//  SapphireMovieImporter.h
//  Sapphire
//
//  Created by Patrick Merrill on 9/10/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//
#import "SapphirePosterChooser.h"
#import "SapphireImporterDataMenu.h"
#include <regex.h>

@interface SapphireMovieImporter : NSObject <SapphireImporter>{
	SapphireImporterDataMenu	*dataMenu;
//	SapphirePosterChooser		*previousChooser;
	//Note: currentData is not retained
	SapphireFileMetaData		*currentData;
	NSMutableDictionary			*movieTranslations;
	NSMutableDictionary			*movieInfo;
	NSString					*settingsPath;
}

- (id) initWithSavedSetting:(NSString *)path;

@end