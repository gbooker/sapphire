//
//  SapphireImporterDataMenu.h
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMetaData.h"
#import "SapphireLayerController.h"

@class SapphireImporterDataMenu;

/*!
 * @brief The importer protocol
 *
 * This protocol is the basic functionality that all importers must implement.  Through this, a common UI can implement all the importers.
 */
@protocol SapphireImporter <NSObject>

/*!
 * @brief Import a single File
 *
 * @param metaData The file to import
 * @return YES if imported, NO otherwise
 */
- (BOOL)importMetaData:(SapphireFileMetaData *)metaData;

/*!
 * @brief Sets the importer's data menu
 *
 * This is the text to display under the title, stating that the importer is done.
 *
 * @param theDataMenu The importer's menu
 */
- (void)setImporterDataMenu:(SapphireImporterDataMenu *)theDataMenu;

/*!
 * @brief The completion text to display
 *
 * @return The completion text to display
 */
- (NSString *)completionText;

/*!
 * @brief The initial text to display
 *
 * This is the initial text to display in the title.
 *
 * @return The initial text to display
 */
- (NSString *)initialText;

/*!
 * @brief The informative text to display
 *
 * This is the text to display under the title, describing what this importer will do.
 *
 * @return The informative text to display
 */
- (NSString *)informativeText;

/*!
 * @brief The button title
 *
 * This text is displayed in the button before the user starts.  The button is hidden after completion, so there are no other functions for this text.
 *
 * @return The button title
 */
- (NSString *)buttonTitle;

/*!
 * @brief The data menu was exhumed
 *
 * Some importers present the user with other choices, so this lets the importer know that the "dialog" has completed.
 *
 * @param controller The Controller which was on top
 */
- (void) wasExhumedByPoppingController: (BRLayerController *) controller;
@end

@interface SapphireImporterDataMenu : SapphireLayerController <SapphireMetaDataScannerDelegate>
{
	BRHeaderControl					*title;
	BRButtonControl					*button;
	BRTextControl					*text;
	BRTextControl					*fileProgress;
	BRTextControl					*currentFile;
	BRProgressBarWidget				*bar;

	SapphireMetaDataCollection		*metaCollection;
	NSMutableArray					*collectionDirectories;
	int								collectionIndex;
	NSMutableArray					*importItems;
	NSTimer							*importTimer;
	float							max;
	float							current;
	float							updated ;
	BOOL							suspended;
	BOOL							canceled;
	
	id <SapphireImporter>			importer;
}
- (id) initWithScene: (BRRenderScene *) scene metaDataCollection:(SapphireMetaDataCollection *)collection  importer:(id <SapphireImporter>)import;
- (void)getItems;
@end

@interface SapphireImporterDataMenu (protectedAccess)
- (void)setText:(NSString *)theText;
- (void)setFileProgress:(NSString *)updateFileProgress;
- (void)resetUIElements;
- (void)importNextItem:(NSTimer *)timer;
- (void)setCurrentFile:(NSString *)theCurrentFile;
- (void)pause;
- (void)resume;
- (void)skipNextItem;
@end
