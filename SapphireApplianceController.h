/*
 * SapphireApplianceController.h
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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

#import "SapphireMediaMenuController.h"

@class SapphireMetaDataCollection, SapphireSettings, SapphireTheme, SapphirePredicate, SapphireLeopardOnly;
@protocol SapphireMetaDataDelegate;

/*!
 * @brief The Main Controller
 *
 * This class Is the main controller.  It uses SapphireMediaMenuController to create its main menu.
 */
@interface SapphireApplianceController : SapphireMediaMenuController
{
	SapphireMetaDataCollection	*metaCollection;		/*!< @brief The collection of metadata*/
	NSMutableArray				*names;					/*!< @brief The menu names, in order*/
	NSMutableArray				*controllers;			/*!< @brief The controllers to launch from menu, in order*/
	NSArray						*masterNames;			/*!< @brief The list of all names, including hidden*/
	NSArray						*masterControllers;		/*!< @brief The list of all controllers, including hidden*/
	SapphireSettings			*settings;				/*!< @brief The settings*/
	SapphireLeopardOnly			*leoOnly;				/*!< @brief Leopard only stuff*/
}

/*!
 * @brief Get the current predicate used
 *
 * @return The current predicate
 */
+ (SapphirePredicate *)predicate;

/*!
 * @brief Change to the next predicate
 *
 * @return The next predicate
 */
+ (SapphirePredicate *)nextPredicate;

/*!
 * @brief Get the left icon for a given predicate
 *
 * @return The left icon
 */
+ (BRTexture *)gemForPredicate:(SapphirePredicate *)predicate;

/*!
 * @brief Log an exception to the console
 *
 * This function attempts to log an exception to the console.  If the exception has a nice backtrace, it logs that along with the location of the Sapphire bundle in memory.  If it does not, it logs the entire backtrace is hex addresses along with the location of all memory objects in the trace.  The idea being that with this information, in either format, the developer can use atos to get exact line numbers.
 *
 * @param e The exception to log
 */
+ (void)logException:(NSException *)e;
@end
