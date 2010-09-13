/*
 * SapphireFileDataImporter.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 24, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireFileDataImporter.h"
#import "SapphireFileMetaData.h"
#import "SapphireImportHelper.h"
#import "SapphireJoinedFile.h"

#import <QTKit/QTKit.h>

@implementation SapphireFileDataImporter

- (void)setDelegate:(id <SapphireImporterDelegate>)aDelegate
{
	delegate = aDelegate;
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	/*Import file if necessary*/
	if([metaData needsUpdating])
	{
		if([[path pathExtension] isEqualToString:@"mov"])
		{
			//Find all references to see if this is a joined movie.
			NSError *error = nil;
			QTMovie *movie = [QTMovie movieWithFile:path error:&error];
			NSMutableSet *filePaths = [NSMutableSet set];
			NSArray *tracks = [movie tracks];
			int trackCount = [tracks count];
			int i;
			for(i=0; i<trackCount; i++)
			{
				QTTrack *track = [tracks objectAtIndex:i];
				QTMedia *media = [track media];
				if(media != nil)
				{
					Media qtMedia = [media quickTimeMedia];
					short count;
					GetMediaDataRefCount(qtMedia, &count);
					int i;
					for(i=0; i<count; i++)
					{
						Handle dataRef;
						OSType dataRefType;
						long dataRefAttrs;
						if(GetMediaDataRef(qtMedia, i, &dataRef, &dataRefType, &dataRefAttrs) == noErr && dataRefType == AliasDataHandlerSubType)
						{
							CFStringRef outPath;
							if(QTGetDataReferenceFullPathCFString(dataRef, dataRefType, (QTPathStyle)kQTNativeDefaultPathStyle, &outPath) == noErr)
							{
								[filePaths addObject:(NSString *)outPath];
								CFRelease(outPath);
							}
							DisposeHandle(dataRef);
						}
					}
				}
			}
			[filePaths removeObject:path];
			SapphireJoinedFile *joined = [metaData joinedFile];
			if([filePaths count])
			{
				NSManagedObjectContext *moc = [metaData managedObjectContext];
				//This is a joined file
				if(joined == nil)
					joined = [SapphireJoinedFile joinedFileForPath:path inContext:moc];
				NSEnumerator *pathEnum = [filePaths objectEnumerator];
				NSString *otherPath;
				while((otherPath = [pathEnum nextObject]) != nil)
					[joined addJoinedFilesObject:[SapphireFileMetaData createFileWithPath:otherPath inContext:moc]];
			}
			else if(joined != nil)
				//This is not a joined file, so mark as such
				[metaData setJoinedFile:nil];
		}
		if([[SapphireImportHelper sharedHelperForContext:[metaData managedObjectContext]] importFileData:metaData inform:self])
			return ImportStateUpdated;
		else
			return ImportStateBackground;
	}
	/*Return whether we imported or not*/
	return ImportStateNotUpdated;
}

- (void)cancelImports
{
	//XXX  The context here is nil.  We know it'll be alloced before here by the above
	[[SapphireImportHelper sharedHelperForContext:nil] removeObjectsWithInform:self];
}

- (NSString *)completionText
{
	return BRLocalizedString(@"Sapphire will continue to import new files as it encounters them.  You may initiate this import again at any time, and any new or changed files will be imported", @"End text after import of files is complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Populate File Data", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will populate Sapphire's File data.  This procedure may take a while, but you may cancel at any time.", @"Description of the import processes");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Populating Data", @"Button");
}

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	//No choosers displayed
	return NO;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
}

- (void)realInformComplete:(NSArray *)status
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *path = [status objectAtIndex:1];
	NSNumber *fileUpdated = [status objectAtIndex:0];
	ImportState state = ImportStateNotUpdated;
	if([fileUpdated boolValue])
		state = ImportStateUpdated;
	[delegate backgroundImporter:self completedImportOnPath:path withState:state];
	[pool drain];
}

- (oneway void)informComplete:(BOOL)fileUpdated onPath:(NSString *)path
{
	NSArray *status = [NSArray arrayWithObjects:[NSNumber numberWithBool:fileUpdated], path, nil];
	[self performSelectorOnMainThread:@selector(realInformComplete:) withObject:status waitUntilDone:NO];
}
@end
