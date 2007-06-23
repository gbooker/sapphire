//
//  SapphirePredicates.m
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphirePredicates.h"
#import "SapphireMetaData.h"

@implementation SapphirePredicates

@end

BOOL unwatchedPredicate(NSString *path, SapphireFileMetaData *metaData)
{
	if(metaData == nil)
		return YES;
	else if(![metaData watched])
		return YES;
	return NO;
}