//
//  SapphireTVDirectory.h
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireVirtualDirectory.h"

@interface SapphireTVDirectory : SapphireVirtualDirectory {
}
- (id)initWithCollection:(SapphireMetaDataCollection *)myCollection;
@end

@interface SapphireShowDirectory : SapphireVirtualDirectory {
}
@end

@interface SapphireSeasonDirectory : SapphireVirtualDirectory {
}
@end