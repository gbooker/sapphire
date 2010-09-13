/*
 * SapphireMarkMenu.m
 * Sapphire
 *
 * Created by Graham Booker on Jun. 25, 2007.
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

#import "SapphireMarkMenu.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireCollectionDirectory.h"
#import "SapphireFileMetaData.h"
#import "SapphireJoinedFile.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireMediaPreview.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import <QTKit/QTKit.h>
#import "SapphireTextEntryController.h"
#import "SapphireErrorDisplayController.h"
#import "SapphireWaitDisplay.h"
#import "SapphireConfirmPrompt.h"
#import "SapphireApplianceController.h"
#import "SapphirePosterChooser.h"
#import "NSImage-Extensions.h"
#import "NSFileManager-Extensions.h"
#import "SapphireSettings.h"

BOOL allowCoverArtChange( NSString * const path )
{
	if ( [[NSFileManager defaultManager] hasVIDEO_TS:path] )
		return NO;
	
	static NSSet *disallowedFormats = nil;
	if(disallowedFormats == nil)
	{
		disallowedFormats = [[NSSet alloc] initWithObjects:@"mkv", @"flv", nil];
	}
	
	return ![disallowedFormats containsObject:[path pathExtension]];
}

@implementation SapphireMarkMenu

NSString *MARK_NAME					= @"Name";
NSString *MARK_DESCRIPTION			= @"Description";
NSString *MARK_COMMAND				= @"Command";

typedef enum {
	COMMAND_MARK_WATCHED,
	COMMAND_MARK_UNWATCHED,
	COMMAND_MARK_FAVORITE,
	COMMAND_MARK_NOT_FAVORITE,
	COMMAND_MARK_TO_REFETCH_TV,
	COMMAND_MARK_TO_REFETCH_MOVIE,
	COMMAND_MARK_TO_DELETE_METADATA,
	COMMAND_MARK_TO_RESET_IMPORT,
	COMMAND_RENAME,
	COMMAND_RENAME_TO_PRETTY,
	COMMAND_CUT_PATH,
	COMMAND_DELETE_PATH,
	COMMAND_CHANGE_ARTWORK,
	//File Only Commands
	COMMAND_MOVE_TO_AUTO_SORT,
	COMMAND_MARK_TO_JOIN,
	COMMAND_MARK_AND_JOIN,
	COMMAND_CLEAR_JOIN_MARK,
	COMMAND_JOIN,
	COMMAND_SHOW_ONLY_SUMMARY,
	//Directory Only Commands
	COMMAND_TOGGLE_SKIP,
	COMMAND_TOGGLE_COLLECTION,
	COMMAND_PASTE_PATH,
} MarkCommand;

static NSMutableArray *joinList;
static NSString *movingPath = nil;

+ (void)initialize
{
	joinList = [[NSMutableArray alloc] init];
}

- (id) initWithScene: (BRRenderScene *) scene metaData: (id <SapphireMetaData>)meta
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	/*Check to see if it is directory or file*/
	isDir = [meta conformsToProtocol:@protocol(SapphireDirectory)];
	metaData = [meta retain];
	/*Create the menu*/
	if(isDir)
	{
		marks = [[NSMutableArray alloc] initWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Rename this Directory", @"Rename a directory"), MARK_NAME,
				BRLocalizedString(@"Edit the name for this directory", @"Renaming a directory description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_RENAME], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Rename all Files to Pretty Name", @"Rename all files to a pretty name"), MARK_NAME,
				BRLocalizedString(@"Rename all files to a pretty name for those which a pretty name exists", @"Rename all files to a pretty name description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_RENAME_TO_PRETTY], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Mark All as Watched", @"Mark whole directory as watched"), MARK_NAME,
				BRLocalizedString(@"Sapphire will save this directory as watched.", @"Mark directory watched description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_WATCHED], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Unwatched", @"Mark whole directory as unwatched"), MARK_NAME,
				BRLocalizedString(@"Sapphire will save this directory as unwatched.", @"Mark directory as unwatched description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_UNWATCHED], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Favorite", @"Mark whole directory as favorite"), MARK_NAME,
				BRLocalizedString(@"Sapphire will add this directory as favorite.", @"Mark directory as favorite description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_FAVORITE], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Not Favorite", @"Mark whole directory as not favorite"), MARK_NAME,
				BRLocalizedString(@"Sapphire will remove this directory from favorites.", @"Mark directory as not favorite"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_NOT_FAVORITE], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Refetch TV Data", @"Mark whole directory to re-fetch its tv data"), MARK_NAME,
				BRLocalizedString(@"Tells Sapphire to refetch TV Show metadata for this directory the next time an import is run.", @"Mark directory to refetch tv data description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_TV], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Refetch Movie Data", @"Mark whole directory to re-fetch its movie data"), MARK_NAME,
				BRLocalizedString(@"Tells Sapphire to refetch Movie metadata for this directory the next time an import is run.", @"Mark whole directory to re-fetch its movie data"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_MOVIE], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Clear Metadata", @"Mark whole directory to delete the metadata"), MARK_NAME,
				BRLocalizedString(@"Tells Sapphire to remove all metadata for this directory.", @"Mark directory to delete metadata description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_TO_DELETE_METADATA], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"            Reset Import Decisions", @"Mark whole directory to reset import decisions"), MARK_NAME,
				BRLocalizedString(@"Tells Sapphire to forget import decisions made on files in this directory.", @"Mark directory to reset import decisions description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_MARK_TO_RESET_IMPORT], MARK_COMMAND,
				nil],
			 nil];
		id <SapphireDirectory> dirMeta = (id <SapphireDirectory>)meta;
		if([dirMeta isKindOfClass:[SapphireDirectoryMetaData class]])
		{
			SapphireCollectionDirectory *collection = [(SapphireDirectoryMetaData *)dirMeta collectionDirectory];
			if([collection isMountValue])
			{
				[marks replaceObjectAtIndex:0 withObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Rename this Collection", @"Rename a collection"), MARK_NAME,
						BRLocalizedString(@"Edit the display name for this collection", @"Rename a collection description"), MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_RENAME], MARK_COMMAND,
						nil]];
			}
			if([collection skipValue])
			{
				[marks addObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Mark Directory For Importing", @"Marks this directory to be no longer be skipped during import"), MARK_NAME,
						BRLocalizedString(@"Tells Sapphire it's okay to import from this directory.", @"Mark Directory For Importing description"), MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_TOGGLE_SKIP], MARK_COMMAND,
						nil]];
			}
			else
			{
				[marks addObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Mark this Directory to Skip Import", @"Marks this directory to be skipped during import"), MARK_NAME,
						BRLocalizedString(@"Tells Sapphire to skip this directory when importing.", @"Mark this Directory to Skip Import description"), MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_TOGGLE_SKIP], MARK_COMMAND,
						nil]];
			}
			if(![collection isMountValue])
			{
				if(collection != nil)
				{
					[marks addObject:
						[NSDictionary dictionaryWithObjectsAndKeys:
							BRLocalizedString(@"                    to Not be a Collection", @"Marks the directory to no longer be a collection"), MARK_NAME,
							BRLocalizedString(@"Tells Sapphire to remove this directory from the Collections list.", @"Marks the directory to no longer be a collection description"), MARK_DESCRIPTION,
							[NSNumber numberWithInt:COMMAND_TOGGLE_COLLECTION], MARK_COMMAND,
							nil]];
				}
				else
				{
					[marks addObject:
						[NSDictionary dictionaryWithObjectsAndKeys:
							BRLocalizedString(@"                    as a Collection", @"Marks the directory to be a collection"), MARK_NAME,
							BRLocalizedString(@"Tells Sapphire to add this directory to the Collections list.", @"Marks the directory to be a collection description"), MARK_DESCRIPTION,
							[NSNumber numberWithInt:COMMAND_TOGGLE_COLLECTION], MARK_COMMAND,
							nil]];
				}
			}
			if(![collection isMountValue])
			{
				[marks addObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Move Directory", @"Marks this directory to be moved"), MARK_NAME,
						BRLocalizedString(@"Move this directory.  Select destination later.", @"Marks this directory to be moved description"), MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_CUT_PATH], MARK_COMMAND,
						nil]];
				[marks addObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Delete Directory", @"Marks this directory to be deleted"), MARK_NAME,
						BRLocalizedString(@"Deletes this directory and its contents", @"Marks this directory to be deleted description"), MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_DELETE_PATH], MARK_COMMAND,
						nil]];
			}
			if(movingPath != nil && ![[dirMeta path] hasPrefix:movingPath])
			{
				[marks addObject:
					[NSDictionary dictionaryWithObjectsAndKeys:
						BRLocalizedString(@"Move to Here", @"Move File to within this directory"), MARK_NAME,
						[NSString stringWithFormat:BRLocalizedString(@"Move %@ to %@", @"parameter is last component of path, second is last path component of destination"), [movingPath lastPathComponent], [[meta path] lastPathComponent]], MARK_DESCRIPTION,
						[NSNumber numberWithInt:COMMAND_PASTE_PATH], MARK_COMMAND,
						nil]];
			}
		}
		else
		{
			[marks removeObjectAtIndex:0];
		}
	}
	else if([meta isKindOfClass:[SapphireFileMetaData class]])
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		NSString *watched = nil;
		NSString *watchedDesc = nil;
		MarkCommand watchedCommand = 0;
		NSString *favorite = nil;
		NSString *favoriteDesc = nil;
		MarkCommand favoriteCommand = 0;
		
		if([fileMeta watchedValue])
		{
			watched			= BRLocalizedString(@"Mark as Unwatched", @"Mark file as unwatched");
			watchedDesc		= BRLocalizedString(@"Sapphire will save this file as unwatched.", @"Mark directory watched description");
			watchedCommand	= COMMAND_MARK_UNWATCHED;
		}
		else
		{
			watched			= BRLocalizedString(@"Mark as Watched", @"Mark file as watched");
			watchedDesc		= BRLocalizedString(@"Sapphire will save this file as watched.", @"Mark directory watched description");
			watchedCommand	= COMMAND_MARK_WATCHED;
		}

		if([fileMeta favoriteValue])
		{
			favorite		= BRLocalizedString(@"        Not Favorite", @"Mark file as a favorite");
			favoriteDesc	= BRLocalizedString(@"Sapphire will remove this file from favorites.", @"Mark directory as not favorite");
			favoriteCommand	= COMMAND_MARK_NOT_FAVORITE;
		}
		else
		{
			favorite		= BRLocalizedString(@"        Favorite", @"Mark file as not a favorite");
			favoriteDesc	= BRLocalizedString(@"Sapphire will add this file as a favorite.", @"Mark directory as favorite description");
			favoriteCommand = COMMAND_MARK_FAVORITE;

		}
		marks = [[NSMutableArray alloc] initWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Rename this file", @"Rename a file"), MARK_NAME,
				BRLocalizedString(@"Move a file to another name", @"Rename file description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_RENAME], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				watched, MARK_NAME,
				watchedDesc, MARK_DESCRIPTION,
				[NSNumber numberWithInt:watchedCommand], MARK_COMMAND,
				nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				favorite, MARK_NAME,
				favoriteDesc, MARK_DESCRIPTION,
				[NSNumber numberWithInt:favoriteCommand], MARK_COMMAND,
				nil],
			nil];
		
		NSString *autoSortPath = [fileMeta autoSortPath];
		if(autoSortPath != nil && [[[fileMeta path] stringByDeletingLastPathComponent] caseInsensitiveCompare:autoSortPath] != NSOrderedSame)
		{
			[marks insertObject:
			    [NSDictionary dictionaryWithObjectsAndKeys:
				    BRLocalizedString(@"Move to Auto Sort Path", @"Moving a file to auto sort path menu title"), MARK_NAME,
					[NSString stringWithFormat:BRLocalizedString(@"Move to \"%@\"", @"Moving a file to auto sort path description; parameter is new path"), autoSortPath], MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MOVE_TO_AUTO_SORT], MARK_COMMAND,
					nil]
				atIndex:1];
		}
		NSString *prettyName = [fileMeta prettyName];
		if(prettyName != nil && [[fileMeta fileName] caseInsensitiveCompare:prettyName] != NSOrderedSame)
		{
			[marks insertObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"Rename to Pretty Name", @"Renaming to a pretty name menu title"), MARK_NAME,
					[NSString stringWithFormat:BRLocalizedString(@"Rename to \"%@\"", @"Renaming to a pretty name menu title; Parameter is new name"), prettyName], MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_RENAME_TO_PRETTY], MARK_COMMAND,
					nil]
				atIndex:1];
		}
		if([fileMeta joinedToFile] != nil)
		{
			[marks removeObjectAtIndex:0];
		}
		int importType = [fileMeta importTypeValue];
		if(importType | ImportTypeMaskTVShow)
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"        Refetch TV Data", @"Mark file to re-fetch its tv data"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to refetch TV Show metadata for this file the next time an import is run.", @"Mark file to refetch tv data description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_TV], MARK_COMMAND,
					nil]];
		}
		if(importType | ImportTypeMaskMovie)
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"        Refetch Movie Data", @"Mark file to re-fetch its movie data"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to refetch Movie metadata for this file the next time an import is run.", @"Mark file to refetch movie description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_TO_REFETCH_MOVIE], MARK_COMMAND,
					nil]];
		}
		if([fileMeta importTypeValue] != 0)
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"        Clear Metadata", @"Mark a file to delete the metadata"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to remove all metadata for this file.", @"Mark file to delete metadata description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_TO_DELETE_METADATA], MARK_COMMAND,
					nil]];
		}
		if([fileMeta fileClass] != FILE_CLASS_UNKNOWN)
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"        Reset Import Decisions", @"Mark a file to reset import decisions"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to forget import decisions made on this file.", @"Mark a file to reset import decisions description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_TO_RESET_IMPORT], MARK_COMMAND,
					nil]];
		}
		if(![joinList containsObject:fileMeta])
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"Join To Other Files", @"Join To Other Files"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire you wish to add this file to a list of files to be joined. The files will be joined in the order they were added to the list.", @"Mark file to be joined description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_TO_JOIN], MARK_COMMAND,
					nil]];
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"     This File and Complete", @"     This File and Complete"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to use this file to complete the joined list.", @"Mark file and join description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_MARK_AND_JOIN], MARK_COMMAND,
					nil]];
		}
		if([joinList count])
		{
			NSString *joinName;
			if(![joinList containsObject:fileMeta])
				joinName = BRLocalizedString(@"     Selected Files", @"     Selected Files");
			else
				joinName = BRLocalizedString(@"Join Selected Files", @"     Selected Files");
			
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					joinName, MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to complete the file join.", @"Join Marked Files description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_JOIN], MARK_COMMAND,
					nil]];
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"     Clear", @"     Clear"), MARK_NAME,
					BRLocalizedString(@"Tells Sapphire to clear the file join list.", @"clear file join list description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_CLEAR_JOIN_MARK], MARK_COMMAND,
					nil]];
		}
		[marks addObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Display Description", @"Marks file to only display discription"), MARK_NAME,
				BRLocalizedString(@"Hide all other info in preview one time", @"Display Description description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_SHOW_ONLY_SUMMARY], MARK_COMMAND,
				 nil]];
		[marks addObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Move File", @"Marks this file to be moved"), MARK_NAME,
				BRLocalizedString(@"Move this file.  Select destination later.", @"Moving a file description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_CUT_PATH], MARK_COMMAND,
				nil]];
		[marks addObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				BRLocalizedString(@"Delete File", @"Marks this file to be deleted"), MARK_NAME,
				BRLocalizedString(@"Deletes this file", @"Deleting a fie description"), MARK_DESCRIPTION,
				[NSNumber numberWithInt:COMMAND_DELETE_PATH], MARK_COMMAND,
				nil]];
		// Allow cover art change for all formats except for DVD, .mkv, and .flv
		// QTMovie is broken on the ATV, don't do it there
		if ([SapphireFrontRowCompat usingLeopard] && allowCoverArtChange( [meta path] ) )
		{
			[marks addObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					BRLocalizedString(@"Change artwork", @"Change artwork"), MARK_NAME,
					BRLocalizedString(@"Select artwork using images from the file", @"Changing artwork description"), MARK_DESCRIPTION,
					[NSNumber numberWithInt:COMMAND_CHANGE_ARTWORK], MARK_COMMAND,
					nil]];
		}
	}
	else
	{
		/*Neither, so just return nil*/
		[self autorelease];
		return nil;
	}
	[[self list] setDatasource:self];
	
	return self;
}

