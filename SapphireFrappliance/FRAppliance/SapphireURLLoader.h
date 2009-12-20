/*
 * SapphireURLLoader.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 10 2009.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

@interface SapphireURLLoader : NSObject {
	NSMutableDictionary	*workers;					/*!< @brief The list of workers, completed an not.  This is also the cache*/
	NSMutableArray		*workerQueue;				/*!< @brief The list of workers waiting to start*/
	int					workersCurrentlyWorking;	/*!< @brief The number of workers currently in progress*/
	NSInvocation		*myInformer;				/*!< @brief The invokation telling the loader when a worker is complete (queue management)*/
	NSTimer				*clearTimer;				/*!< @brief Timer indicating when the cache should be cleared*/
}

/*!
 * @brief Load a string at a URL
 *
 * Loads a string at a given URL, informing the target/selecter when it is done.
 * This attempts to discover the string encoding used by the source and produce a string in that encoding.
 *
 * @param url The URL to load (as an NSString)
 * @param target The target to call upon completion
 * @param selector The selector to call upon completion
 * @param anObject The context object to pass as the second parameter to the selector upon completion
 */
- (void)loadStringURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject;

/*!
 * @brief Load data at a URL
 *
 * Loads data at a given URL, informing the target/selecter when it is done.
 *
 * @param url The URL to load (as an NSString)
 * @param target The target to call upon completion
 * @param selector The selector to call upon completion
 * @param anObject The context object to pass as the second parameter to the selector upon completion
 */
- (void)loadDataURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject;

/*!
 * @brief Saves data at a given URL to a file
 *
 * @param url The URL to load (as an NSString)
 * @param path The path at which to save the data
 */
- (void)saveDataAtURL:(NSString *)url toFile:(NSString *)path;

@end
