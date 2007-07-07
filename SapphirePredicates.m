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

/*!
 * @brief States whether we should accept this file or not
 *
 * @param path The file's path
 * @param metaData The file's meta data if it exists, nil otherwise
 * @return YES if the file is accepted by the predicate, NO otherwise
 */
- (BOOL)accept:(NSString *)path meta:(SapphireFileMetaData *)metaData
{
	return NO;
}

@end

@implementation SapphireUnwatchedPredicate

/*See super documentation*/
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

/*See super documentation*/
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

/*See super documentation*/
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
