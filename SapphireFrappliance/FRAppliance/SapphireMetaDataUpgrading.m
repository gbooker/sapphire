/*
 * SapphireMetaDataUpgrading.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 2 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireMetaDataUpgrading.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireMetaDataSupport.h"
#import "SapphireApplianceController.h"
#import "SapphireApplianceController.h"
#import "SapphireTVTranslation.h"
#import "SapphireSettings.h"

@implementation SapphireMetaDataUpgrading

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(self == nil)
		return self;

	[self setListTitle:BRLocalizedString(@"Upgrading Metadata", @"Menu title indicating Sapphire is upgrading metadata")];
	
	status = [SapphireFrontRowCompat newTextControlWithScene:scene];
	if([BRWaitSpinnerControl instancesRespondToSelector:@selector(initWithScene:)])
		spinner = [[BRWaitSpinnerControl alloc] initWithScene:scene];
	else
		spinner = [[BRWaitSpinnerControl alloc] init];
	
	if([SapphireFrontRowCompat usingLeopard])
	{
		[spinner release];
		spinner = [[BRWaitSpinnerLayer alloc] init];
	}
	
	[self doMyLayout];
	
	[self addControl:status];
	if([SapphireFrontRowCompat usingLeopard])
		[SapphireFrontRowCompat addSublayer:spinner toControl:self];
	else
		[self addControl:spinner];
	
	[SapphireLayoutManager setCustomLayoutOnControl:self];

	return self;
	
}

- (void)doMyLayout
{
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	frame.origin.y += frame.size.height / 2.0f;
	frame.origin.x = frame.size.width / 2.0f;
	frame.size.width = frame.size.height = frame.size.height / 6.0f;
	[spinner setFrame:frame] ;
}

- (void) dealloc
{
	[spinner release];
	[status release];
	[super dealloc];
}

- (void)realSetCurrentFile:(NSString *)file
{
	if(file == nil)
		file = @"";
	[SapphireFrontRowCompat setText:file withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:status];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize progressSize = [SapphireFrontRowCompat textControl:status renderedSizeWithMaxSize:NSMakeSize(master.size.width, master.size.height * 0.3f)];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.12f) + master.origin.y;
	frame.size = progressSize;
	[status setFrame:frame];
}

- (void)setCurrentFile:(NSString *)file
{
	[self performSelectorOnMainThread:@selector(realSetCurrentFile:) withObject:file waitUntilDone:YES];
}

- (void)cleanup
{
	NSManagedObjectContext *moc = [SapphireMetaDataSupport mainContext];
	if(!moc)
		return;
	
	[SapphireTVTranslation cancelShowIDFetchInContext:moc];
	[SapphireMetaDataSupport save:moc];
	[SapphireMetaDataSupport setMainContext:nil];
}

- (void)finished
{
	[self cleanup];
	if([SapphireApplianceController upgradeNeeded])
		[self setCurrentFile:BRLocalizedString(@"Upgrading Needs to Be Run Again; Press Menu to Go Back and Run", @"Upgrade progress indicator stating Sapphire is done upgrading and user should press menu")];
	else
		[self setCurrentFile:BRLocalizedString(@"Upgrading Complete; Press Menu to Go Back", @"Upgrade progress indicator stating Sapphire is done upgrading and user should press menu")];
	if(![SapphireFrontRowCompat usingATypeOfTakeTwo])
		[[self stack] popController];
}

- (NSManagedObjectContext *)newMoc:(NSString *)storeFile withVersion:(NSString *)version
{
	NSURL *storeUrl = [NSURL fileURLWithPath:storeFile];
	NSError *error = nil;
	
	NSString *mopath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Sapphire" ofType:@"momd"];
	mopath = [mopath stringByAppendingPathComponent:[NSString stringWithFormat:@"Sapphire%@.mom", version]];
	NSURL *mourl = [NSURL fileURLWithPath:mopath];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mourl];
	
	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	if(![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
	{
		SapphireLog(SapphireLogTypeAll, SapphireLogLevelError, @"Could not add store: %@", error);
		
		[coord release];
		[model release];
		return nil;
	}
	
	NSManagedObjectContext *retmoc = [[NSManagedObjectContext alloc] init];
	[retmoc setUndoManager:nil];
	[retmoc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	[retmoc setPersistentStoreCoordinator:coord];
	
	[model release];
	[coord release];
	
	return retmoc;	
}

- (void)doTVTranslations:(NSManagedObjectContext *)moc
{
	SapphireURLLoader *loader = [SapphireApplianceController urlLoader];
	[loader addDelegate:self];
	remainingURLs = [loader loadingURLCount];
	[SapphireTVTranslation fetchShowIDsInContext:moc];
	if(remainingURLs)
		[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Upgrading Requires Network Queries %d left", @"Upgrade progress indicator stating Sapphire is upgrading with network info.  Parameter is number of URLs remaining"), remainingURLs]];
	else
		[self finished];
}

- (void)doUpgrade:(id)obj
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *v3StoreFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV3"];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	BOOL v3Existed = [fm fileExistsAtPath:v3StoreFile];
	NSString *v1StoreFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireData"];
	NSString *v2StoreFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV2"];
	NSManagedObjectContext *moc = [SapphireApplianceController newManagedObjectContextForFile:nil withOptions:nil];
	SapphireSettings *settings = [[SapphireSettings alloc] initWithScene:[self scene] settingsPath:[applicationSupportDir() stringByAppendingPathComponent:@"settings.plist"] context:moc];
	@try {
		if(v3Existed)
		{
			//Likely the TV Translations failed due to network; try again
			//Will be done later
		}
		else if([fm fileExistsAtPath:v2StoreFile])
		{
			NSManagedObjectContext *oldContext = [self newMoc:v2StoreFile withVersion:@"V2"];
			if(oldContext != nil)
				[SapphireMetaDataSupport importVersion:2 store:oldContext intoContext:moc withDisplay:self];
			[oldContext release];
		}
		else if([fm fileExistsAtPath:v1StoreFile])
		{
			NSManagedObjectContext *oldContext = [self newMoc:v1StoreFile withVersion:@"V1"];
			if(oldContext != nil)
				[SapphireMetaDataSupport importVersion:1 store:oldContext intoContext:moc withDisplay:self];
			[oldContext release];
		}
		else
		{
			NSLog(@"Checking for Plist files to upgrade");
			[SapphireMetaDataSupport importPlist:applicationSupportDir() intoContext:moc withDisplay:self];
		}
		[SapphireMetaDataSupport setMainContext:moc];
		[SapphireMetaDataSupport save:moc];
		[self performSelectorOnMainThread:@selector(doTVTranslations:) withObject:moc waitUntilDone:NO];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	[moc release];
	[SapphireSettings relinquishSettings];
	[settings release];
	[pool drain];
}

- (void)wasPushed
{
	[super wasPushed];
	[SapphireFrontRowCompat setSpinner:spinner toSpin:YES];
	[NSThread detachNewThreadSelector:@selector(doUpgrade:) toTarget:self withObject:nil];
}

- (void)wasPopped
{
	[super wasPopped];
	[self cleanup];
}

- (void)urlLoaderFinisedResource:(SapphireURLLoader *)loader
{
	remainingURLs--;
	if(!remainingURLs)
	{
		[self performSelector:@selector(finished) withObject:nil afterDelay:0.0];
	}
	else
		[self setCurrentFile:[NSString stringWithFormat:BRLocalizedString(@"Upgrading Requires Network Queries %d left", @"Upgrade progress indicator stating Sapphire is upgrading with network info.  Parameter is number of URLs remaining"), remainingURLs]];
}

- (void)urlLoaderCancelledResource:(SapphireURLLoader *)loader
{
}

- (void)urlLoaderAddedResource:(SapphireURLLoader *)loader
{
	remainingURLs++;
}

@end
