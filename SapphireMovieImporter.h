//
//  SapphireMovieImporter.h
//  Sapphire
//
//  Created by Patrick Merrill on 9/10/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//
#import "SapphireImporterDataMenu.h"

@class SapphirePosterChooser;

@interface SapphireMovieImporter : NSObject <SapphireImporter>{
	SapphireImporterDataMenu	*dataMenu;
	//Note: currentData is not retained
	SapphireFileMetaData		*currentData;
	NSMutableDictionary			*movieTranslations;
	NSMutableDictionary			*movieInfo;
	NSString					*settingsPath;
	//Note: posterChooser is not retained
	SapphirePosterChooser		*posterChooser;
}

- (id) initWithSavedSetting:(NSString *)path;

@end