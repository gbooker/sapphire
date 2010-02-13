/*
 * CMPDVDImageAction.h
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 3 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */

#import <Cocoa/Cocoa.h>
#import "CMPActionController.h"
#import "CMPISODVDPlayer.h"
#import "CMPDVDImageAction.h"

@class CMPActionController;
@interface CMPDVDImageAction : NSObject <CMPActionController>{

	NSString *imagePath;
	NSString *mountedPath;
	id player;
}
- (NSString *)imagePath;
- (void)setImagePath:(NSString *)value;

- (NSString *)mountedPath;
- (void)setMountedPath:(NSString *)value;
- (BOOL)openWithError:(NSError **)error;
- (id)initWithPlayer:(id <CMPPlayer>)thePlayer andPath:(NSString *)thePath;
- (NSString *)attachImage:(NSString *)irString;
- (BOOL)detachImage:(NSString *)theImagePath;
@end
