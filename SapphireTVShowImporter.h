/*
 * SapphireTVShowDataMenu.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 30, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
