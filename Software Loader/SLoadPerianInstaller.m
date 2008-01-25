/*
 * SLoadPerianInstaller.h
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

#import "SLoadPerianInstaller.h"
#import <SLoadUtilities/SLoadDelegateProtocol.h>
#import <SLoadUtilities/NSData-HashSupport.h>
#import <SLoadUtilities/SLoadDownloadDelegate.h>
#import <SLoadUtilities/SLoadFileUtilities.h>

@interface SLoadPerianInstaller (private)
- (void)installPerianDownloaded:(NSString *)path;
@end

@implementation SLoadPerianInstaller

enum{
	PERIAN_INSTALL_STAGE_UPDATE_CHECK = 0,
	PERIAN_INSTALL_STAGE_DOWNLOAD,
	PERIAN_INSTALL_STAGE_INSTALLING,
	PERIAN_INSTALL_STAGE_INSTALLING_COMPONENTS,
	PERIAN_INSTALL_STAGES,
};

NSString *PerianInstallStrings[] = {
	@"Checking for Updates",
	@"Downloading Perian",
	@"Installing Perian",
	@"Installing Perian Components",
	@"Install Complete",
};

#define PerianStageSet(stage) 	[delegate setStage:stage of:PERIAN_INSTALL_STAGES withName:BRLocalizedString(PerianInstallStrings[stage], nil)]

- (void)install:(NSDictionary *)software
{
	[delegate setHasDownload:YES];
	PerianStageSet(PERIAN_INSTALL_STAGE_UPDATE_CHECK);
	NSURL *updateURL = [NSURL URLWithString:@"http://www.perian.org/appcast.xml"];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:updateURL options:NSXMLDocumentTidyXML error:nil];
	if(document == nil)
	{
		[self setError:BRLocalizedString(@"Could not get perian update list", nil)];
		[delegate instalFailed:[self error]];
		return;
	}
	NSString *md5 = [[document objectsForXQuery:@"//enclosure/@md5Sum/string()" error:nil] objectAtIndex:0];
	NSString *url = [[document objectsForXQuery:@"//enclosure/@url/string()" error:nil] objectAtIndex:0];
	NSData *md5Data = [NSData dataFromHexString:md5];
	if([md5Data length] != 16 || ![url length])
	{
		[self setError:BRLocalizedString(@"Could not get perian update data", nil)];
		[delegate instalFailed:[self error]];
		return;
	}
	PerianStageSet(PERIAN_INSTALL_STAGE_DOWNLOAD);
	NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Frontrow/Perian.dmg"];
	if(![filemanager fileExistsAtPath:path] || ![[NSData md5HashForFile:path] isEqualToData:md5Data])
	{
		SLoadDownloadDelegate *downloadDelegate = [[SLoadDownloadDelegate alloc] initWithDest:path];
		[downloadDelegate setTarget:self success:@selector(installPerianDownloaded:) failure:@selector(downloadFailed:)];
		[downloadDelegate setLoadDelegate:delegate];
		[downloadDelegate setHash:md5Data];
		downloader = [[fileUtils downloadURL:url withDelegate:downloadDelegate] retain];
		[downloadDelegate release];
		return;
	}
	[self installPerianDownloaded:path];
}

- (void)installPerianDownloaded:(NSString *)path
{
	[fileUtils remountReadWrite];
	[downloader release];
	downloader = nil;
	[delegate downloadCompleted];
	PerianStageSet(PERIAN_INSTALL_STAGE_INSTALLING);
	NSString *tmpPath = @"/tmp";
	NSArray *mounts = [fileUtils mountDiskImage:path];
	if([mounts count])
	{
		BOOL success = YES;
		NSString *panePath = [[mounts objectAtIndex:0] stringByAppendingPathComponent:@"Perian.prefPane"];
		NSString *rootPath = [panePath stringByAppendingPathComponent:@"/Contents/Resources/Components"];
		success = [fileUtils extract:[rootPath stringByAppendingPathComponent:@"Perian.zip"] inDir:tmpPath];
		if(success)
			success = [fileUtils move:[tmpPath stringByAppendingPathComponent:@"Perian.component"] toDir:@"/Library/Quicktime" withReplacement:YES];
		PerianStageSet(PERIAN_INSTALL_STAGE_INSTALLING_COMPONENTS);
		NSArray *components = [[[NSBundle bundleWithPath:panePath] infoDictionary] objectForKey:@"Components"];
		NSEnumerator *compEnum = [components objectEnumerator];
		NSDictionary *compInfo;
		while((compInfo = [compEnum nextObject]) != nil && success)
		{
			NSString *zipFile = [compInfo objectForKey:@"ArchiveName"];
			NSString *fileName = [compInfo objectForKey:@"Name"];
			if(!zipFile || !fileName)
				continue;
			NSString *finalDest = nil;
			NSString *sourceFile = nil;
			if([[compInfo objectForKey:@"Type"] intValue] == 1)
			{
				finalDest = @"/Library/Audio/Plug-Ins/Components";
				sourceFile = [[rootPath stringByAppendingPathComponent:@"CoreAudio"] stringByAppendingPathComponent:zipFile];
			}
			else
			{
				finalDest = @"/Library/QuickTime";
				sourceFile = [[rootPath stringByAppendingPathComponent:@"QuickTime"] stringByAppendingPathComponent:zipFile];
			}
			if(success)
				success = [fileUtils extract:sourceFile inDir:tmpPath];
			if(success)
				success = [fileUtils move:[tmpPath stringByAppendingPathComponent:fileName] toDir:finalDest withReplacement:YES];						
		}
		[fileUtils unmountDiskImage:mounts];
		if(!success)
			[delegate instalFailed:[self error]];
	}
	[fileUtils remountReadOnly];
	PerianStageSet(PERIAN_INSTALL_STAGES);
}

@end
