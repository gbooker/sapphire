//
//  SapphireMovieImporter.h
//  Sapphire
//
//  Created by Patrick Merrill on 9/10/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//
#import "SapphireImporterDataMenu.h"

@class SapphirePosterChooser;

/*!
 * @brief The importer of movie data
 *
 * This class is a subclass of SapphireMultipleImporter for importing movie data.  It will search IMDB in an attempt to identify the movie.  Then it will present the user with the results it found and ask them to make a choice.  Once the movie is identified, it will then import data from IMDB.  In addition, it will download posters from impawards and ask the user to select a poster to display for cover art.
 */
@interface SapphireMovieImporter : NSObject <SapphireImporter>{
	SapphireImporterDataMenu	*dataMenu;				/*!< @brief The UI for the import*/
	SapphireFileMetaData		*currentData;			/*!< @brief The metadata currently being imported(not retained)*/
	NSMutableDictionary			*movieTranslations;		/*!< @brief The translation dictionary from filename to movie*/
	NSString					*settingsPath;			/*!< @brief The persistent store of translations*/
	SapphirePosterChooser		*posterChooser;			/*!< @brief The poster chooser (if exists) (not retained)*/
}

/*!
 * @brief Create a movie importer with persistent store
 *
 * This creates a movie importer.  It provides it with a path to save the user's selection so that he isn't required to keep entering the same selection if the movie is imported again
 *
 * @param path The path to the persistent store
 * @return The movie importer
 */
- (id) initWithSavedSetting:(NSString *)path;

@end