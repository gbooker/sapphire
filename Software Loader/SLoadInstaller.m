/*
 * SLoadInstaller.h
 * Software Loader
 *
 * Created by Graham Booker on Dec. 27 2007.
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

#import "SLoadInstaller.h"
#import <SLoadUtilities/SLoadDelegateProtocol.h>
#import <SLoadUtilities/SLoadInstallerProtocol.h>
#import "SLoadInstallClient.h"
#import "SLoadInstallerInstaller.h"

@interface SLoadInstaller (private)
- (BOOL)loadInstaller:(NSString *)bundlePath;
@end

@implementation SLoadInstaller

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *myPath = [[NSBundle bundleForClass:[SLoadInstaller class]] bundlePath];
	NSString *installersPath = [myPath stringByAppendingPathComponent:@"Contents/Resources/Installers"];
	NSArray *candidates = [fm directoryContentsAtPath:installersPath];
	
	NSEnumerator *candidateEnum = [candidates objectEnumerator];
	NSString *candidate;
	while((candidate = [candidateEnum nextObject]) != nil)
	{
		if(![[candidate pathExtension] isEqualToString:@"framework"])
			continue;
		NSString *bundlePath = [installersPath stringByAppendingPathComponent:candidate];
#ifndef DEBUG_BUILD
		if(![[[fm fileAttributesAtPath:bundlePath traverseLink:YES] objectForKey:NSFileOwnerAccountName] isEqualToString:@"root"])
			continue;
#endif
		[self loadInstaller:bundlePath];
	}
		
	return self;
}

- (void) dealloc
{
	[currentInstaller release];
	[installers release];
	[super dealloc];
}

- (BOOL)loadInstaller:(NSString *)bundlePath
{
	NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
	NSDictionary *info = [bundle infoDictionary];
	NSString *installerName = [info objectForKey:INSTALLER_NAME_KEY];
	if(installerName == nil)
		return NO;
	if([installers objectForKey:installerName] != nil)
		return NO;
	Class installerClass = [bundle principalClass];
	if(![installerClass conformsToProtocol:@protocol(SLoadInstallerProtocol)])
		return NO;
	id installer = [[installerClass alloc] init];
	[installers setObject:installer forKey:installerName];
	[installer release];
	return YES;
}

- (void)setDelegate:(id <SLoadDelegateProtocol>)aDelegate
{
	[delegate release];
	delegate = [aDelegate retain];
	[currentInstaller setDelegate:delegate];
}

- (void)cancel
{
	[currentInstaller cancel];
}

- (void)runInstaller:(id <SLoadInstallerProtocol>)installer withData:(NSDictionary *)software
{
	[currentInstaller cancel];
	[currentInstaller release];
	currentInstaller = [installer retain];
	[currentInstaller setDelegate:delegate];
	[currentInstaller install:software];	
}

- (void)installSoftware:(NSDictionary *)software withInstaller:(NSString *)installer
{
	[self runInstaller:[installers objectForKey:installer] withData:software];
}

- (void)installInstaller:(NSString *)installerName
{
	id <SLoadInstallerProtocol> installer = [[SLoadInstallerInstaller alloc] init];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:installerName, @"lalala",nil];
	[self runInstaller:installer withData:info];
	[installer release];
}

- (NSArray *)installerList
{
	return [installers allKeys];
}

@end