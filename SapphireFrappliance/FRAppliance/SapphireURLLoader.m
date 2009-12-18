/*
 * SapphireURLLoader.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 10 2009.
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

#import "SapphireURLLoader.h"

#define MAX_WORKERS		10

@interface SapphireURLLoaderWorker : NSObject
{
	NSURL				*url;
	NSMutableArray		*informers;
	BOOL				loaded;
}

- (id)initWithURL:(NSURL *)url;
- (void)loadData;
- (void)addInformer:(NSInvocation *)invoke;
- (id)loadedObject;

@end

@interface SapphireStringURLLoaderWorker : SapphireURLLoaderWorker
{
	NSString			*loadedString;
}
@end

@interface SapphireDataURLLoaderWorker : SapphireURLLoaderWorker
{
	NSData			*loadedData;
}
@end

@interface SapphireDataURLToFileWorker : NSObject
{
	NSString		*path;
}
- (id)initWithPath:(NSString *)aPath;
@end



@implementation SapphireURLLoaderWorker

- (id)initWithURL:(NSURL *)aUrl
{
	self = [super init];
	if(!self)
		return self;
	
	url = [aUrl retain];
	informers = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc
{
	[url release];
	[informers release];
	[super dealloc];
}

- (void)tellInformers
{
	NSEnumerator *invokeEnum = [informers objectEnumerator];
	NSInvocation *invoke;
	id loadedObject = [self loadedObject];
	while((invoke = [invokeEnum nextObject]) != nil)
	{
		[invoke setArgument:&loadedObject atIndex:2];
		[invoke invoke];
	}
	[informers release];
	informers = nil;
	[url release];
	url = nil;
}

- (void)realLoadData
{
}

- (id)loadedObject
{
	return nil;
}

- (void)loadData
{
	[NSThread detachNewThreadSelector:@selector(realLoadData) toTarget:self withObject:nil];
}

- (void)addInformer:(NSInvocation *)invoke
{
	if(loaded)
	{
		id loadedObject = [self loadedObject];
		[invoke setArgument:&loadedObject atIndex:2];
		[invoke invoke];
	}
	else
		[informers addObject:invoke];
}

@end

@implementation SapphireStringURLLoaderWorker

- (void)dealloc
{
	[loadedString release];
	[super dealloc];
}


- (void)realLoadData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	NSStringEncoding encoding;
	
	loadedString = [[NSString alloc] initWithContentsOfURL:url usedEncoding:&encoding error:&error];
	loaded = YES;
	[self performSelectorOnMainThread:@selector(tellInformers) withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (id)loadedObject
{
	return loadedString;
}

@end

@implementation SapphireDataURLLoaderWorker

- (void)dealloc
{
	[loadedData release];
	[super dealloc];
}


- (void)realLoadData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	loadedData = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
	loaded = YES;
	[self performSelectorOnMainThread:@selector(tellInformers) withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (id)loadedObject
{
	return loadedData;
}

@end

@implementation SapphireDataURLToFileWorker

- (id)initWithPath:(NSString *)aPath
{
	self = [super init];
	if(!self)
		return self;
	
	path = [aPath retain];
	
	return self;
}

- (void)dealloc
{
	[path release];
	[super dealloc];
}

- (void)dataLoaded:(NSData *)data
{
	if(![data length])
		//Some failure, oh well
		return;
	
	[data writeToFile:path atomically:YES];
}

@end



@implementation SapphireURLLoader

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	workers = [[NSMutableDictionary alloc] init];
	workerQueue = [[NSMutableArray alloc] init];
	myInformer = [[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(workerFinished:)]] retain];
	[myInformer setTarget:self];
	[myInformer setSelector:@selector(workerFinished:)];
	
	return self;
}

- (void) dealloc
{
	[workers release];
	[workerQueue release];
	[myInformer release];
	[super dealloc];
}

- (void)addWorkerToQueue:(SapphireURLLoaderWorker *)worker
{
	if(workersCurrentlyWorking < MAX_WORKERS)
	{
		[worker loadData];
		workersCurrentlyWorking++;
	}
	else
		[workerQueue addObject:worker];
	
	[worker addInformer:myInformer];
}

- (void)workerFinished:(SapphireURLLoaderWorker *)worker
{
	if(workersCurrentlyWorking == MAX_WORKERS && [workerQueue count])
	{
		SapphireURLLoaderWorker *newWorker = [workerQueue objectAtIndex:0];
		[newWorker loadData];
		[workerQueue removeObjectAtIndex:0];
	}
	else
		workersCurrentlyWorking--;
}

- (void)addCallbackToWorker:(SapphireURLLoaderWorker *)worker withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invoke retainArguments];
	[invoke setTarget:target];
	[invoke setSelector:selector];
	if(anObject != nil)
		[invoke setArgument:&anObject atIndex:3];
	
	[worker addInformer:invoke];
}

- (void)loadStringURL:(NSString *)url withCache:(NSString *)cache withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSString *key = [@"S" stringByAppendingString:cache];
	SapphireStringURLLoaderWorker *worker = [workers objectForKey:key];
	if(worker == nil)
	{
		worker = [[SapphireStringURLLoaderWorker alloc] initWithURL:[NSURL URLWithString:url]];
		[workers setObject:worker forKey:key];
		[worker release];
		[self addWorkerToQueue:worker];
	}
	
	[self addCallbackToWorker:worker withTarget:target selector:selector object:anObject];
}

- (void)loadDataURL:(NSString *)url withCache:(NSString *)cache withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSString *key = [@"D" stringByAppendingString:cache];
	SapphireDataURLLoaderWorker *worker = [workers objectForKey:key];
	if(worker == nil)
	{
		worker = [[SapphireDataURLLoaderWorker alloc] initWithURL:[NSURL URLWithString:url]];
		[workers setObject:worker forKey:key];
		[worker release];
		[self addWorkerToQueue:worker];
	}
	
	[self addCallbackToWorker:worker withTarget:target selector:selector object:anObject];
}

- (void)saveDataAtURL:(NSString *)url toFile:(NSString *)path
{
	SapphireDataURLToFileWorker *worker = [[SapphireDataURLToFileWorker alloc] initWithPath:path];
	
	[self loadDataURL:url withCache:url withTarget:worker selector:@selector(dataLoaded:) object:nil];
	
	[worker release];
}

@end
