/*
 * CMPDVDFrameworkLoadAction.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 3 2010
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

#import "CMPDVDFrameworkLoadAction.h"
#import "CMPTypesDefines.h"
#import "CMPATVVersion.h"

@implementation CMPDVDFrameworkLoadAction

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	return [super init];
}

- (BOOL)stubLoadedWithError:(NSError **)error
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *pathToFramework = @"/System/Library/Frameworks/DVDPlayback.framework/Versions/A/DVDPlayback";
	
	
	NSNumber *sysFrameworkSize;
	NSDictionary *sysFileAttributes;
	//NSLog(@"userPathToFramework: %@", userPathToFramework);
	if ([fm fileExistsAtPath:pathToFramework])
	{
		sysFileAttributes = [fm fileAttributesAtPath:pathToFramework traverseLink:YES];
		sysFrameworkSize = [sysFileAttributes objectForKey:NSFileSize];
		//NSLog(@"sysFrameworkSize: %@", sysFrameworkSize);
		if ([sysFrameworkSize intValue] == 17644)
		{
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"DVD Framework Stub loaded.  Move before DVD Playback will work", @"Stub framework error message"), NSLocalizedDescriptionKey,
																				  nil]];			
			return TRUE;
		}
		else
			return FALSE;
	}
	return FALSE;
}

- (void)fixFramework
{
	NSString *rootPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework"];
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:[rootPath stringByAppendingPathComponent:@"DVDPlayback"] handler:nil];
	[fm removeFileAtPath:[rootPath stringByAppendingPathComponent:@"Headers"] handler:nil];
	[fm removeFileAtPath:[rootPath stringByAppendingPathComponent:@"Resources"] handler:nil];
	[fm removeFileAtPath:[rootPath stringByAppendingPathComponent:@"Versions/Current"] handler:nil];
	
	
	
	[fm createSymbolicLinkAtPath:[rootPath stringByAppendingPathComponent:@"DVDPlayback"] pathContent:[rootPath stringByAppendingPathComponent:@"Versions/A/DVDPlayback"]];
	[fm createSymbolicLinkAtPath:[rootPath stringByAppendingPathComponent:@"Headers"] pathContent:[rootPath stringByAppendingPathComponent:@"Versions/A/Headers"]];
	[fm createSymbolicLinkAtPath:[rootPath stringByAppendingPathComponent:@"Resources"] pathContent:[rootPath stringByAppendingPathComponent:@"Versions/A/Resources"]];
	[fm createSymbolicLinkAtPath:[rootPath stringByAppendingPathComponent:@"Versions/Current"] pathContent:[rootPath stringByAppendingPathComponent:@"Versions/A/"]];
}

- (BOOL)analyzeFrameworkWithError:(NSError **)error
{
	
	/*
	 right now this is a bit flawed but should make due for now, it just checks to see if DVDPlayback is NSFileTypeSymbolicLink, if it is not we run fixFramework which 
	 removes all the duplicates and relinks everything properly
	 
	 */ 
	NSString *rootPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework/"];
	NSDictionary *versionPlist = [NSDictionary dictionaryWithContentsOfFile:[rootPath stringByAppendingPathComponent:@"Resources/version.plist"]];
	
	int frameworkV = [[versionPlist objectForKey:@"CFBundleVersion"] intValue];
	//NSLog(@"DVDPlayback CFBundleVersion: %i", frameworkV);
	
	if (frameworkV != 4700){
		//NSLog(@"bad version, kill");
		//	[self badVFramework:rootPath];
		//	return FALSE;
		
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *attrs = [fm fileAttributesAtPath:[rootPath stringByAppendingPathComponent:@"DVDPlayback"] traverseLink:NO];
	//NSLog(@"DVDPlayback attrs: %@",attrs); 
	NSString *dvdpFType = [attrs objectForKey:NSFileType];
	
	if([dvdpFType isEqualToString:NSFileTypeSymbolicLink])
	{
		//NSLog(@"framework should be okay");
		return TRUE;
	} else {
		//NSLog(@"bunkity framework, attempting to fix");
		[self fixFramework];
		if(error)
			*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			  BRLocalizedString(@"Framework is missing symbolic links", @"Broken framework error message"), NSLocalizedDescriptionKey,
																			  nil]];		
		return FALSE;
	}
	
	if(error)
		*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  BRLocalizedString(@"Framework item that should be symbolic link isn't", @"Broken framework error message"), NSLocalizedDescriptionKey,
																		  nil]];	
	return FALSE;
	
}

- (BOOL)frameworkPresentWithError:(NSError **)error
{
	//NSLog(@"%@ %s", self, _cmd);
	if(![self analyzeFrameworkWithError:error])
		return NO;
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *rootPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework/"];
	NSDictionary *attrs = [man fileAttributesAtPath:rootPath traverseLink:NO];
	NSNumber *fsize = [attrs objectForKey:NSFileSize];
	float kb = [fsize floatValue]/1024;
	float mb = kb/1024;
	if (mb > 7){
		NSLog(@"Playback WARNING: DVDPlayback.framework size of %.0f may be too large, size should be ~5.3 megabytes. Using scp or fugu to install is NOT recommended.", mb);
	}
	NSString *userPathToFramework = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework/Versions/A/DVDPlayback"];
	NSNumber *fileSize;
	NSDictionary *fileAttributes;
	
	if ([man fileExistsAtPath:userPathToFramework])
	{
		fileAttributes = [man fileAttributesAtPath:userPathToFramework traverseLink:YES];
		fileSize = [fileAttributes objectForKey:NSFileSize];
		//NSLog(@"frameworkSize: %@", fileSize);
		if ([fileSize intValue] == 17644)
		{
			if(error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"DVD Framework is wrong size", @"Wrong framework size error message"), NSLocalizedDescriptionKey,
																				  nil]];			
			return FALSE;
		}
		else
			return TRUE;
	}
	if(error)
		*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  BRLocalizedString(@"DVD Framework not Found", @"Failure to find framework error message"), NSLocalizedDescriptionKey,
																		  nil]];	
	return FALSE;
}

- (BOOL)openWithError:(NSError * *)error
{
	if([CMPATVVersion usingLeopard])
		return [[NSBundle bundleWithPath:@"/System/Library/Frameworks/DVDPlayback.framework/"] load];
	
	//NSLog(@"%@ %s", self, _cmd);
	BOOL ret = NO;
	if(![self stubLoadedWithError:error])
	{
		if([self frameworkPresentWithError:error])
		{
			NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/DVDPlayback.framework/"];
			ret = [[NSBundle bundleWithPath:path] load];
			if(ret == NO && error)
				*error = [NSError errorWithDomain:CMPErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  BRLocalizedString(@"Failed to load DVD Framework", @"Failure to load error message"), NSLocalizedDescriptionKey,
																				  nil]];
			else
				NSLog(@"Loaded framework");
		}
	}
	
	return ret;
}

- (BOOL)closeWithError:(NSError **)error
{
	return YES;
}

@end
