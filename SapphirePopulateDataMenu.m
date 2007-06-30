//
//  SapphirePopulateDataMenu.m
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphirePopulateDataMenu.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"

@interface SapphireImporterDataMenu (private)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)importNextItem:(NSTimer *)timer;
- (void)setCurrentFile:(NSString *)theCurrentFile;
@end

@implementation SapphirePopulateDataMenu
- (void)getItems
{
	importItems = [[meta subFileMetas] mutableCopy];
}

- (BOOL)doImport
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	return [fileMeta updateMetaData];
}

- (void)setCompletionText
{
	[self setText:@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported"];
}

- (void)importNextItem:(NSTimer *)timer
{
	SapphireFileMetaData *fileMeta = [importItems objectAtIndex:0];
	NSString * fileName=[[fileMeta path] lastPathComponent] ;
	[self setCurrentFile:[NSString stringWithFormat:@"Current File: %@",fileName]];
	[super importNextItem:timer];
}

- (void)resetUIElements
{
	[super resetUIElements];
	[title setTitle: @"Populate Show Data"];
	[self setText:@"This will populate Sapphire's Meta data.  This proceedure may take a while, but you may cancel at any time"];
	[button setTitle: @"Import Meta Data"];
}
@end
