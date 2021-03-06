/*
 * SapphireAppliance.h
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

/*!
 * @brief The ATV 2 protocol
 *
 * This protocol defines the new methods in ATV 2.
 */
@protocol BRAppliance <NSObject>
- (id)applianceInfo;
- (id)applianceCategories;
- (id)identifierForContentAlias:(id)fp8;
- (id)controllerForIdentifier:(id)fp8;
@end

/*!
 * @brief The Main class
 *
 * This class bypasses the whitelist check and sets up backrow to load and use the main controller.
 */
@interface SapphireAppliance : NSObject <BRAppliance, BRApplianceProtocol> {
	BOOL		upgradeNeeded;		/*!< @brief YES if upgrade is needed*/
}
@end

