/*
 * SapphireDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 13, 2008.
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

#import "SapphireDirectory.h"
#import "SapphireFileMetaData.h"
#import "SapphireMetaDataSupport.h"

NSString *VIRTUAL_DIR_ROOT_PATH =			@"@MOVIES";
NSString *VIRTUAL_DIR_ALL_PATH =			@"@MOVIES/All Movies";
NSString *VIRTUAL_DIR_CAST_PATH =			@"@MOVIES/By Cast";
NSString *VIRTUAL_DIR_DIRECTOR_PATH =		@"@MOVIES/By Director";
NSString *VIRTUAL_DIR_GENRE_PATH =			@"@MOVIES/By Genre";
NSString *VIRTUAL_DIR_TOP250_PATH =			@"@MOVIES/IMDB Top 250";
NSString *VIRTUAL_DIR_OSCAR_PATH =			@"@MOVIES/Academy Award Winning";

void doSubtreeInvocation(id <SapphireDirectory> dir, SEL select, id object)
{
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[SapphireFileMetaData class] instanceMethodSignatureForSelector:select]];
	[inv setSelector:select];
	if(object != nil)
		[inv setArgument:&object atIndex:2];
	[dir invokeOnAllFiles:inv];
	[SapphireMetaDataSupport save:[dir managedObjectContext]];
}

void setSubtreeToWatched(id <SapphireDirectory> dir, BOOL watched)
{
	SEL select = @selector(setWatched:);
	doSubtreeInvocation(dir, select, [NSNumber numberWithBool:watched]);
}

void setSubtreeToFavorite(id <SapphireDirectory> dir, BOOL favorite)
{
	SEL select = @selector(setFavorite:);
	doSubtreeInvocation(dir, select, [NSNumber numberWithBool:favorite]);
}

void setSubtreeToReimportFromMask(id <SapphireDirectory> dir, int mask)
{
	SEL select = @selector(setToReimportFromMask:);
	doSubtreeInvocation(dir, select, [NSNumber numberWithInt:mask]);
}

void setSubtreeToClearMetaData(id <SapphireDirectory> dir)
{
	SEL select = @selector(clearMetaData);
	doSubtreeInvocation(dir, select, nil);
}

void setSubtreeToResetImportDecisions(id <SapphireDirectory> dir)
{
	SEL select = @selector(setToResetImportDecisions);
	doSubtreeInvocation(dir, select, nil);
}