/*
 * SapphireMovieImporter.h
 * Sapphire
 *
 * Created by Patrick Merrill on Sep. 10, 2007.
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
#import "SapphireSiteScraper.h"

@class SapphirePosterChooser;

/*!
 * @brief The importer of movie data
 *
 * This class is a subclass of SapphireMultipleImporter for importing movie data.  It will search IMDB in an attempt to identify the movie.  Then it will present the user with the results it found and ask them to make a choice.  Once the movie is identified, it will then import data from IMDB.  In addition, it will download posters from impawards and ask the user to select a poster to display for cover art.
 */
@interface SapphireMovieImporter : NSObject <SapphireImporter, SapphireSiteMovieScraperDelegate>{
	id <SapphireImporterDelegate>	delegate;				/*!< @brief The UI for the import (not retained)*/
	BOOL							cancelled;				/*!< @brief YES if the import has been cancelled, NO otherwise*/
	SapphireMovieScraper			*scraper;				/*!< @brief The scraper to use*/
}

@end