- (void) dealloc
{
	[marks release];
	[metaData release];
	[super dealloc];
}

- (BRLayerController *)loadArtwork:(SapphireFileMetaData *)fileMeta
{
	NSInvocation *invoke = [NSInvocation invocationWithMethodSignature: [self methodSignatureForSelector: @selector(doChangeArtwork:)]];
	[invoke setSelector: @selector(doChangeArtwork:)];
	[invoke setTarget:   self];
	
	SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene: [self scene]
																	 title: BRLocalizedString(@"Getting artwork selection", @"Getting artwork selection")
																invocation: invoke];
	
	[invoke setArgument: &fileMeta atIndex: 2];
	return [wait autorelease];
}

- (BRLayerController *)doChangeArtwork:(SapphireFileMetaData *)fileMeta
{
	SapphirePosterChooser *controller = [[SapphirePosterChooser alloc] initWithScene:[self scene]];

	[controller setListTitle:BRLocalizedString(@"Select cover art", @"Select cover art")];
	[controller setMovieTitle:@" "];
	[controller setFile:fileMeta];
	[controller setPosterImages:[NSImage imagesFromMovie:[fileMeta path] forArraySize:10]];
	
	NSInvocation *invoke = [NSInvocation invocationWithMethodSignature: [self methodSignatureForSelector:@selector(doChangeArtwork:)]];
	[invoke setSelector:@selector(doChangeArtwork:)];
	[invoke setTarget:self];
	[invoke retainArguments];
	[invoke setArgument:&fileMeta atIndex:2];
	[controller setRefreshInvocation:invoke];
	
	return [controller autorelease];
}

