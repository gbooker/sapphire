/*
 * SLoadInstallerProtocol.h
 * Software Loader
 *
 * Created by Graham Booker on Dec. 30 2007.
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

#define INSTALLER_NAME_KEY @"SLoadInstallerName"

#define INSTALL_URL_KEY				@"link"				/*Download URL*/
#define INSTALL_MD5_KEY				@"md5"				/*Md5 of the download*/
#define INSTALL_NAME_KEY			@"installname"		/*Filename of extracted file*/
#define INSTALL_DISPLAY_NAME_KEY	@"title"			/*Display title*/
#define INSTALL_VERSION_KEY			@"version"			/*Version*/
#define INSTALL_INSTALLER_KEY		@"installer"		/*Installers to use*/
#define INSTALL_BUNDLE_PATH			@"bundlePath"		/*Bundle path to check version*/
#define INSTALL_SOFTWARE_TYPE		@"type"				/*Software type*/

/*Softawre types*/
#define INSTALL_TYPE_INSTALLER		@"installer"		/*An installer*/
#define INSTALL_TYPE_SOFTWARE		@"software"			/*Installed Software*/

@protocol SLoadDelegateProtocol;

@protocol SLoadInstallerProtocol <NSObject>
- (void)setDelegate:(id <SLoadDelegateProtocol>)aDelegate;
- (void)cancel;
- (void)install:(NSDictionary *)software;
@end