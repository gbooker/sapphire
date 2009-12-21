/*
 * SapphireMediaPreview.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 26, 2007.
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

//Special Display Only Info (MediaPreview)
extern NSString *META_EPISODE_AND_SEASON_KEY;
extern NSString *META_MOVIE_IMDB_STATS_KEY;
extern NSString *AUDIO_DESC_LABEL_KEY;
extern NSString *VIDEO_DESC_LABEL_KEY;
extern NSString *AUDIO2_DESC_LABEL_KEY;
extern NSString *VIDEO2_DESC_LABEL_KEY;
extern NSString *SUBTITLE_LABEL_KEY;

@class SapphireMetaData, SapphireDirectoryMetaData;
@protocol SapphireMetaDataProtocol, SapphireDirectory;


/*!
 * @brief A subclass of BRMetadataPreviewController for our own preview
 *
 * This class provides a means by which our custom metadata can be displayed.  From the metadata and its containing metadata, all the information can be gathered to construct the preview.
 *
 * The directory may not always be the parent of the metadata. In the case of virtual directories, the parent is a virtual directory while the metadata is the actual file located elsewhere.
 */
@interface SapphireMediaPreview : BRMetadataPreviewController{
	int		padding[32];	/*!< @brief The classes are of different sizes.  This padding prevents a class compiled with one size to overlap when used with a class of a different size*/	
	id <SapphireMetaDataProtocol>	meta;			/*!< @brief The metadata to display in the preview*/
	id <SapphireDirectory>			dirMeta;		/*!< @brief The directory containing the metadata*/
	BOOL							imageOnly;		/*!< @brief Sets preview to only display the image (like in poster choosers)*/
}

/*!
 * @brief Set the File information
 *
 * Set the metadata information for the preview.  This provides the necessary information for the preview to display all the information about the file
 *
 * @param newMeta The metadata for the file or directory
 * @param dir The directory which contains this metadata
 */
- (void)setMetaData:(id <SapphireMetaDataProtocol>)newMeta inMetaData:(id <SapphireDirectory>)dir;
- (void)setUtilityData:(NSMutableDictionary *)newMeta;
- (void)setImageOnly:(BOOL)imageOnly;

@end
