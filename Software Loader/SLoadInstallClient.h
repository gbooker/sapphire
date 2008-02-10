/*
 * SLoadInstallClient.h
 * Software Loader
 *
 * Created by Graham Booker on Dec. 28 2007.
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

@class SLoadInstaller;
@protocol SLoadServer, SLoadDelegateProtocol;

@protocol SLoadClient <NSObject>
- (oneway void)setDelegate:(id <SLoadDelegateProtocol>)aDelegate;
- (oneway void)cancel;
- (oneway void)installSoftware:(NSDictionary *)software withInstaller:(NSString *)installer;
- (oneway void)installInstaller:(NSString *)installer;
- (NSArray *)installerList;
- (oneway void)exitClient;
@end

@interface SLoadInstallClient : NSObject <SLoadClient> {
	SLoadInstaller		*realClient;
	BOOL				keepRunning;
	id <SLoadServer>	server;
}
- (void)startChild;
- (BOOL)keepRunning;
@end
