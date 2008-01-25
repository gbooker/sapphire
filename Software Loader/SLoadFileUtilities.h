/*
 * SLoadFileUtilities.h
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

@class SLoadDownloadDelegate;

@interface SLoadFileUtilities : NSObject {
	NSString		*error;
	NSFileManager	*filemanager;
	BOOL			wasReadOnly;
}

+ (SLoadFileUtilities *)sharedInstance;
- (NSString *)error;
- (BOOL)extract:(NSString *)src inDir:(NSString *)dest;
- (BOOL)copy:(NSString *)src toDir:(NSString *)dest withReplacement:(BOOL)replace;
- (BOOL)move:(NSString *)src toDir:(NSString *)dest withReplacement:(BOOL)replace;
- (NSURLDownload *)downloadURL:(NSString *)urlString withDelegate:(SLoadDownloadDelegate *)downloadDelegate;
- (NSArray *)mountDiskImage:(NSString *)path;
- (void)unmountDiskImage:(NSArray *)mounts;
- (void)remountReadWrite;
- (void)remountReadOnly;
@end
