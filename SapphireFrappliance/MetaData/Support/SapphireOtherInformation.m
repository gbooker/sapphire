/*
 * SapphireOtherInformationImplementation.h
 * Sapphire
 *
 * Created by Graham Booker on Jul. 2, 2009.
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

#import "SapphireOtherInformation.h"

#define otherInformationKey @"otherProperties"
#define otherInformationDataKey @"otherPropertiesData"

@implementation NSManagedObject (otherInformation)

- (NSDictionary *)otherInformation
{
	[self willAccessValueForKey:otherInformationKey];
	NSDictionary *ret = [self primitiveValueForKey:otherInformationKey];
	[self didAccessValueForKey:otherInformationKey];
	if(ret == nil)
	{
		NSData *propData = [self valueForKey:otherInformationDataKey];
		if(propData != nil)
		{
			ret = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
			[self setPrimitiveValue:ret forKey:otherInformationKey];
		}
	}
	return ret;
}

- (void)setOtherInformation:(NSDictionary *)info
{
	[self willChangeValueForKey:otherInformationKey];
	[self setPrimitiveValue:info forKey:otherInformationKey];
	[self didChangeValueForKey:otherInformationKey];
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:info] forKey:otherInformationDataKey];
}

- (void)setOtherObject:(id)obj forKey:(id)key
{
	NSMutableDictionary *mutOther = [[self otherInformation] mutableCopy];
	[mutOther setObject:obj forKey:key];
	NSDictionary *dict = [mutOther copy];
	[self setOtherInformation:dict];
	[dict release];
	[mutOther release];
}

- (void)removeOtherObjectForKey:(id)key
{
	NSMutableDictionary *mutOther = [[self otherInformation] mutableCopy];
	[mutOther removeObjectForKey:mutOther];
	NSDictionary *dict = [mutOther copy];
	[self setOtherInformation:dict];
	[dict release];
	[mutOther release];
}

- (id)otherInformationForKey:(id)key
{
	return [[self otherInformation] objectForKey:key];
}

@end