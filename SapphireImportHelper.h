/*
 * SapphireImportHelper.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 8, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

@protocol SapphireFileMetaDataProtocol, SapphireImporterBackgroundProtocol;
@class SapphireImporterDataMenu, SapphireAllImporter;

typedef enum {
	IMPORT_TYPE_FILE_DATA,
	IMPORT_TYPE_ALL_DATA,
}ImportType;

@protocol SapphireImportFileProtocol <NSObject>
- (id <SapphireFileMetaDataProtocol>)file;
- (id <SapphireImporterBackgroundProtocol>)informer;
- (ImportType)importType;
@end

@protocol SapphireImportClient <NSObject>
- (oneway void)startQueue;
@end

@protocol SapphireImportServer <NSObject>
- (id <SapphireImportFileProtocol>)nextFile;
- (oneway void)setClient:(id <SapphireImportClient>)aClient;
- (oneway void)importComplete:(BOOL)updated;
@end

@interface SapphireImportHelper : NSObject{
}
+ (SapphireImportHelper *)sharedHelper;
- (void)importFileData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
- (void)importAllData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
- (void)removeObjectsWithInform:(id <SapphireImporterBackgroundProtocol>)inform;

@end

@interface SapphireImportHelperClient : SapphireImportHelper <SapphireImportClient> {
	id <SapphireImportServer>	server;
	SapphireAllImporter			*allImporter;
}
- (void)startChild;
@end

@interface SapphireImportHelperServer : SapphireImportHelper <SapphireImportServer> {
	id <SapphireImportClient>			client;
	NSMutableArray						*queue;
	BOOL								queueSuspended;
	id <SapphireImportFileProtocol>		currentImporting;
}

@end