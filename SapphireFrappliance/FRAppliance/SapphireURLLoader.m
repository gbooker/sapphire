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
#import "NSFileManager-Extensions.h"
#import "SapphireApplianceController.h"

#define MAX_WORKERS		10

@interface SapphireURLLoaderWorker : NSObject
{
	NSURL				*url;
	NSMutableArray		*informers;
	BOOL				loaded;
}

- (id)initWithURL:(NSURL *)url;
- (NSString *)urlKey;
- (void)loadData;
- (void)addInformer:(NSInvocation *)invoke;
- (BOOL)loaded;
- (BOOL)failed;
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

- (NSString *)urlKey
{
	return [url absoluteString];
}

- (void)tellInformers
{
	loaded = YES;
	@try {
		NSEnumerator *invokeEnum = [informers objectEnumerator];
		NSInvocation *invoke;
		id loadedObject = [self loadedObject];
		while((invoke = [invokeEnum nextObject]) != nil)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[invoke setArgument:&loadedObject atIndex:2];
			[invoke invoke];
			[pool drain];
		}
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	@finally {
		[informers release];
		informers = nil;
		[url release];
		url = nil;		
	}
}

- (void)realLoadData
{
}

- (void)loadLoop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i;
	for(i=0; i<3; i++)
	{
		[self realLoadData];
		if(![self failed])
			break;
	}
	[self performSelectorOnMainThread:@selector(tellInformers) withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (BOOL)loaded
{
	return loaded;
}

- (BOOL)failed
{
	return NO;
}

- (id)loadedObject
{
	return nil;
}

- (void)loadData
{
	[NSThread detachNewThreadSelector:@selector(loadLoop) toTarget:self withObject:nil];
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
	int i;
	for(i=0; i<[informers count]; i++)
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

- (NSString *)urlKey
{
	return [@"S" stringByAppendingString:[url absoluteString]];
}

- (void)realLoadData
{
	NSError *error = nil;
	
	if(url != nil)
	{
		NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
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
				if(loadedString == nil)
					//Fallback in last ditch effort because we have to still handle more moronic things that TVRage does.
					loadedString = [[NSString alloc] initWithData:mutData encoding:NSISOLatin1StringEncoding];
				[mutData release];
			}
		}
	}
	if(![loadedString length])
		NSLog(@"Load of %@ failed with error %@!!!", url, error);
}

- (id)loadedObject
{
	return loadedString;
}

- (BOOL)failed
{
	return [loadedString length] == 0;
}

@end

@implementation SapphireDataURLLoaderWorker

- (void)dealloc
{
	[loadedData release];
	[super dealloc];
}

- (NSString *)urlKey
{
	return [@"D" stringByAppendingString:[url absoluteString]];
}

- (void)realLoadData
{
	NSError *error = nil;
	
	if(url != nil)
		loadedData = [[NSData alloc] initWithContentsOfURL:url options:NSUncachedRead error:&error];
}

- (id)loadedObject
{
	return loadedData;
}

- (BOOL)failed
{
	return [loadedData length] == 0;
}

@end

@interface SapphireURLLoader ()
- (void)addCallbackToWorker:(SapphireURLLoaderWorker *)worker withTarget:(id)target selector:(SEL)selector object:(id)anObject;
@end


@implementation SapphireURLLoader

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	workers = [[NSMutableDictionary alloc] init];
	workerQueue = [[NSMutableArray alloc] init];
	priorityWorkerQueue = [[NSMutableArray alloc] init];
	delegates = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) dealloc
{
	[workers release];
	[workerQueue release];
	[priorityWorkerQueue release];
	[clearTimer invalidate];
	[delegates release];
	[super dealloc];
}

- (void)addWorkerToQueue:(SapphireURLLoaderWorker *)worker withPriority:(BOOL)priority
{
	if(workersCurrentlyWorking < MAX_WORKERS)
	{
		[self addCallbackToWorker:worker withTarget:self selector:@selector(loadedData:fromWorker:) object:worker];
		[worker loadData];
		workersCurrentlyWorking++;
	}
	else if(priority)
		[priorityWorkerQueue addObject:worker];
	else
		[workerQueue addObject:worker];
	[delegates makeObjectsPerformSelector:@selector(urlLoaderAddedResource:) withObject:self];
}

- (void)loadedData:(id)obj fromWorker:(SapphireURLLoaderWorker *)worker
{
	int priorityCount = [priorityWorkerQueue count];
	if(workersCurrentlyWorking == MAX_WORKERS && (priorityCount || [workerQueue count]))
	{
		SapphireURLLoaderWorker *newWorker;
		if(priorityCount)
			newWorker = [priorityWorkerQueue objectAtIndex:0];
		else
			newWorker = [workerQueue objectAtIndex:0];
		[self addCallbackToWorker:newWorker withTarget:self selector:@selector(loadedData:fromWorker:) object:newWorker];
		[newWorker loadData];
		if(priorityCount)
			[priorityWorkerQueue removeObjectAtIndex:0];
		else
			[workerQueue removeObjectAtIndex:0];
	}
	else
		workersCurrentlyWorking--;
	[delegates makeObjectsPerformSelector:@selector(urlLoaderFinisedResource:) withObject:self];
	if([worker failed])
	{
		[workers removeObjectForKey:[worker urlKey]];
	}
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
		[self addWorkerToQueue:worker withPriority:NO];
	}
	
	[self addCallbackToWorker:worker withTarget:target selector:selector object:anObject];
}

- (void)loadDataURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject
{
	[self loadDataURL:url withTarget:target selector:selector object:anObject withPriority:NO];
}
- (void)loadDataURL:(NSString *)url withTarget:(id)target selector:(SEL)selector object:(id)anObject withPriority:(BOOL)priority
{
	NSString *key = [@"D" stringByAppendingString:url];
	SapphireDataURLLoaderWorker *worker = [workers objectForKey:key];
	if(worker == nil)
	{
		worker = [[SapphireDataURLLoaderWorker alloc] initWithURL:[NSURL URLWithString:url]];
		[workers setObject:worker forKey:key];
		[worker release];
		[self addWorkerToQueue:worker withPriority:priority];
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
	[[NSFileManager defaultManager] constructPath:[path stringByDeletingLastPathComponent]];
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
		[priorityWorkerQueue removeObject:worker];
		[workers removeObjectForKey:key];
		[delegates makeObjectsPerformSelector:@selector(urlLoaderCancelledResource:) withObject:self];
	}
	key = [@"S" stringByAppendingString:url];
	worker = [workers objectForKey:key];
	if(![worker loaded] && ![worker cancelForTarget:target])
	{
		//Worker is no longer needed
		[workerQueue removeObject:worker];
		[priorityWorkerQueue removeObject:worker];
		[workers removeObjectForKey:key];
		[delegates makeObjectsPerformSelector:@selector(urlLoaderCancelledResource:) withObject:self];
	}
}

- (void)addDelegate:(id <SapphireURLLoaderDelegate>)delegate
{
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id <SapphireURLLoaderDelegate>)delegate
{
	[delegates removeObject:delegate];
}

- (int)loadingURLCount
{
	return workersCurrentlyWorking + [workerQueue count] + [priorityWorkerQueue count];
}

@end
