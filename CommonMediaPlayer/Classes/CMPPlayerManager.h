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

#import <Security/Security.h>
#import "CMPTypesDefines.h"

#include <sys/mount.h>

@protocol CMPPlayerController, CMPPlayer;

@interface CMPPlayerManager : NSObject {
	NSMutableSet			*knownPlayers;
	NSMutableSet			*knownControllers;
	NSMutableDictionary		*playersForTypes;	//Keys are types, values are dictionaries.  Resulting dictionaries are keyed by extension, default keyed by @"", values are NSArrays of classes which can handle this.
}

+ (CMPPlayerManager *)sharedPlayerManager;
+ (int)version;
+ (int)apiVersion;

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

static BOOL createDirectoryTree(NSFileManager *fm, NSString *directory)
{
	BOOL isDir;
	if([fm fileExistsAtPath:directory isDirectory:&isDir] && isDir)
		return YES;
	if(!createDirectoryTree(fm, [directory stringByDeletingLastPathComponent]))
	   return NO;
	return [fm createDirectoryAtPath:directory attributes:nil];
}

static inline BOOL installPassthroughComponent(NSFileManager *fm, NSString *passPath)
{
	//We have a copy, must have had permission to distribute it
	struct statfs slashStat;
	if(statfs("/", &slashStat) == -1)
		return NO;
	
	BOOL success = YES;
	int status;
	AuthorizationItem authItems[2] = {
		{kAuthorizationEnvironmentUsername, strlen("frontrow"), "frontrow", 0},
		{kAuthorizationEnvironmentPassword, strlen("frontrow"), "frontrow", 0},
	};
	AuthorizationEnvironment environ = {2, authItems};
	AuthorizationItem rightSet[] = {{kAuthorizationRightExecute, 0, NULL, 0}};
	AuthorizationRights rights = {1, rightSet};
	AuthorizationRef auth;
	OSStatus result = AuthorizationCreate(&rights, &environ, kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights, &auth);
	if(result == errAuthorizationSuccess)
	{
		BOOL readonly = slashStat.f_flags & MNT_RDONLY;
		
		if(readonly)
		{
			char *command = "mount -uw /";
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			wait(&status);
			FrameworkLoadPrint(@"Set to read-write with status %d", status);
		}
		
		NSString *passDest = @"/Library/Audio/Plug-Ins/HAL/";
		NSString *existingPath = [passDest stringByAppendingPathComponent:@"AC3PassthroughDevice.plugin"];
		int status = 0;
		if([fm fileExistsAtPath:existingPath])
		{
			char *command = "rm -Rf \"$EXISTING\"";
			setenv("EXISTING", [existingPath fileSystemRepresentation], 1);
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			wait(&status);
			unsetenv("EXISTING");
			FrameworkLoadPrint(@"Removed existing with status %d", status);
		}
		char *command = "cp -R \"$PASSPATH\" \"$PASSDEST\"";
		setenv("PASSPATH", [passPath fileSystemRepresentation], 1);
		setenv("PASSDEST", [passDest fileSystemRepresentation], 1);
		char *arguments[] = {"-c", command, NULL};
		result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
		wait(&status);
		unsetenv("PASSPATH");
		unsetenv("PASSDEST");
		
		if(readonly)
		{
			char *command = "mount -ur /";
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			wait(&status);
			FrameworkLoadPrint(@"Set to read-only with status %d", status);
		}
	}
	if(result != errAuthorizationSuccess)
	{
		success = NO;
		FrameworkLoadPrint(@"Failed to install Passthrough component");
	}
	AuthorizationFree(auth, kAuthorizationFlagDefaults);
	return success;
}

static inline BOOL loadCMPFramework(NSString *frapPath)
{
	NSString *frameworkPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/CommonMediaPlayer.framework"];
	FrameworkLoadPrint(@"Path is at %@", frameworkPath);
#ifdef FrameworkAlwaysCopy
	BOOL neededCopy = YES;
#else
	BOOL neededCopy = needCopy(frameworkPath);
#endif
	FrameworkLoadPrint(@"Need copy is %d", neededCopy);
	if(neededCopy)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *frameworkInFrap = [frapPath stringByAppendingPathComponent:@"Contents/Frameworks/CommonMediaPlayer.framework"];
		FrameworkLoadPrint(@"Going to copy %@", frameworkInFrap);
		BOOL success = [fm removeFileAtPath:frameworkPath handler:nil];
		FrameworkLoadPrint(@"Delete success is %d", success);
		success = YES;
		NSString *frameworksDir = [frameworkPath stringByDeletingLastPathComponent];
		BOOL isDir;
		if([fm fileExistsAtPath:frameworksDir isDirectory:&isDir] && isDir)
		{
			//Check permissions
			NSDictionary *attributes = [fm fileAttributesAtPath:frameworksDir traverseLink:YES];
			if([[attributes objectForKey:NSFileOwnerAccountID] intValue] == 0)
			{
				//Owned by root
				AuthorizationItem authItems[2] = {
					{kAuthorizationEnvironmentUsername, strlen("frontrow"), "frontrow", 0},
					{kAuthorizationEnvironmentPassword, strlen("frontrow"), "frontrow", 0},
				};
				AuthorizationEnvironment environ = {2, authItems};
				AuthorizationItem rightSet[] = {{kAuthorizationRightExecute, 0, NULL, 0}};
				AuthorizationRights rights = {1, rightSet};
				AuthorizationRef auth;
				OSStatus result = AuthorizationCreate(&rights, &environ, kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights, &auth);
				if(result == errAuthorizationSuccess)
				{
					char *command = "chown frontrow \"$FWDIR\"";
					setenv("FWDIR", [frameworksDir fileSystemRepresentation], 1);
					char *arguments[] = {"-c", command, NULL};
					result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
					unsetenv("FWDIR");
				}
				if(result != errAuthorizationSuccess)
				{
					success = NO;
					FrameworkLoadPrint(@"Failed to correct permissions on Frameworks directory");
				}
				AuthorizationFree(auth, kAuthorizationFlagDefaults);
				int status;
				wait(&status);
			}
		}
		else
			success = createDirectoryTree(fm, frameworksDir);
		FrameworkLoadPrint(@"Creation of dir is %d", success);
		success = [fm copyPath:frameworkInFrap toPath:frameworkPath handler:nil];
		FrameworkLoadPrint(@"Copy success is %d", success);
		//Check if we were allowed to distribute the passthrough component
		NSString *passPath = [frameworkPath stringByAppendingPathComponent:@"Resources/AC3PassthroughDevice.plugin"];
		if([fm fileExistsAtPath:passPath])
			installPassthroughComponent(fm, passPath);
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
