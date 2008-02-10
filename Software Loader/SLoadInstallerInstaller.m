/*
 * SLoadInstallerInstaller.h
 * Software Loader
 *
 * Created by Graham Booker on Jan. 1 2008.
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

#import "SLoadInstallerInstaller.h"
#import <SLoadUtilities/SLoadDelegateProtocol.h>
#import <SLoadUtilities/NSData-HashSupport.h>
#import <SLoadUtilities/SLoadDownloadDelegate.h>
#import <SLoadUtilities/SLoadFileUtilities.h>
#import <SLoadUtilities/SLoadChannelParser.h>

@implementation SLoadInstallerInstaller

- (void) dealloc
{
	[installDict release];
	[super dealloc];
}

enum{
	INSTALLER_INSTALL_STAGE_FETCHING = 0,
	INSTALLER_INSTALL_STAGE_DOWNLOAD,
	INSTALLER_INSTALL_STAGE_EXTRACTING,
	INSTALLER_INSTALL_STAGE_INSTALL,
	INSTALLER_INSTALL_STAGES,
};

NSString *InstallerInstallStrings[] = {
	@"Fetching Info",
	@"Downloading",
	@"Extracting",
	@"Installing",
	@"Install Complete",
};

#define InstallerStageSet(stage) 	[delegate setStage:stage of:INSTALLER_INSTALL_STAGES withName:BRLocalizedString(InstallerInstallStrings[stage], nil)]

- (void)install:(NSDictionary *)installer
{
	[installDict release];
	installDict = nil;

	[delegate setHasDownload:YES];
	InstallerStageSet(INSTALLER_INSTALL_STAGE_FETCHING);
	SLoadChannelParser *parser = [[SLoadChannelParser alloc] init];
	NSDictionary *installers = [parser installers];
	NSDictionary *installerInfo = [installers objectForKey:[[installer allValues] objectAtIndex:0]];
	[parser release];
	
	InstallerStageSet(INSTALLER_INSTALL_STAGE_DOWNLOAD);
	installDict = [installerInfo retain];
	NSString *downloadURL = [installerInfo objectForKey:INSTALL_URL_KEY];
	NSString *md5 = [installerInfo objectForKey:INSTALL_MD5_KEY];
	NSData *md5Data = [NSData dataFromHexString:md5];
	if([md5Data length] != 16 || ![downloadURL length])
	{
		[self setError:BRLocalizedString(@"Could not locate download", @"URL not set error or the md5 hash is in an invalid format")];
		[delegate instalFailed:[self error]];
		return;
	}
	
	SLoadDownloadDelegate *downloadDelegate = [[SLoadDownloadDelegate alloc] initWithDest:@"/tmp/installtemp"];
	[downloadDelegate setTarget:self success:@selector(installInstallerDownloaded:) failure:@selector(downloadFailed:)];
	[downloadDelegate setLoadDelegate:delegate];
	[downloadDelegate setHash:md5Data];
	downloader = [[fileUtils downloadURL:downloadURL withDelegate:downloadDelegate] retain];
	[downloadDelegate release];
}

- (void)installInstallerDownloaded:(NSString *)path
{
	[fileUtils remountReadWrite];
	[downloader release];
	downloader = nil;
	[delegate downloadCompleted];
	InstallerStageSet(INSTALLER_INSTALL_STAGE_EXTRACTING);
	BOOL success = YES;
	
	NSString *tmpPath = @"/tmp";
	NSString *mypath = [[NSBundle mainBundle] bundlePath];
	NSString *installPath = [mypath stringByAppendingPathComponent:@"Contents/Resources/Installers/"];
	success = [fileUtils extract:path inDir:tmpPath];
	InstallerStageSet(INSTALLER_INSTALL_STAGE_INSTALL);
	if(success)
		success = [fileUtils move:[tmpPath stringByAppendingPathComponent:[installDict objectForKey:INSTALL_NAME_KEY]] toDir:installPath withReplacement:YES];
	InstallerStageSet(INSTALLER_INSTALL_STAGES);
	if(!success)
		[delegate instalFailed:[self error]];
	[fileUtils remountReadOnly];
	InstallerStageSet(INSTALLER_INSTALL_STAGES);
}

@end
