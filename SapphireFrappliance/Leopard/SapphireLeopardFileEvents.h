/*
 * SapphireLeopardFileEvents.h
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

@class SapphireMetaDataCollection;

/*!
 * @brief Leopard only file event responding
 *
 * Leopard has an API to register for file change events within certain paths.  While it is possible to do the same thing in Tiger (AppleTV), this requires a completly different method, involving kernel APIs.
 */
@interface SapphireLeopardFileEvents : NSObject {
	NSManagedObjectContext			*moc;			/*!< @brief The context*/
	FSEventStreamRef				stream;			/*!< @brief The file event stream*/
}
/*!
 * @brief Create a new file event watcher for a given collection
 *
 * @param context The main context
 */
- (id)initWithContext:(NSManagedObjectContext *)context;
@end
