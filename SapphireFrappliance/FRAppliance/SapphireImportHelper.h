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

#import "SapphireImporterDataMenu.h"

@protocol SapphireImporterBackgroundProtocol;
@class SapphireImporterDataMenu, SapphireAllImporter, SapphireFileMetaData;

/*!
 * @brief The protocol for a file import data
 *
 * This object is a protocol of data to import.  It has the metadata as well as what kind of import to od.  Finally, it has an object to inform when the import is complete.
 */
@protocol SapphireImportFileProtocol <NSObject>
/*!
 * @brief Get the file to import
 *
 * @return The path to file to import
 */
- (bycopy NSString *)path;

/*!
 * @brief Get the informer
 *
 * The informer is the object which should be informed once import is complete.  This is used for UI or scheduling the next file to import.  Called by the server, not the client.
 *
 * @return The informer
 */
- (id <SapphireImporterBackgroundProtocol>)informer;

/*!
 * @brief The file container type
 */
- (enum FileContainerType)fileContainerType;
@end

/*!
 * @brief The import client protocol
 *
 * This is the protocol for the client.  It is the interface for the server to use for its child
 */
@protocol SapphireImportClient <NSObject>
/*!
 * @brief Start the queue on the client
 */
- (oneway void)startQueue;

/*!
 * @brief Tell the child it may quit
 */
- (oneway void)exitChild;
@end

/*!
 * @brief The import server protocol
 *
 * This is the protocol for the server.  It is the interface for the client to use for its server
 */
@protocol SapphireImportServer <NSObject>
/*!
 * @brief Get the next import data
 *
 * @return The next import data
 */
- (id <SapphireImportFileProtocol>)nextFile;

/*!
 * @brief Sets the client for the server
 *
 * This is called by the client once it is ready to process data.
 *
 * @param aClient The client
 */
- (oneway void)setClient:(id <SapphireImportClient>)aClient;

/*!
 * @brief The client has finished importing
 *
 * @param changes The dictionary of changes
 * @param update YES if data was imported, NO otherwise
 */
- (void)importCompleteWithChanges:(bycopy NSDictionary *)changes updated:(BOOL)updated;

/*!
 * @brief The client has finished importing file metadata
 *
 * @param fileMeta The dictionary of file metadata
 * @param path The path which was imported
 */
- (void)fileImportCompleteWithMeta:(bycopy NSDictionary *)fileMeta path:(NSString *)path;
@end

/*!
 * @brief The generic import helper (used by both the server and client)
 *
 * Since the client uses the same code as the server, some import operations may go through this class.  In such a case, instead of queueing up the data for a client (itself), it is processed immediately.
 */
@interface SapphireImportHelper : NSObject{
}
/*!
 * @brief Get the shared object
 *
 * @param context The managed object context
 * @return The shared object
 */
+ (SapphireImportHelper *)sharedHelperForContext:(NSManagedObjectContext *)moc;

/*!
 * @brief Release the shared object
 *
 * When called on the server (should never be called on the client), it will both release the helper object, and exit the client
 */
+ (void)relinquishHelper;

/*!
 * @brief Release the shared object
 *
 * When called on the server (should never be called on the client), it will both release the helper object, and exit the client
 */
- (void)relinquishHelper;

/*!
 * @brief Import file data
 *
 * @param file The file to import
 * @param inform The informer to inform of completion
 * @return YES if the import is not backgrounded, NO otherwise
 */
- (BOOL)importFileData:(SapphireFileMetaData *)file inform:(id <SapphireImporterBackgroundProtocol>)inform;

/*!
 * @brief Import all data
 *
 * @param file The file to import
 * @param inform The informer to inform of completion
 */
- (void)importAllData:(SapphireFileMetaData *)file inform:(id <SapphireImporterBackgroundProtocol>)inform;

/*!
 * @brief Remove all objects in the queue with a certain informer
 *
 * @param inform The informer's queued items to remove
 */
- (void)removeObjectsWithInform:(id <SapphireImporterBackgroundProtocol>)inform;

@end

/*!
 * @brief The importer client object
 */
@interface SapphireImportHelperClient : SapphireImportHelper <SapphireImportClient> {
	id <SapphireImportServer>	server;			/*!< @brief The server*/
	BOOL						keepRunning;	/*!< @brief Keep running (for terminating run loop)*/
}

/*!
 * @brief Creates a new importer client
 *
 * @param context The managed object context
 * @return The new importer client
 */
- (id)init;

/*!
 * @brief Start the child's processing
 */
- (void)startChild;

/*!
 * @brief Should keep running?
 *
 * @return YES if runloop should keep running, NO otherwise
 */
- (BOOL)keepRunning;
@end

/*!
 * @brief The importer server object
 */
@interface SapphireImportHelperServer : SapphireImportHelper <SapphireImportServer, SapphireImporterDelegate> {
	NSConnection						*serverConnection;	/*!< @brief The server's listener connection*/
	id <SapphireImportClient>			client;				/*!< @brief The client*/
	NSManagedObjectContext				*moc;				/*!< @brief The object context*/
	NSMutableArray						*queue;				/*!< @brief The processing queue*/
	BOOL								queueSuspended;		/*!< @brief YES if the child exists, but nothing is in the queue, NO otherwise*/
	id <SapphireImportFileProtocol>		currentImporting;	/*!< @brief The file the child is currently processing*/
	SapphireAllImporter					*allImporter;		/*!< @brief An allimporter object for importing all data*/
	NSMutableDictionary					*informers;			/*!< @brief The informer of completion of import keyed by path*/
}

/*!
 * @brief Creates a new importer server
 *
 * @param context The managed object context
 * @return The new importer server
 */
- (id)initWithContext:(NSManagedObjectContext *)context;

@end