//
//  SapphireMultipleImporter.m
//  Sapphire
//
//  Created by Graham Booker on 8/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMultipleImporter.h"


@implementation SapphireMultipleImporter

- (id)initWithImporters:(NSArray *)importerList
{
	self = [super init];
	if(self == nil)
		return nil;
	
	importers = [importerList retain];
	
	return self;
}

- (void) dealloc
{
	[importers release];
	[super dealloc];
}

- (BOOL)importMetaData:(SapphireFileMetaData *)metaData
{
	BOOL ret = NO;
	NSEnumerator *importEnum = [importers objectEnumerator];
	id <SapphireImporter> importer = nil;
	while((importer = [importEnum nextObject]) != nil)
		ret |= [importer importMetaData:metaData];
	
	return ret;
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[importers makeObjectsPerformSelector:@selector(setImporterDataMenu:) withObject:theDataMenu];
}

- (NSString *)completionText
{
	return @"";
}

- (NSString *)initialText
{
	return @"";
}

- (NSString *)informativeText
{
	return @"";
}

- (NSString *)buttonTitle
{
	return @"";
}

- (void) wasExhumedByPoppingController:(BRLayerController *) controller
{
	[importers makeObjectsPerformSelector:@selector(wasExhumedByPoppingController:) withObject:controller];
}

@end
