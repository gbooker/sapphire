//
//  SapphireTVShowDataMenu.h
//  Sapphire
//
//  Created by Graham Booker on 6/30/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireImporterDataMenu.h"
#include <regex.h>

/*!
 * @brief The importer of TV data
 *
 * This class is a subclass of SapphireMultipleImporter for importing TV data.  It will search tvrage in an attempt to identify the tv show.  Then it will present the user with the results it found and ask them to make a choice.  Once the tv show is identified, it will then import data from tvrage.  In addition, it will download screenshots to display for cover art.
 */
@interface SapphireTVShowImporter : NSObject <SapphireImporter>{
	SapphireImporterDataMenu	*dataMenu;				/*!< @brief The UI for the import*/
	SapphireFileMetaData		*currentData;			/*!< @brief The metadata currently being imported(not retained)*/
	NSMutableDictionary			*showTranslations;		/*!< @brief The translation dictionary from filename prefix to tvshow*/
	NSMutableDictionary			*showInfo;				/*!< @brief The info about a TV show kept during import so that it doesn't need feteching every time*/
	NSString					*settingsPath;			/*!< @brief The persistent store of translations*/
	regex_t						letterMarking;			/*!< @brief Regex for matching S##E##*/
	regex_t						seasonByEpisode;		/*!< @brief Regex for matching #x##*/
	regex_t						seasonEpisodeTriple;	/*!< @brief Regex for matching ###*/
}

/*!
 * @brief Create a TV importer with persistent store
 *
 * This creates a TV importer.  It provides it with a path to save the user's selection so that he isn't required to keep entering the same selection if the show is imported again
 *
 * @param path The path to the persistent store
 * @return The TV importer
 */
- (id) initWithSavedSetting:(NSString *)path;

@end
