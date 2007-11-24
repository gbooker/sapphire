//
//  SapphireVirtualDirectory.h
//  Sapphire
//
//  Created by Graham Booker on 11/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMetaData.h"

@interface SapphireVirtualDirectory : SapphireDirectoryMetaData {
	NSMutableDictionary		*directory;
	NSTimer					*reloadTimer;
}
- (id)initWithParent:(SapphireVirtualDirectory *)myParent path:(NSString *)myPath;
- (void)setReloadTimer;
- (void)processFile:(SapphireFileMetaData *)file;
- (void)removeFile:(SapphireFileMetaData *)file;
- (void)childDisplayChanged;
- (void)writeToFile:(NSString *)filePath;
- (BOOL)isDisplayEmpty;
- (BOOL)isEmpty;
@end

@interface SapphireVirtualDirectoryOfDirectories : SapphireVirtualDirectory {
}
- (BOOL)addFile:(SapphireFileMetaData *)file toKey:(NSString *)key withChildClass:(Class)childClass;
- (BOOL)removeFile:(SapphireFileMetaData *)file fromKey:(NSString *)key;
@end