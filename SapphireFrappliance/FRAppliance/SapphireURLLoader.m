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
- (BOOL)loaded;
- (id)loadedObject;
- (int)cancelForTarget:(id)target;

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

- (BOOL)loaded
{
	return loaded;
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

- (int)cancelForTarget:(id)target
{
	for(int i=0; i<[informers count]; i++)
	{
		NSInvocation *invoke = [informers objectAtIndex:i];
		if([invoke target] == target)
		{
			[informers removeObjectAtIndex:i];
			i--;
		}
	}
	return [informers count];
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
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	NSURLResponse *response = nil;
	NSData *documentData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(error == nil)
	{	
		NSStringEncoding responseEncoding = NSISOLatin1StringEncoding;
		NSString *encodingName = [response textEncodingName];
		if([encodingName length])
			responseEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
		loadedString = [[NSString alloc] initWithData:documentData encoding:responseEncoding];
		if(loadedString == nil)
		{
			//Most likely this is UTF-8 and some moron doesn't understand that the meta tags need to follow the same encoding.
			NSMutableData *mutData = [documentData mutableCopy];
			int length = [mutData length];
			const char *bytes = [mutData bytes];
			const char *location;
			while((location = strnstr(bytes, "<meta", length)) != NULL)
			{
				int offset = location - bytes;
				const char *end = strnstr(location, ">", length-offset);
				if(end != NULL)
				{
					int replaceLength = end-location+2;
					[mutData replaceBytesInRange:NSMakeRange(offset, replaceLength) withBytes:"" length:0];
					bytes = [mutData bytes];
					length = [mutData length];
				}
				else
					break;
			}
			loadedString = [[NSString alloc] initWithData:mutData encoding:responseEncoding];
			[mutData release];
		}
	}
	loaded = YES;
	if(![loadedString length])
		NSLog(@"Load of %@ failed with error %@!!!", url, error);
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
	
	loadedData = [[NSData alloc] initWithContentsOfURL:url options:NSUncachedRead error:&error];
	loaded = YES;
	[self performSelectorOnMainThread:@selector(tellInformers) withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (id)loadedObject
{
	return loadedData;
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
	[clearTimer invalidate];
	[super dealloc];
}

- (void)addWorkerToQueue:(SapphireURLLoaderWorker *)worker
{
	if(workersCurrentlyWorking < MAX_WORKERS)
	{
		[worker addInformer:myInformer];
		[worker loadData];
		workersCurrentlyWorking++;
	}
	else
		[workerQueue addObject:worker];
}

- (void)workerFinished:(SapphireURLLoaderWorker *)worker
{
	if(workersCurrentlyWorking == MAX_WORKERS && [workerQueue count])
	{
		SapphireURLLoaderWorker *newWorker = [workerQueue objectAtIndex:0];
		[newWorker addInformer:myInformer];
		[newWorker loadData];
		[workerQueue removeObjectAtIndex:0];
	}
	else
		workersCurrentlyWorking--;
}

- (void)clearCache
{
	clearTimer = nil;
	NSDictionary *dictCopy = [workers copy];
	NSEnumerator *keyEnum = [dictCopy keyEnumerator];
	NSString *key;
	while((key = [keyEnum nextObject]) != nil)
	{
		SapphireURLLoaderWorker *worker = [workers objectForKey:key];
		if([worker loaded])
			[workers removeObjectForKey:key];
	}
	[dictCopy release];
}

- (void)resetClearTimer
{
	[clearTimer invalidate];
	clearTimer = [NSTimer scheduledTimerWithTimeInterval:180 target:self selector:@selector(clearCache) userInfo:nil repeats:NO];
}

- (void)addCallbackToWorker:(SapphireURLLoaderWorker *)worker withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[invoke retainArguments];
	[invoke setTarget:target];
	[invoke setSelector:selector];
	if(anObject != nil)
		[invoke setArgument:&anObject atIndex:3];
	
	[self resetClearTimer];
	[worker addInformer:invoke];
}

- (void)loadStringURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSString *key = [@"S" stringByAppendingString:url];
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

- (void)loadDataURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	NSString *key = [@"D" stringByAppendingString:url];
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

- (void)saveData:(NSData *)data toFile:(NSString *)path
{
	if([data length])
		[data writeToFile:path atomically:YES];
}

- (void)saveDataAtURL:(NSString *)url toFile:(NSString *)path
{
	[self loadDataURL:url withTarget:self selector:@selector(saveData:toFile:) object:path];
}

- (void)cancelLoadOfURL:(NSString *)url forTarget:(id)target
{
	NSString *key = [@"D" stringByAppendingString:url];
	SapphireURLLoaderWorker *worker = [workers objectForKey:key];
	if(![worker loaded] && ![worker cancelForTarget:target])
	{
		//Worker is no longer needed
		[workerQueue removeObject:worker];
		[workers removeObjectForKey:key];
	}
	key = [@"S" stringByAppendingString:url];
	worker = [workers objectForKey:key];
	if(![worker loaded] && ![worker cancelForTarget:target])
	{
		//Worker is no longer needed
		[workerQueue removeObject:worker];
		[workers removeObjectForKey:key];
	}
}

@end
