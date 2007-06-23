//
//  SapphirePredicates.h
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SapphireFileMetaData;
typedef BOOL (*metaDataPredicate)(NSString *path, SapphireFileMetaData *metaData);

@interface SapphirePredicates : NSObject {
}

@end

BOOL unwatchedPredicate(NSString *path, SapphireFileMetaData *metaData);