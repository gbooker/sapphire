/*
 * CMPPlayerManager.h
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 1 2010
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

#import "CMPTypesDefines.h"

@protocol CMPPlayerController, CMPPlayer;

@interface CMPPlayerManager : NSObject {
	NSMutableSet			*knownPlayers;
	NSMutableSet			*knownControllers;
	NSMutableDictionary		*playersForTypes;	//Keys are types, values are dictionaries.  Resulting dictionaries are keyed by extension, default keyed by @"", values are NSArrays of classes which can handle this.
}

+ (CMPPlayerManager *)sharedPlayerManager;

//types is a dictionary with the key being the type above, and value is an array of extensions (empty array means any extension)
- (void)registerPlayer:(Class)player forTypes:(NSDictionary *)types;
- (void)registerPlayer:(Class)player forType:(CMPPlayerManagerFileType)type withExtensions:(NSArray *)extensions;
//preferences are same formate as playersForTypes listed above
- (id <CMPPlayer>)playerForPath:(NSString *)path type:(CMPPlayerManagerFileType)type preferences:(NSDictionary *)preferences;
- (id <CMPPlayerController>)playerControllerForPlayer:(id <CMPPlayer>)player scene:(BRRenderScene *)scene preferences:(NSDictionary *)preferences;

@end

#ifdef FrameworkLoadDebug
#define FrameworkLoadPrint(...) NSLog(__VA_ARGS__)
#else
#define FrameworkLoadPrint(...)
#endif

static inline BOOL needCopy(NSString *frameworkPath)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	FrameworkLoadPrint(@"Checking if dir exists");
	if(![fm fileExistsAtPath:frameworkPath isDirectory:&isDir] || !isDir)
		return YES;
	
	NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
	NSString *plistPath = [bundle pathForResource:@"Info" ofType:@"plist"];
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	
	NSString *version = [plist objectForKey:@"CFBundleVersion"];
	FrameworkLoadPrint(@"Version is %@:%d compared to %d", version, [version intValue], CMPVersion);
	if([version intValue] < CMPVersion)
		return YES;
	
	return NO;
}

static inline BOOL loadCMPFramework(NSString *frapPath)
{
	NSString *frameworkPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/CommonMediaPlayer.framework"];
	FrameworkLoadPrint(@"Path is at %@", frameworkPath);
	BOOL neededCopy = needCopy(frameworkPath);
	FrameworkLoadPrint(@"Need copy is %d", neededCopy);
	if(neededCopy)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		FrameworkLoadPrint(@"Going to copy %@", [frapPath stringByAppendingPathComponent:@"Contents/Frameworks/CommonMediaPlayer.framework"]);
		BOOL success = [fm removeFileAtPath:frameworkPath handler:nil];
		FrameworkLoadPrint(@"Delete success is %d", success);
		success = [fm copyPath:[frapPath stringByAppendingPathComponent:@"Contents/Frameworks/CommonMediaPlayer.framework"] toPath:frameworkPath handler:nil];
		FrameworkLoadPrint(@"Copy success is %d", success);
		if(!success || needCopy(frameworkPath))
			//We failed in our copy too!
			return NO;
	}
	
	NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
	FrameworkLoadPrint(@"Bundle is %@", framework);
	if([framework isLoaded] && neededCopy)
	{
		//We should restart here
		FrameworkLoadPrint(@"Need to restart");
		[[NSApplication sharedApplication] terminate:nil];
	}
	
	FrameworkLoadPrint(@"Loading framework");
	return [framework load];
}
