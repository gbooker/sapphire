/*
 * NSManagedObject-Extensions.h
 * Sapphire
 *
 * Created by Graham Booker on Oct. 7, 2007.
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
 * @brief Managed Object extensions
 *
 * This class provides additional methods for managed objects
 */
@interface NSManagedObject(Extensions)

/*!
 * @brief Turn an ojbect into a fault.  This will not fault an object with unsaved changes.
 *
 * @param moc The managed Object Context in which this object resides
 */
- (void)faultOjbectInContext:(NSManagedObjectContext *)moc;

/*!
 * @brief Checks to see if an object is deleted
 *
 * The isDeleted in CoreData only returns YES between when the delete called, and when the context is saved.
 * After the save, it returns NO, so this does a check to see if the object is registered with the context
 * to see if it is really there or has already been deleted.
 *
 * @return YES if it has been deleted, NO otherwise
 */
- (BOOL)objectHasBeenDeleted;
@end
