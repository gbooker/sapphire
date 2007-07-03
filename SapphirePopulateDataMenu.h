//
//  SapphirePopulateDataMenu.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireImporterDataMenu.h"
@class SapphireFileMetaData;

@interface SapphirePopulateDataMenu : SapphireImporterDataMenu
{
	int  xmlFileCount ;
	BOOL xmlPathIsDir ;
}
- (void)importXMLFile:(NSString *)xmlFileName forMeta: (SapphireFileMetaData *) fileMeta ;
@end 
