/*
 * SapphireTVShowImporter.h
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

@class SapphireShowChooser;

/*!
 * @brief The importer of TV data
 *
 * This class is a subclass of SapphireMultipleImporter for importing TV data.  It will search tvrage in an attempt to identify the tv show.  Then it will present the user with the results it found and ask them to make a choice.  Once the tv show is identified, it will then import data from tvrage.  In addition, it will download screenshots to display for cover art.
 */
@interface SapphireTVShowImporter : NSObject <SapphireImporter>{
	id <SapphireImporterDelegate>	delegate;				/*!< @brief The delegate for the import (not retained)*/
	NSMutableDictionary				*showInfo;				/*!< @brief The info about a TV show kept during import so that it doesn't need feteching every time*/
	NSTimer							*showInfoClearTimer;	/*!< @brief Timer to clear the show info cache*/
	regex_t							letterMarking;			/*!< @brief Regex for matching S##E##*/
	regex_t							seasonByEpisode;		/*!< @brief Regex for matching #x##*/
	regex_t							seasonEpisodeTriple;	/*!< @brief Regex for matching ###*/
}
@end
