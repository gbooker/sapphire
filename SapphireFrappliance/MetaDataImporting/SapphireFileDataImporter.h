/*
 * SapphireFileDataImporter.h
 * Sapphire
 *
 * Created by pnmerrill on Jun. 24, 2007.
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
@class SapphireFileMetaData;

/*!
 * @brief The importer of file data
 *
 * This class is a subclass of SapphireMultipleImporter for importing file data.  It will read in data from the file, such as size, length, and codecs.
 */
@interface SapphireFileDataImporter : NSObject <SapphireImporter, SapphireImporterBackgroundProtocol>
{
	id <SapphireImporterDelegate>	delegate;		/*!< @brief The delegate for the import (not retained)*/
}
@end 
