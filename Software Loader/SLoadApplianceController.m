/*
 * SLoadApplianceController.m
 * Software Loader
 *
 * Created by Graham Booker on Dec. 22 2007.
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

#import "SLoadApplianceController.h"
#import "SLoadInstaller.h"
#import "SLoadInstallServer.h"
#import "SLoadInstallClient.h"
#import "SLoadInstallProgress.h"
#import <SLoadUtilities/SLoadChannelParser.h>
#import <SLoadUtilities/SLoadInstallerProtocol.h>

@interface SLoadInstallerIntermediateDelegate : NSObject <SLoadDelegateProtocol> {
	id <SLoadDelegateProtocol>		delegate;
	SLoadApplianceController		*controller;
	BOOL							hasError;
}
- (id)initWithDeleate:(id <SLoadDelegateProtocol>)aDelegate withController:(SLoadApplianceController *)aController;
@end

@implementation SLoadInstallerIntermediateDelegate

- (id)initWithDeleate:(id <SLoadDelegateProtocol>)aDelegate withController:(SLoadApplianceController *)aController
{
	self = [super init];
	if(self == nil)
		return nil;
	
	delegate = [aDelegate retain];
	controller = [aController retain];
	
	return self;
}

- (void) dealloc
{
	[delegate release];
	[controller release];
	[super dealloc];
}

- (void)setStage:(int)stage of:(int)totalStages withName:(NSString *)name
{
	[delegate setStage:stage of:totalStages withName:name];
	if(stage == totalStages)
		[controller installerCompletedWithError:hasError];
}

- (void)setDownloadedBytes:(unsigned int)bytes ofTotal:(unsigned int)total
{
	[delegate setDownloadedBytes:bytes ofTotal:total];
}

- (void)setHasDownload:(BOOL)hasDownload
{
	[delegate setHasDownload:hasDownload];
}

- (void)downloadCompleted
{
	[delegate downloadCompleted];
}

- (void)instalFailed:(NSString *)error
{
	[delegate instalFailed:error];
	hasError = YES;
}

@end

@implementation SLoadApplianceController

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(self == nil)
		return nil;
	
	installServer = [[SLoadInstallServer alloc] init];
	
	parser = [[SLoadChannelParser alloc] init];
	software = [[parser softwareList] retain];
	
	[[self list] setDatasource:self];
	
	return self;
}

- (void) dealloc
{
	[software release];
	[installServer release];
	[parser release];
	[super dealloc];
}

- (long) itemCount
{
	return [software count];
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	BRAdornedMenuItemLayer *ret = [BRAdornedMenuItemLayer adornedMenuItemWithScene:[self scene]];
	[[ret textItem] setTitle:[[software objectAtIndex:row] objectForKey:INSTALL_DISPLAY_NAME_KEY]];
}

- (NSString *) titleForRow: (long) row
{
	
	if ( row > [ software count] ) return ( nil );
	
	NSString *result = [[software objectAtIndex:row] objectForKey:INSTALL_DISPLAY_NAME_KEY];
	return ( result ) ;
}

- (long) rowForTitle: (NSString *) title
{
    long result = -1;
    long i, count = [self itemCount];
    for ( i = 0; i < count; i++ )
    {
        if ( [title isEqualToString: [self titleForRow: i]] )
        {
            result = i;
            break;
        }
    }
    
    return ( result );
}

typedef enum{
	COMMAND_SUCCESS,
	COMMAND_COULD_NOT_EXECUTE,
	COMMAND_FAILED,
} CommandStatus;

- (void) itemSelected: (long) row
{
	NSLog(@"Running install");
	SLoadInstallProgress *progress = [[SLoadInstallProgress alloc] initWithScene:[self scene]];
	id <SLoadClient> client = [installServer client];
	[client setDelegate:progress];
	install = [software objectAtIndex:row];
	NSString *installer = [[[install objectForKey:INSTALL_INSTALLER_KEY] objectAtIndex:0] objectForKey:INSTALL_NAME_KEY];
	if(![[client installerList] containsObject:installer])
	{
		SLoadInstallerIntermediateDelegate *newDelegate = [[SLoadInstallerIntermediateDelegate alloc] initWithDeleate:progress withController:self];
		[client setDelegate:newDelegate];
		[client installInstaller:installer];
		[newDelegate release];
	}
	else
		[client installSoftware:install withInstaller:installer];
	[progress release];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) item
{
	return nil;
}

- (void)installerCompletedWithError:(BOOL)error
{
	if(error == YES)
		return;
	
	SLoadInstallProgress *progress = [[SLoadInstallProgress alloc] initWithScene:[self scene]];
	id <SLoadClient> client = [installServer client];
	[client setDelegate:progress];
	NSString *installer = [[[install objectForKey:INSTALL_INSTALLER_KEY] objectAtIndex:0] objectForKey:INSTALL_NAME_KEY];
	[client installSoftware:install withInstaller:installer];
	[progress release];
}

@end
