/*
 * SapphirePredicates.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 23, 2007.
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

#import "SapphirePredicates.h"
#import "SapphireMetaData.h"

@implementation SapphirePredicate

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData
{
	return NO;
}

@end

@implementation SapphireUnwatchedPredicate

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData
{
	if(metaData == nil)
		return YES;
	else if(![metaData watched])
		return YES;
	return NO;
}

@end

@implementation SapphireFavoritePredicate

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData
{

	if(metaData == nil)
		return NO;
	else if([metaData favorite])
		return YES;
	return NO;

}

@end

@implementation SapphireTopShowPredicate

- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData
{
/*
	if(metaData == nil)
		return YES;
	else if(![metaData topShow])
		return YES;
	return NO;
*/
	return YES ;
}

@end
