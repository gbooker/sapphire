//
//  SapphireFileDataImporter.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireImporterDataMenu.h"
@class SapphireFileMetaData;

/*!
 * @brief The importer of file data
 *
 * This class is a subclass of SapphireMultipleImporter for importing file data.  It will read in data from the file, such as size, length, and codecs.  In addition, it will also read any data stored in XML files with the file.
 */
@interface SapphireFileDataImporter : NSObject <SapphireImporter>
{
	int  xmlFileCount;		/*!< @brief The number of xml files which were imported*/
}
@end 
