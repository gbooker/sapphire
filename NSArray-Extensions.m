//
//  NSArray-Extensions.m
//  Sapphire
//
//  Created by Graham Booker on 12/18/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "NSArray-Extensions.h"

@implementation NSMutableArray (extensions)
- (void)uniqueObjects
{
	int i, count = [self count];
	NSMutableSet *uniquer = [NSMutableSet new];
	for(i=0; i<count; i++)
	{
		id obj = [self objectAtIndex:i];
		if([uniquer containsObject:obj])
		{
			[self removeObjectAtIndex:i];
			i--;
			count--;
		}
		else
			[uniquer addObject:obj];
	}
	[uniquer release];
}
@end