- (BRLayerController *)doJoin:(SapphireWaitDisplay *)wait
{
	@try {
		if(![joinList count])
			return nil;
		
		BOOL isFav = NO, isUnwatched = NO;
		QTMovie *resultingMovie = [[QTMovie alloc] init];
		[resultingMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
		
		NSString *savePath = [[joinList objectAtIndex:0] path];
		BOOL hasmovExt = [[savePath pathExtension] isEqualToString:@"mov"];
		NSString *base = [[joinList objectAtIndex:0] extensionlessPath];
		if([[base lowercaseString] hasSuffix:@" part 1"])
			base = [base substringToIndex:[base length] - 7];
		if(hasmovExt)
			savePath = [[base stringByAppendingString:@" Joined"] stringByAppendingPathExtension:@"mov"];
		else
			savePath = [base stringByAppendingPathExtension:@"mov"];
		
		NSManagedObjectContext *moc = [[joinList objectAtIndex:0] managedObjectContext];
		NSMutableString *mutSavePath = [savePath mutableCopy];
		[mutSavePath replaceOccurrencesOfString:@":" withString:@"-" options:0 range:NSMakeRange(0, [mutSavePath length])];  //Stupid QTKit Programmers.  This bug exists in QT Player in Leopard too.
		savePath = [mutSavePath autorelease];
		SapphireFileMetaData *finalFile = [SapphireFileMetaData createFileWithPath:savePath inContext:moc];
		SapphireJoinedFile *joined = [SapphireJoinedFile joinedFileForPath:savePath inContext:moc];
		int i, count=[joinList count];
		for(i=0;i<count;i++)
		{
			SapphireFileMetaData *meta = [joinList objectAtIndex:i];
			isFav |= [meta favoriteValue];
			isUnwatched |= ![meta watchedValue];
			[wait setCurrentStatus:[NSString stringWithFormat:BRLocalizedString(@"Opening %@", @"parameter is filename"), [[meta path] lastPathComponent]]];
			NSError *error = nil;
			NSDictionary *openAttr = [NSDictionary dictionaryWithObjectsAndKeys:
									  [meta path], QTMovieFileNameAttribute,
									  [NSNumber numberWithBool:NO], QTMovieOpenAsyncOKAttribute,
									  nil];
			QTMovie *current = [[QTMovie alloc] initWithAttributes:openAttr error:&error];
			if(error == nil)
			{
				QTTimeRange range;
				range.time = [current selectionStart];
				range.duration = [current duration];
				[current setSelection:range];
				[resultingMovie appendSelectionFromMovie:current];
				[meta setJoinedToFile:joined];
			}
			else
			{
				SapphireErrorDisplayController *errorDisplay = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Read Error", @"Short error indicating an error while reading a file in a join") longError:[error localizedDescription]];
				[resultingMovie release];
				[current release];
				return [errorDisplay autorelease];
			}
			[current release];
		}
		
		SapphireErrorDisplayController *errorDisplay = nil;
		[wait setCurrentStatus:[NSString stringWithFormat:BRLocalizedString(@"Saving Joined File to %@", @"parameter is save path"), [savePath lastPathComponent]]];
		[finalFile setWatchedValue:!isUnwatched];
		[finalFile setFavoriteValue:isFav];
		if(![resultingMovie writeToFile:savePath withAttributes:[NSDictionary dictionary]])
		{
			errorDisplay = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Save Error", @"Short error indicating an error while saving a file in a join") longError:BRLocalizedString(@"Save Error", @"Short error indicating an error while saving a file in a join")];
		}
		[resultingMovie release];
		[joinList removeAllObjects];
		[SapphireMetaDataSupport save:moc];
		return [errorDisplay autorelease];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	return nil;
}

- (long)itemCount
{
    // return the number of items in your menu list here
	return [marks count];
}

- (id<BRMenuItemLayer>)itemForRow:(long)row
{
	/*
	 // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
	 // return that object, it will be used to display the list item.
	 return ( nil );
	 */
	if(row >= [marks count])
		return nil;
	
	BRAdornedMenuItemLayer *result = nil;
	NSDictionary *mark = [marks objectAtIndex:row];
	NSString *name = [mark objectForKey:MARK_NAME];
	result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
	
	// add text
	[SapphireFrontRowCompat setTitle:name forMenu:result];
				
	return result;
}

- (NSString *)titleForRow:(long)row
{
	
	if(row >= [marks count])
		return nil;
	
	NSString *result = [[marks objectAtIndex:row] objectForKey:MARK_NAME];
	return result;
}

- (long)rowForTitle:(NSString *)title
{
    long result = -1;
    long i, count = [self itemCount];
    for(i = 0; i < count; i++)
    {
        if([title isEqualToString:[self titleForRow:i]])
        {
            result = i;
            break;
        }
    }
    
    return result;
}

- (void)itemSelected:(long) row
{
    // This is called when the user presses play/pause on a list item
	if(row >= [marks count])
		return;
	
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	BRLayerController *replaceController = nil;
	MarkCommand command = [[[marks objectAtIndex:row] objectForKey:MARK_COMMAND] intValue];
	/*Do action on dir or file*/
	if(isDir)
	{
		id <SapphireDirectory> dirMeta = (id <SapphireDirectory>)metaData;
		SapphireCollectionDirectory *collection = nil;
		if([dirMeta isKindOfClass:[SapphireDirectoryMetaData class]])
			collection = [(SapphireDirectoryMetaData *)dirMeta collectionDirectory];
		NSString *path = [dirMeta path];
		switch(command)
		{
			case COMMAND_MARK_WATCHED:
				setSubtreeToWatched(dirMeta, YES);
				break;
			case COMMAND_MARK_UNWATCHED:
				setSubtreeToWatched(dirMeta, NO);
				break;
			case COMMAND_MARK_FAVORITE:
				setSubtreeToFavorite(dirMeta, YES);
				break;
			case COMMAND_MARK_NOT_FAVORITE:
				setSubtreeToFavorite(dirMeta, NO);
				break;
			case COMMAND_MARK_TO_REFETCH_TV:
				setSubtreeToReimportFromMask(dirMeta, ImportTypeMaskTVShow);
				break;
			case COMMAND_MARK_TO_REFETCH_MOVIE:
				setSubtreeToReimportFromMask(dirMeta, ImportTypeMaskMovie);
				break;
			case COMMAND_MARK_TO_DELETE_METADATA:
				setSubtreeToClearMetaData(dirMeta);
				break;
			case COMMAND_MARK_TO_RESET_IMPORT:
				setSubtreeToResetImportDecisions(dirMeta);
				break;
			case COMMAND_TOGGLE_SKIP:
				if(collection == nil)
					[SapphireCollectionDirectory collectionAtPath:path mount:NO skip:YES hidden:NO manual:NO inContext:moc];
				else
					[collection setSkipValue:![collection skipValue]];
				break;
			case COMMAND_TOGGLE_COLLECTION:
				if(collection == nil)
					[SapphireCollectionDirectory collectionAtPath:path mount:NO skip:NO hidden:NO manual:YES inContext:moc];
				else
					[moc deleteObject:collection];
				break;
			case COMMAND_RENAME:
				if([dirMeta isKindOfClass:[SapphireDirectoryMetaData class]])
				{
					NSString *title = [NSString stringWithFormat:BRLocalizedString(@"Rename %@", @"Rename a file, directory, or collection, argument is path"), [dirMeta path]];
					NSInvocation *invoke;
					NSString *oldName;
					if(collection == nil)
					{
						oldName = [[dirMeta path] lastPathComponent];
						invoke = [NSInvocation invocationWithMethodSignature:[(SapphireDirectoryMetaData *)dirMeta methodSignatureForSelector:@selector(rename:)]];
						[invoke setTarget:dirMeta];
					}
					else
					{
						oldName = [collection name];
						if([oldName length] == 0)
							oldName = title;
						
						invoke = [NSInvocation invocationWithMethodSignature:[collection methodSignatureForSelector:@selector(rename:)]];
						[invoke setTarget:collection];
					}
					[invoke setSelector:@selector(rename:)];
					SapphireTextEntryController *rename = [[SapphireTextEntryController alloc] initWithScene:[self scene] title:title defaultText:oldName completionInvocation:invoke];
					replaceController = [rename autorelease];
				}
				break;
			case COMMAND_RENAME_TO_PRETTY:
				doSubtreeInvocation(dirMeta, @selector(renameToPrettyName), nil);
				break;
			case COMMAND_CUT_PATH:
				[movingPath release];
				movingPath = [[dirMeta path] retain];
				break;
			case COMMAND_PASTE_PATH:
			{
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(pasteInDir:)]];
				[invoke setSelector:@selector(pasteInDir:)];
				[invoke setTarget:self];
				[invoke setArgument:&dirMeta atIndex:2];
				
				SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene:[self scene] title:[NSString stringWithFormat:BRLocalizedString(@"Moving %@", @"parameter is file/dir that is being moved"), [movingPath lastPathComponent]] invocation:invoke];
				
				replaceController = [wait autorelease];
			}
				break;
			case COMMAND_DELETE_PATH:
			{
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(deleteReturnedResult:atPath:)]];
				[invoke setSelector:@selector(deleteReturnedResult:atPath:)];
				[invoke setTarget:self];
				[invoke setArgument:&dirMeta atIndex:3];
				[invoke retainArguments];
				
				SapphireConfirmPrompt *confirm = [[SapphireConfirmPrompt alloc] initWithScene:[self scene] title:BRLocalizedString(@"Delete Directory?", @"Delete Directory Prompt Title") subtitle:[NSString stringWithFormat:BRLocalizedString(@"Are you sure you wish to delete %@?", @"parameter is file/dir that is being deleted"), [[dirMeta path] lastPathComponent]] invocation:invoke];
				
				replaceController = [confirm autorelease];
				break;
			}
			default:
				break;
		}
	}
	else
	{
		SapphireFileMetaData *fileMeta = (SapphireFileMetaData *)metaData;
		switch(command)
		{
			case COMMAND_MARK_WATCHED:
				[fileMeta setWatchedValue:YES];
				[fileMeta setResumeTime:0];
				break;
			case COMMAND_MARK_UNWATCHED:
				[fileMeta setWatchedValue:NO];
				[fileMeta setResumeTime:0];
				break;
			case COMMAND_MARK_FAVORITE:
				[fileMeta setFavoriteValue:YES];
				break;
			case COMMAND_MARK_NOT_FAVORITE:
				[fileMeta setFavoriteValue:NO];
				break;
			case COMMAND_MARK_TO_REFETCH_TV:
				[fileMeta setToReimportFromMaskValue:ImportTypeMaskTVShow];
				break;
			case COMMAND_MARK_TO_REFETCH_MOVIE:
				[fileMeta setToReimportFromMaskValue:ImportTypeMaskMovie];
				break;
			case COMMAND_MARK_TO_DELETE_METADATA:
				[fileMeta clearMetaData];
				break;
			case COMMAND_MARK_TO_RESET_IMPORT:
				[fileMeta setToResetImportDecisions];
				break;
			case COMMAND_MARK_TO_JOIN:
				[joinList addObject:fileMeta];
				break;
			case COMMAND_CLEAR_JOIN_MARK:
				[joinList removeAllObjects];
				break;
			case COMMAND_MARK_AND_JOIN:
				[joinList addObject:fileMeta];
			case COMMAND_JOIN:
			{
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(doJoin:)]];
				[invoke setSelector:@selector(doJoin:)];
				[invoke setTarget:self];
				
				SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene:[self scene] title:BRLocalizedString(@"Joining Files", @"Title for wait display while joining files") invocation:invoke];
				[invoke setArgument:&wait atIndex:2];
				
				replaceController = [wait autorelease];
			}
				break;
			case COMMAND_SHOW_ONLY_SUMMARY:
				[[SapphireSettings sharedSettings] setDisplayOnlyPlotUntil:[NSDate dateWithTimeIntervalSinceNow:5]];
				break;
			case COMMAND_RENAME:
			{
				NSString *title = [NSString stringWithFormat:BRLocalizedString(@"Rename %@", @"Rename a file, directory, or collection, argument is path"), [fileMeta path]];
				NSString *oldName = [fileMeta fileName];
				
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[fileMeta methodSignatureForSelector:@selector(rename:)]];
				[invoke setSelector:@selector(rename:)];
				[invoke setTarget:fileMeta];
				SapphireTextEntryController *rename = [[SapphireTextEntryController alloc] initWithScene:[self scene] title:title defaultText:oldName completionInvocation:invoke];
				replaceController = [rename autorelease];				
			}
				break;
			case COMMAND_RENAME_TO_PRETTY:
			{
				NSString *error = [fileMeta renameToPrettyName];
				if(error != nil)
					replaceController = [[[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Error", @"Short message indicating error condition") longError:error] autorelease];
			}
				break;
			case COMMAND_MOVE_TO_AUTO_SORT:
			{
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(pasteInDir:)]];
				[invoke setSelector:@selector(moveToAutoSortName:)];
				[invoke setTarget:self];
				[invoke setArgument:&fileMeta atIndex:2];
				
				SapphireWaitDisplay *wait = [[SapphireWaitDisplay alloc] initWithScene:[self scene] title:[NSString stringWithFormat:BRLocalizedString(@"Moving %@", @"parameter is file/dir that is being moved"), [[fileMeta path] lastPathComponent]] invocation:invoke];
				
				replaceController = [wait autorelease];
			}
				break;
			case COMMAND_CUT_PATH:
				[movingPath release];
				movingPath = [[fileMeta path] retain];
				break;				
			case COMMAND_DELETE_PATH:
			{
				NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(deleteReturnedResult:atPath:)]];
				[invoke setSelector:@selector(deleteReturnedResult:atPath:)];
				[invoke setTarget:self];
				[invoke setArgument:&fileMeta atIndex:3];
				[invoke retainArguments];
				
				SapphireConfirmPrompt *confirm = [[SapphireConfirmPrompt alloc] initWithScene:[self scene] title:BRLocalizedString(@"Delete File?", @"Delete File Prompt Title") subtitle:[NSString stringWithFormat:BRLocalizedString(@"Are you sure you wish to delete %@?", @"parameter is file/dir that is being deleted"), [[fileMeta path] lastPathComponent]] invocation:invoke];
				
				replaceController = [confirm autorelease];
			}
				break;
			case COMMAND_CHANGE_ARTWORK:
				replaceController = [self loadArtwork:fileMeta];
				break;
			default:
				break;
		}
	}
	/*Save and exit*/
	[SapphireMetaDataSupport save:moc];
	if(replaceController != nil)
		[[self stack] swapController:replaceController];
	else
		[[self stack] popController];
}

