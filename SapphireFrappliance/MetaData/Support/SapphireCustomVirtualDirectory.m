/*
 * SapphireCustomVirtualDirectory.m
 * Sapphire
 *
 * Created by mjacobsen on Oct. 2, 2009.
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

#import "SapphireCustomVirtualDirectory.h"

@implementation SapphireCustomVirtualDirectory

- (void) dealloc
{
	[title release];
	[description release];
	[predicate release];
	[super dealloc];
}

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[SapphireCustomVirtualDirectory class]])
	{
		SapphireCustomVirtualDirectory *other = (SapphireCustomVirtualDirectory *)object;
		
		if(![other->title isEqualToString:title])
			return NO;
		
		if(![other->predicate isEqual:predicate])
			return NO;
		
		return YES;
	}
	return NO;
}

- (NSString *)title
{
	return title;
}

- (NSString *)description
{
	return description;
}

- (NSPredicate *)predicate
{
	return predicate;
}

- (void)setTitle:(NSString*)newTitle
{
	[title autorelease];
	title = [newTitle retain];
}

- (void)setDescription:(NSString*)newDescription
{
	[description autorelease];
	description = [newDescription retain];
}

- (void)setPredicate:(NSPredicate*)newPredicate
{
	[predicate autorelease];
	predicate = [newPredicate retain];
}
@end
