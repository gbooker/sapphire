/*
 * SapphireVirtualDirectory.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 18, 2007.
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

#import "SapphireMetaData.h"

/*!
 * @brief The base Virtual directory
 *
 * This class is designed to be a virtual directory without any basis in reality.  It contains all the shared code for subclasses to store their information.
 */
@interface SapphireVirtualDirectory : SapphireDirectoryMetaData {
	NSMutableDictionary		*directory;		/*!< @brief The directory of files since there isn't a real directory*/
	NSTimer					*reloadTimer;	/*!< @brief A timer to reload the visual contents (not retained)*/
	BOOL					loading;		/*!< @brief TRUE if the directory is still loading*/
}

/*!
 * @brief Creates a new virtual directory object
 *
 * This creates a new virtual directory metadata object.  It is similar to its superclass, but has no persistent store.
 *
 * @param myParent The parent metadata
 * @param myPath The path for this metadata
 * @return The metadata object
 */
- (id)initWithParent:(SapphireVirtualDirectory *)myParent path:(NSString *)myPath;

/*!
 * @brief Sets a timer to reload
 *
 * The timer is set to reload the contents so that updates can be consolidated.
 */
- (void)setReloadTimer;

/*!
 * @brief Process a file to add to the virtual directory
 *
 * @param file The file to add
 */
- (void)processFile:(SapphireFileMetaData *)file;

/*!
 * @brief Process a file to remove from the virtual directory
 *
 * @param file The file to remove
 */
- (void)removeFile:(SapphireFileMetaData *)file;

/*!
 * @brief The default cover art path for directories in this class
 *
 * @return The cover art path for this class
 */
- (NSString *)classDefaultCoverPath;

/*!
 * @brief A child of this directory had its contents change
 *
 * This is a trigger for the current object to do an update.  Since the child's display has changed, this object may need to change its display to match
 */
- (void)childDisplayChanged;

/*!
 * @brief Write directory structure to a file
 *
 * This is for debug purposes.  It writes the entire directory structure to a file to test its opperation
 */
- (void)writeToFile:(NSString *)filePath;

/*!
 * @brief Determines if the display is empty
 *
 * @return YES if the display is empty, NO if it contians at least one object
 */
- (BOOL)isDisplayEmpty;

/*!
 * @brief Determines if the directory is empty
 *
 * @return YES if the directory is empty, NO if it contians at least one object
 */
- (BOOL)isEmpty;

/*!
 * @brief Determines if the directory is loaded
 *
 * @return YES if the directory is fully loadded, NO otherwise
 */
- (BOOL)isLoaded;
@end

/*!
 * @brief A virtual directory containing other virtual directories
 *
 * This is a subclass of SapphireVirtualDirectory which contains abstract methods to make its subclasses easier.  It provides methods for adding a file to its directory and creating the child object if necessary.
 */
@interface SapphireVirtualDirectoryOfDirectories : SapphireVirtualDirectory {
}
/*!
 * @brief Add a file to the subdirectories
 *
 * This method exists to make directories of directories easier.  If a file is added with a certain key, this method does everything that is needed.
 *
 * For example with TV shows.  The SapphireTVDirectory needs to add Dexter 2x12.  It calls this method with the file metadata, the key of "Dexter" and a class of SapphireShowDirectory.  It will lookup the directory with the key "Dexter" and if nothing exists there yet, it will create a new SapphireShowDirectory and place it in the directory.  Then it will call the SapphireShowDirectory object's processFile.  If a new directory was created, and it is still empty after that call, it is then removed.  Lastly, the reload time is called.
 *
 * @param file The file to add
 * @param key The key of the subdirectory which is to contain the file
 * @param childClass The class of the child directory
 * @return YES if the file was added, NO otherwise
 */
- (BOOL)addFile:(SapphireFileMetaData *)file toKey:(NSString *)key withChildClass:(Class)childClass;

/*!
 * @brief Remove a file from the subdirectories
 *
 * This method exists to make directories of directories easier.  If a removed from a certain directory, this does all that is needed.  It will have the subdirectory remove the file, and then if the subdirectory is empty, remove the subdirectory itself.  
 *
 * @param file The file to remove
 * @param key The key of the subdirectory which contains the file
 * @return YES if the subdirectory was removed, NO otherwise
 */
- (BOOL)removeFile:(SapphireFileMetaData *)file fromKey:(NSString *)key;
@end