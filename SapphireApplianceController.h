//
//  SapphireApplianceController.h
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"

@class SapphireMetaDataCollection, SapphireSettings, SapphireTheme, SapphirePredicate;
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
@end
