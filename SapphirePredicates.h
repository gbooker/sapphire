//
//  SapphirePredicates.h
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SapphireFileMetaData;

@interface SapphirePredicate : NSObject {
}

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData;

@end

@interface SapphireUnwatchedPredicate : SapphirePredicate {
}
@end
