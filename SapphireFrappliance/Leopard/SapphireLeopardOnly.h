/*
 * SapphireLeopardOnly.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 19, 2007.
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

#import <Cocoa/Cocoa.h>

@class SapphireLeopardFileEvents, SapphireMetaDataCollection;

/*!
 * @brief Leopard only code
 *
 * Leopard has a few APIs which don't exist on the AppleTV.  Such code goes here.
 */
@interface SapphireLeopardOnly : NSObject {
	SapphireLeopardFileEvents		*fileEvents;	/*!< @brief The file event watcher*/
}
/*!
 * @brief Initialize the leopard only APIs
 *
 * @param context The main context
 */
- (id)initWithContext:(NSManagedObjectContext *)context;

@end
