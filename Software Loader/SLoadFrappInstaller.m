/*
 * SLoadFrappInstaller.m
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

#import "SLoadFrappInstaller.h"
#import <SLoadUtilities/SLoadDelegateProtocol.h>
#import <SLoadUtilities/NSData-HashSupport.h>
#import <SLoadUtilities/SLoadDownloadDelegate.h>
#import <SLoadUtilities/SLoadFileUtilities.h>

@implementation SLoadFrappInstaller

- (void) dealloc
{
	[installDict release];
	[super dealloc];
}

enum{
	FRAP_INSTALL_STAGE_DOWNLOAD = 0,
	FRAP_INSTALL_STAGE_EXTRACTING,
	FRAP_INSTALL_STAGE_INSTALL,
	FRAP_INSTALL_STAGE_STAGES,
};

NSString *FrapInstallStrings[] = {
	@"Downloading",
	@"Extracting",
	@"Installing",
};

#define FrapStageSet(stage) [delegate setStage:stage of:FRAP_INSTALL_STAGE_STAGES withName:BRLocalizedString(FrapInstallStrings[stage], nil)]

- (void)install:(NSDictionary *)software
{
	[installDict release];
	installDict = [software retain];
	[delegate setHasDownload:YES];
	FrapStageSet(FRAP_INSTALL_STAGE_DOWNLOAD);
	NSString *downloadURL = [software objectForKey:INSTALL_URL_KEY];
	NSString *md5 = [software objectForKey:INSTALL_MD5_KEY];
	NSData *md5Data = [NSData dataFromHexString:md5];
	if([md5Data length] != 16 || ![downloadURL length])
	{
		[self setError:BRLocalizedString(@"Could not locate download", @"URL not set error or the md5 hash is in an invalid format")];
		[delegate instalFailed:[self error]];
		return;
	}
	SLoadDownloadDelegate *downloadDelegate = [[SLoadDownloadDelegate alloc] initWithDest:@"/tmp/installtemp"];
	[downloadDelegate setTarget:self success:@selector(installFrapDownloaded:) failure:@selector(downloadFailed:)];
	[downloadDelegate setLoadDelegate:delegate];
	[downloadDelegate setHash:md5Data];
	downloader = [[fileUtils downloadURL:downloadURL withDelegate:downloadDelegate] retain];
	[downloadDelegate release];
}

- (void)installFrapDownloaded:(NSString *)path
{
	[fileUtils remountReadWrite];
	[downloader release];
	downloader = nil;
	[delegate downloadCompleted];
	FrapStageSet(FRAP_INSTALL_STAGE_EXTRACTING);
	BOOL success = YES;
	
	NSString *tmpPath = @"/tmp";
	NSString *mypath = [[NSBundle mainBundle] bundlePath];
	NSString *installPath = [mypath stringByDeletingLastPathComponent];
	success = [fileUtils extract:path inDir:tmpPath];
	FrapStageSet(FRAP_INSTALL_STAGE_INSTALL);
	if(success)
		success = [fileUtils move:[tmpPath stringByAppendingPathComponent:[installDict objectForKey:INSTALL_NAME_KEY]] toDir:installPath withReplacement:YES];
	[fileUtils remountReadOnly];
	FrapStageSet(FRAP_INSTALL_STAGE_STAGES);
}

@end