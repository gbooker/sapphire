//
//  SapphireAllImporter.m
//  Sapphire
//
//  Created by Graham Booker on 8/6/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireAllImporter.h"


@implementation SapphireAllImporter

/*!
 * @brief Import a single File
 *
 * @param metaData The file to import
 * @return YES if imported, NO otherwise
 */
- (BOOL)importMetaData:(SapphireFileMetaData *)metaData
{
	return [super importMetaData:metaData];
}

/*!
 * @brief Sets the importer's data menu
 *
 * @param theDataMenu The importer's menu
 */
- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[super setImporterDataMenu:theDataMenu];
}

/*!
* @brief The completion text to display
 *
 * @return The completion text to display
 */
- (NSString *)completionText
{
	return BRLocalizedString(@"All availble metadata has been imported", @"The group metadata import complete");
}

/*!
* @brief The initial text to display
 *
 * @return The initial text to display
 */
- (NSString *)initialText
{
	return BRLocalizedString(@"Import All Data", @"Title");
}

/*!
* @brief The informative text to display
 *
 * @return The informative text to display
 */
- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will import all the meta data it can find.  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of all meta import");
}

/*!
* @brief The button title
 *
 * @return The button title
 */
- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Importing Data", @"Button");
}

/*!
* @brief The data menu was exhumed
 *
 * @param controller The Controller which was on top
 */
- (void) wasExhumedByPoppingController:(BRLayerController *) controller
{
	[super wasExhumedByPoppingController:controller];
}

@end
