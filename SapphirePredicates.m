//
//  SapphirePredicates.m
//  Sapphire
//
//  Created by Graham Booker on 6/23/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

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
