/*
 * SapphireImportHelper.m
 * Sapphire
 *
 * Created by Graham Booker on Dec. 8, 2007.
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

#import "SapphireImportHelper.h"
#import "SapphireMetaData.h"
#import "SapphireAllImporter.h"
#import "SapphireFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireMovieImporter.h"

#define CONNECTION_NAME @"Sapphire Server"

@interface SapphireImportFile : NSObject <SapphireImportFileProtocol>{
	id <SapphireFileMetaDataProtocol>		file;
	id <SapphireImporterBackgroundProtocol>	informer;
	ImportType								type;
}
- (id)initWithFile:(id <SapphireFileMetaDataProtocol>)aFile informer:(id <SapphireImporterBackgroundProtocol>)aInformer type:(ImportType)aType;
@end

@interface SapphireImportHelperServer (private)
- (void)startClient;
@end

static void childHandler(int i)
{
	int status;
	pid_t child;
	
	while((child = waitpid(-1, &status, WNOHANG)) > 0);
}

@implementation SapphireImportHelper

static SapphireImportHelper *shared = nil;

+ (SapphireImportHelper *)sharedHelper
{
	if(shared == nil)
		shared = [[SapphireImportHelperServer alloc] init];

	return shared;
}

+ (void)relinquishHelper
{
	if(shared != nil)
		[shared relinquishHelper];
}

- (void)relinquishHelper
{
}

- (void)importFileData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
{
}

- (void)importAllData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
{
}

- (void)removeObjectsWithInform:(id <SapphireImporterBackgroundProtocol>)inform
{
}

@end

@implementation SapphireImportHelperClient

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	SapphireFileDataImporter *fileImp = [[SapphireFileDataImporter alloc] init];
	SapphireTVShowImporter *tvImp = [[SapphireTVShowImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/tvdata.plist"]];
	SapphireMovieImporter *movImp = [[SapphireMovieImporter alloc] initWithSavedSetting:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Sapphire/movieData.plist"]];
	allImporter = [[SapphireAllImporter alloc] initWithImporters:[NSArray arrayWithObjects:tvImp,movImp,fileImp,nil]];
	[fileImp release];
	[tvImp release];
	[movImp release];
	keepRunning = YES;
	
	return self;
}
- (void) dealloc
{
	[server release];
	[allImporter release];
	[super dealloc];
}

- (void)importFileData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
{
	updateMetaData(file);
}

- (void)startChild
{
	/*Child here*/
	@try {
		NSConnection *connection = [NSConnection connectionWithRegisteredName:CONNECTION_NAME host:nil];
		id serverobj = [[connection rootProxy] retain];
		[serverobj setProtocolForProxy:@protocol(SapphireImportServer)];
		shared = self;
		[serverobj setClient:(SapphireImportHelperClient *)shared];
		server = serverobj;	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];		
	}
	@catch (NSException * e) {
		keepRunning = NO;
	}
}

- (BOOL)keepRunning
{
	return keepRunning;
}

- (void)connectionDidDie:(NSNotification *)note
{
	[self exitChild];
}

- (oneway void)exitChild
{
	keepRunning = NO;
}

- (oneway void)startQueue
{
	id <SapphireImportFileProtocol> file = nil;
	while((file = [server nextFile]) != nil)
	{
		ImportType type = [file importType];
		BOOL ret;
		if(type == IMPORT_TYPE_FILE_DATA)
			ret = updateMetaData([file file]);
		else
			ret = [allImporter importMetaData:[file file]];
		[server importComplete:ret];
	}
}
@end

@implementation SapphireImportHelperServer

- (id) init
{
	self = [super init];
	if (self == nil)
		return nil;
	
	queue = [[NSMutableArray alloc] init];
	queueSuspended = NO;
	
	serverConnection = [NSConnection defaultConnection];
	[serverConnection setRootObject:self];
	if([serverConnection registerName:CONNECTION_NAME] == NO)
		NSLog(@"Register failed");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
	/*Handle children crashing*/
	struct sigaction act;
	
	act.sa_handler = childHandler;
	act.sa_flags = SA_NOCLDWAIT;
	sigaction(SIGCHLD,  &act, NULL);
	
	[self startClient];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[client release];
	[queue release];
	[currentImporting release];
	[super dealloc];
}

- (void)relinquishHelper
{
	[client exitChild];
	[serverConnection setRootObject:nil];
	[shared autorelease];
	shared = nil;
}

- (void)startClient
{
	NSString *path = [[NSBundle bundleForClass:[SapphireImportHelper class]] pathForResource:@"ImportHelper" ofType:@""];
	const char *cpath = [path fileSystemRepresentation];
	int pid = fork();
	if(pid == 0)
	{
		const char *argv[2] = {cpath, NULL};
		execve(cpath, argv, NULL);
	}	
}

- (void)connectionDidDie:(NSNotification *)note
{
	[client release];
	client = nil;
	/*Inform that import completed (since it crashed, no update done)*/
	[self importComplete:NO];
	if(shared != nil)
		/* Don't start it again if we are shutting down*/
		[self startClient];
}

- (void)itemAdded
{
	if(!queueSuspended)
		return;
	queueSuspended = NO;
	[client startQueue];
}

- (void)importFileData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
{
	SapphireImportFile *item = [[SapphireImportFile alloc] initWithFile:file informer:inform  type:IMPORT_TYPE_FILE_DATA];
	[queue addObject:item];
	[item release];
	[self itemAdded];
}

- (void)importAllData:(id <SapphireFileMetaDataProtocol>)file inform:(id <SapphireImporterBackgroundProtocol>)inform;
{
	SapphireImportFile *item = [[SapphireImportFile alloc] initWithFile:file informer:inform  type:IMPORT_TYPE_ALL_DATA];
	[queue addObject:item];
	[item release];
	[self itemAdded];
}

- (void)removeObjectsWithInform:(id <SapphireImporterBackgroundProtocol>)inform
{
	if(inform == nil)
		return;
	
	int i, count=[queue count];
	for(i=0; i<count; i++)
	{
		id <SapphireImportFileProtocol> file = [queue objectAtIndex:i];
		if([file informer] == inform)
		{
			[queue removeObjectAtIndex:i];
			i--;
			count--;
		}
	}
}

- (id <SapphireImportFileProtocol>)nextFile
{
	if(![queue count])
	{
		queueSuspended = YES;
		return nil;
	}
	[currentImporting release];
	currentImporting = [[queue objectAtIndex:0] retain];
	[queue removeObjectAtIndex:0];
	return currentImporting;
}

- (oneway void)setClient:(id <SapphireImportClient>)aClient
{
	if(shared == nil)
	{
		[aClient exitChild];
		return;
	}
	client = [aClient retain];
	if([queue count])
	{
		queueSuspended = NO;
		[client startQueue];
	}
}

- (oneway void)importComplete:(BOOL)updated
{
	[[currentImporting informer] informComplete:updated];
	[currentImporting release];
	currentImporting = nil;
}

@end

@implementation SapphireImportFile
- (id)initWithFile:(id <SapphireFileMetaDataProtocol>)aFile informer:(id <SapphireImporterBackgroundProtocol>)aInformer type:(ImportType)aType
{
	self = [super init];
	if(!self)
		return nil;
	
	file = [aFile retain];
	informer = [aInformer retain];
	type = aType;
	
	return self;
}
- (void) dealloc
{
	[file release];
	[informer release];
	[super dealloc];
}

- (id <SapphireFileMetaDataProtocol>)file
{
	return file;
}
- (id <SapphireImporterBackgroundProtocol>)informer
{
	return informer;
}

- (ImportType)importType
{
	return type;
}

@end
