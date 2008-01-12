/*
 * SapphireMultipleImporter.h
 * Sapphire
 *
 * Created by Graham Booker on Aug. 29, 2007.
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

/*!
 * @brief An importer that contains multiple importers
 *
 * This class implements SapphireImporter to provide a proxy to multiple importers.  This is the mechanism by which the "Import All Data" works.
 */
@interface SapphireMultipleImporter : NSObject <SapphireImporter>{
	NSArray		*importers;		/*!< @brief The list of importers to use, in order*/
	int			importIndex;	/*!< @brief The index of the next importer to run*/
	ImportState	resumedState;	/*!< @brief The state to use when we finally resume */
}

/*!
 * @brief Creates a new importer set
 *
 * @param importerList The list of importers to use
 * @return The importer if successful, nil otherwise
 */
- (id)initWithImporters:(NSArray *)importerList;

@end