- (BRControl *)moveToAutoSortName:(SapphireFileMetaData *)fileMeta
{
	NSString *error = [fileMeta moveToAutoSortName];
	if(error != nil)
		return [[[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Error", @"Short message indicating error condition") longError:error] autorelease];
	return nil;
}

- (BRControl *)pasteInDir:(SapphireDirectoryMetaData *)dirMeta
{
	NSManagedObjectContext *moc = [metaData managedObjectContext];
	NSString *errorString = nil;
	BOOL movingDir;
	if(![[NSFileManager defaultManager] fileExistsAtPath:movingPath isDirectory:&movingDir])
	{
		errorString = [NSString stringWithFormat:BRLocalizedString(@"%@ Seems to be missing", @"Could not find file; parameter is moving file"), [movingPath lastPathComponent]];
	}
	else if(movingDir)
	{
		SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData directoryWithPath:movingPath inContext:moc];
		errorString = [dir moveToDir:dirMeta];
	}
	else
	{
		SapphireFileMetaData *file = [SapphireFileMetaData fileWithPath:movingPath inContext:moc];
		errorString = [file moveToDir:dirMeta];
	}
	if(errorString != nil)
	{
		SapphireErrorDisplayController *error = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Moving Error", @"Short error indicating an error while moving a file") longError:errorString];
		return [error autorelease];
	}
	else
	{
		[movingPath release];
		movingPath = nil;
	}
	[SapphireMetaDataSupport save:moc];
	return nil;
}

- (BRControl *)deleteReturnedResult:(SapphireConfirmPromptResult)result atPath:(NSManagedObject <SapphireMetaData> *)meta
{
	if(result != SapphireConfirmPromptResultOK)
		return nil;
	
	@try {
		NSManagedObjectContext *moc = [meta managedObjectContext];
		BOOL success = [[NSFileManager defaultManager] removeFileAtPath:[meta path] handler:nil];
		if(!success)
		{
			NSString *errorString = [NSString stringWithFormat:BRLocalizedString(@"Could not delete %@.  Is the filesystem read-only?", @"Unknown error renaming file/directory; parameter is name"), [[meta path] lastPathComponent]];
			SapphireErrorDisplayController *error = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Delete Error", @"Short error indicating an error while deleting a file") longError:errorString];
			return [error autorelease];
		}
		[moc deleteObject:meta];
		[SapphireMetaDataSupport save:moc];
		return nil;
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	return nil;
}

- (id<BRMediaPreviewController>)previewControlForItem:(long)item
{
	return [self previewControllerForItem:item];
}

- (id<BRMediaPreviewController>)previewControllerForItem:(long)item
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
		if(item >= [marks count])
		return nil;
	else
	{
		/* Get setting name & kill cushion  */
		NSDictionary *mark = [marks objectAtIndex:item];
		NSString *markName = [NSString stringWithFormat:@"%@ for \"%@\"",[mark objectForKey:MARK_NAME],(NSString *)[self listTitle]];
		NSString *markDescription = [mark objectForKey:MARK_DESCRIPTION];
		/* Construct a gerneric metadata asset for display */
		NSMutableDictionary *markMeta=[[NSMutableDictionary alloc] init];
		[markMeta setObject:markName forKey:META_TITLE_KEY];
		[markMeta setObject:[NSNumber numberWithInt:FILE_CLASS_UTILITY] forKey:FILE_CLASS_KEY];
		[markMeta setObject:markDescription forKey:META_DESCRIPTION_KEY];
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		[preview setUtilityData:markMeta];
		[markMeta release];
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

@end
