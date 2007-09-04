//
//  SapphirePredicates.h
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@class SapphireFileMetaData;

@interface SapphirePredicate : NSObject {
}

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData;

@end

@interface SapphireUnwatchedPredicate : SapphirePredicate {
}
@end

@interface SapphireFavoritePredicate : SapphirePredicate {
}
@end

@interface SapphireTopShowPredicate : SapphirePredicate {
}
@end