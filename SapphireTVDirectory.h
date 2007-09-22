//
//  SapphireTVDirectory.h
//  Sapphire
//
//  Created by Graham Booker on 9/5/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMetaData.h"

@interface SapphireTVBaseDirectory : SapphireDirectoryMetaData {
	NSMutableDictionary		*directory;
	NSTimer					*reloadTimer;
}
- (void)processFile:(SapphireFileMetaData *)file;
- (void)removeFile:(SapphireFileMetaData *)file;
@end

@interface SapphireTVDirectory : SapphireTVBaseDirectory {
}
@end

@interface SapphireShowDirectory : SapphireTVBaseDirectory {
}
@end

@interface SapphireSeasonDirectory : SapphireTVBaseDirectory {
}
@end