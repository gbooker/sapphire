//
//  SapphireMediaPreview.h
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

@class SapphireMetaData, SapphireDirectoryMetaData;

/*!
 * @brief A subclass of BRMetadataPreviewController for our own preview
 *
 * This class provides a means by which our custom metadata can be displayed.  From the metadata and its containing metadata, all the information can be gathered to construct the preview.
 *
 * The directory may not always be the parent of the metadata. In the case of virtual directories, the parent is a virtual directory while the metadata is the actual file located elsewhere.
 */
@interface SapphireMediaPreview : BRMetadataPreviewController{
	SapphireMetaData			*meta;			/*!< @brief The metadata to display in the preview*/
	SapphireDirectoryMetaData	*dirMeta;		/*!< @brief The directory containing the metadata*/
}

/*!
 * @brief Set the File information
 *
 * Set the metadata information for the preview.  This provides the necessary information for the preview to display all the information about the file
 *
 * @param newMeta The metadata for the file or directory
 * @param dir The directory which contains this metadata
 */
- (void)setMetaData:(SapphireMetaData *)newMeta inMetaData:(SapphireDirectoryMetaData *)dir;

@end
