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

- (void)finished
{
	if(![SapphireFrontRowCompat usingATypeOfTakeTwo])
		[[self stack] popController];
}

- (NSManagedObjectContext *)newV1Moc:(NSString *)storeFile
{
	NSURL *storeUrl = [NSURL fileURLWithPath:storeFile];
	NSError *error = nil;
	
	NSString *mopath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Sapphire" ofType:@"momd"];
	mopath = [mopath stringByAppendingPathComponent:@"SapphireV1.mom"];
	NSURL *mourl = [NSURL fileURLWithPath:mopath];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mourl];
	
	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	if(![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
	{
		SapphireLog(SAPPHIRE_LOG_ALL, SAPPHIRE_LOG_LEVEL_ERROR, @"Could not add store: %@", error);
		
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

- (void)doUpgrade:(id)obj
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *v1StoreFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireData"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSManagedObjectContext *moc = [SapphireApplianceController newManagedObjectContextForFile:nil withOptions:nil];
	@try {
		if([fm fileExistsAtPath:v1StoreFile])
		{
			NSManagedObjectContext *oldContext = [self newV1Moc:v1StoreFile];
			if(oldContext != nil)
				[SapphireMetaDataSupport importV1Store:oldContext intoContext:moc withDisplay:self];
			[oldContext release];
		}
		else
		{
			NSLog(@"Checking for Plist files to upgrade");
			[SapphireMetaDataSupport importPlist:applicationSupportDir() intoContext:moc withDisplay:self];
		}
		[SapphireMetaDataSupport setMainContext:moc];
		[SapphireMetaDataSupport save:moc];
		[SapphireMetaDataSupport setMainContext:nil];
		[self setCurrentFile:BRLocalizedString(@"Upgrading Complete; Press Menu to Go Back", @"Upgrade progress indicator stating Sapphire is done upgrading and user should press menu")];
		
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	[moc release];
	[self performSelectorOnMainThread:@selector(finished) withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (void)wasPushed
{
	[super wasPushed];
	[SapphireFrontRowCompat setSpinner:spinner toSpin:YES];
	[NSThread detachNewThreadSelector:@selector(doUpgrade:) toTarget:self withObject:nil];
}

@end
