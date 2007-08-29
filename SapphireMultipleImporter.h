//
//  SapphireMultipleImporter.h
//  Sapphire
//
//  Created by Graham Booker on 8/29/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireImporterDataMenu.h"

@interface SapphireMultipleImporter : NSObject <SapphireImporter>{
	NSArray		*importers;
}

- (id)initWithImporters:(NSArray *)importerList;

@end
