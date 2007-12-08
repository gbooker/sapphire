//
//  SapphireAllImporter.m
//  Sapphire
//
//  Created by Graham Booker on 8/6/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireAllImporter.h"


@implementation SapphireAllImporter

- (BOOL)importMetaData:(SapphireFileMetaData *)metaData
{
	return [super importMetaData:metaData];
}

- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu
{
	[super setImporterDataMenu:theDataMenu];
}

- (NSString *)completionText
{
	return BRLocalizedString(@"All available metadata has been imported", @"The group metadata import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Import All Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will import all the metadata it can find.  This procedure may take quite some time and could ask you questions.  You may cancel at any time.", @"Description of all meta import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Importing Data", @"Button");
}

- (void) wasExhumedByPoppingController:(BRLayerController *) controller
{
	[super wasExhumedByPoppingController:controller];
}

@end
