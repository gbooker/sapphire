//
//  SapphireMultipleImporter.h
//  Sapphire
//
//  Created by Graham Booker on 8/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireImporterDataMenu.h"

/*!
 * @brief An importer that contains multiple importers
 *
 * This class implements SapphireImporter to provide a proxy to multiple importers.  This is the mechanism by which the "Import All Data" works.
 */
@interface SapphireMultipleImporter : NSObject <SapphireImporter>{
	NSArray		*importers;		/*!< @brief The list of importers to use, in order*/
}

/*!
 * @brief Creates a new importer set
 *
 * @param importerList The list of importers to use
 * @return The importer if successful, nil otherwise
 */
- (id)initWithImporters:(NSArray *)importerList;

@end
