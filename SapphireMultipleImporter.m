//
//  SapphireMultipleImporter.m
//  Sapphire
//
//  Created by Graham Booker on 8/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMultipleImporter.h"


@implementation SapphireMultipleImporter

/*!
 * @brief Creates a new importer set
 *
 * @param importerList The list of importers to use
 * @return The importer if successful, nil otherwise
 */
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

/*!
 * @brief Import a single File
 *
 * @param metaData The file to import
 * @return YES if imported, NO otherwise
 */
- (BOOL)importMetaData:(SapphireFileMetaData *)metaData
{
	BOOL ret = NO;
	NSEnumerator *importEnum = [importers objectEnumerator];
	id <SapphireImporter> importer = nil;
	while((importer = [importEnum nextObject]) != nil)
		ret |= [importer importMetaData:metaData];
	
	return ret;
}

/*!
 * @brief Sets the importer's data menu
 *
 * @param theDataMenu The importer's menu
 */
- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[importers makeObjectsPerformSelector:@selector(setImporterDataMenu:) withObject:theDataMenu];
}

/*!
* @brief The completion text to display
 *
 * @return The completion text to display
 */
- (NSString *)completionText
{
	return @"";
}

/*!
* @brief The initial text to display
 *
 * @return The initial text to display
 */
- (NSString *)initialText
{
	return @"";
}

/*!
* @brief The informative text to display
 *
 * @return The informative text to display
 */
- (NSString *)informativeText
{
	return @"";
}

/*!
* @brief The button title
 *
 * @return The button title
 */
- (NSString *)buttonTitle
{
	return @"";
}

/*!
* @brief The data menu was exhumed
 *
 * @param controller The Controller which was on top
 */
- (void) wasExhumedByPoppingController:(BRLayerController *) controller
{
	[importers makeObjectsPerformSelector:@selector(wasExhumedByPoppingController:) withObject:controller];
}

@end
