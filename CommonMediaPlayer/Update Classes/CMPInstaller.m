/*
 * CMPInstaller.m
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 25 2010
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
#import "AGProcess.h"
#import "CMPInstaller.h"


@implementation CMPInstaller

+ (BOOL)checkForUpdate
{
	NSString *updateURL = @"http://nitosoft.com/CMP/version.plist";
	NSDictionary *onlineDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:updateURL]];
	int versionNumber = [[onlineDict valueForKey:@"version"] intValue];
	
	if (CMPVersion < versionNumber)
	{
		NSLog(@"online version %i is greater than installed version %i", versionNumber, CMPVersion);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CMPUpdateAvailable" object:self userInfo:onlineDict];
		return YES;
	} else {
		return NO;
		
	}
	return NO;
}

+ (void)killFinder
{
	//NSLog(@"%@ %s", self, _cmd);
	
	[[BRAppManager sharedApplication] terminate];
	AGProcess *finder = [AGProcess processForCommand:@"Finder"];
	if (finder != nil)
	{
		[finder terminate];
	}
	
}

- (id <CMPInstallerDelegate>)delegate
{
	return delegate;
}

-(void)setDelegate:(id <CMPInstallerDelegate>)theDelegate
{
	delegate = [theDelegate retain];
	
}

- (id)initWithUpdate:(NSString *)updatePath
{
	self = [super init];
	_zipFile = updatePath;

	[_zipFile retain];
	
	return self;
	
}


- (BOOL)performUpdate
{
	NSMutableDictionary *settingsDict = [[NSMutableDictionary alloc] init];
	NSString *frameworkLocation = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Frameworks/CommonMediaPlayer.framework"];
	NSString *frameworkLocationBak = [frameworkLocation stringByAppendingPathExtension:@"bak"];
	NSFileManager *man = [NSFileManager defaultManager];
	if ([man movePath:frameworkLocation toPath:frameworkLocationBak handler:nil])
	{
		NSLog(@"moved old version");
		if ([self unzipFile:_zipFile toPath:[frameworkLocation stringByDeletingLastPathComponent]])
		{
			NSLog(@"Update Success!");
			[man removeFileAtPath:frameworkLocationBak handler:nil];
			[settingsDict setValue:BRLocalizedString(@"Installed Successfully!", @"Installed Successfully!") forKey:@"title"];
			[settingsDict setValue:BRLocalizedString(@"CommonMediaPlayer Updated Successfully! Restarting the Finder...", @"CommonMediaPlayer Updated Successfully! Restarting the Finder...") forKey:@"sourceText"];
			[settingsDict setValue:@"killFinder" forKey:@"action"];
			[delegate installer:self didEndWithSettings:settingsDict];
			[settingsDict release];
			return YES;
		} else {
			NSLog(@"unzip fail!");
			[man movePath:frameworkLocationBak toPath:frameworkLocation handler:nil];
			[settingsDict setValue:BRLocalizedString(@"Installation Failed!", @"Installation Failed!") forKey:@"title"];
			[settingsDict setValue:BRLocalizedString(@"CommonMediaPlayer failed to update!", @"CommonMediaPlayer failed to update!") forKey:@"sourceText"];
			[settingsDict setValue:@"popTop" forKey:@"action"];
			[delegate installer:self didEndWithSettings:settingsDict];
			[settingsDict release];
			return NO;
		}
		
	} else {
		
		NSLog(@"Removal failed!");
		[settingsDict setValue:BRLocalizedString(@"Installation Failed!", @"Installation Failed!") forKey:@"title"];
		[settingsDict setValue:BRLocalizedString(@"CommonMediaPlayer failed to update!", @"CommonMediaPlayer failed to update!") forKey:@"sourceText"];
		[settingsDict setValue:@"popTop" forKey:@"action"];
		[delegate installer:self didEndWithSettings:settingsDict];
		[settingsDict release];
		return NO;
	}

	
	return NO;
	
	
}


- (BOOL)unzipFile:(NSString *)theFile toPath:(NSString *)newPath
{
	//	NSLog(@"%@ %s", self, _cmd);

	NSString *uzp = [[NSBundle bundleForClass:[CMPInstaller class]] pathForResource:@"unzip" ofType:@"" inDirectory:@"bin"];
	NSFileManager *man = [NSFileManager defaultManager];
	
	if (![man fileExistsAtPath:uzp])
	{
		//NSLog(@"uzp: %@ missing?", uzp);
		uzp = @"/usr/bin/unzip";
	}
	
	if (![man fileExistsAtPath:uzp])
	{
		return NO;
	}
	
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	//NSLog(@"uzp2: %@", uzp2);
	NSTask *unzipTask = [[NSTask alloc] init];
	
	
    [unzipTask setLaunchPath:uzp];
    [unzipTask setArguments:[NSArray arrayWithObjects:@"-o", theFile, @"-d", newPath, nil]];
	[unzipTask setStandardOutput:nullOut];
	[unzipTask setStandardError:nullOut];
    [unzipTask launch];
	[unzipTask waitUntilExit];
	int theTerm = [unzipTask terminationStatus];
	//NSLog(@"helperTask terminated with status: %i",theTerm);
	if (theTerm != 0)
	{
		//NSLog(@"failure unzip %@ to %@", theFile, newPath);
		return (NO);
		
	} else if (theTerm == 0){
		//NSLog(@"success unzip %@ to %@", theFile, newPath);
		
		return (YES);
	}
	
	return (NO);
}

@end
