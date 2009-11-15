/*
 * SapphireCustomVirtualDirectory.h
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
 * @brief The simple object to hold movie virtual directory data
 *
 * This class is a value object for holding imported xml movie virtual directory data.
 */
@interface SapphireCustomVirtualDirectory : NSObject {
	NSString *title;
	NSString *description;
	NSPredicate *predicate;
}
- (NSString *)title;
- (NSString *)description;
- (NSPredicate *)predicate;
- (void)setTitle:(NSString*)v;
- (void)setDescription:(NSString*)v;
- (void)setPredicate:(NSPredicate*)v;
@end

