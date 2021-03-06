/*
 * SapphireCustomVirtualDirectoryImporter.h
 * Sapphire
 *
 * Created by mjacobsen on Oct. 2, 2009.
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

/*!
 * @brief The importer of movie virtual directory data
 *
 * This class is a for importing xml movie virtual directory data.  It will read in data stored in XML files for defining custom movie virtual directories.
 */
@interface SapphireCustomVirtualDirectoryImporter : NSObject {
	NSDictionary	*elementCommands;
	NSDictionary	*movieElementCommands;
	NSDictionary	*tvShowElementCommands;
	NSString		*path;
	NSArray			*movieVirtualDirectories;
	NSArray			*tvShowVirtualDirectories;
	int				lastReadTime;
}

- (NSArray *)movieVirtualDirectories;
- (NSArray *)tvShowVirtualDirectories;
@end
