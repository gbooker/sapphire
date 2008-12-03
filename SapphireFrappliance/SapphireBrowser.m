/*
 * SapphireBrowser.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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

#import "SapphireBrowser.h"
#import <BackRow/BackRow.h>
#import "SapphireMetaData.h"
#import "SapphireMarkMenu.h"
#import "SapphireMedia.h"
#import "SapphireVideoPlayer.h"
#import "SapphireMediaPreview.h"
#import "SapphireTheme.h"
#import "SapphireSettings.h"
#import "NSString-Extensions.h"
#import "SapphireAudioPlayer.h"
#import "SapphireAudioMedia.h"
#import "SapphireApplianceController.h"
#import "SapphireVideoPlayerController.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import <SapphireCompatClasses/SapphireDVDLoadingController.h>

#import <objc/objc-class.h>

@interface SapphireBrowser (private)
- (void)reloadDirectoryContents;
- (void)setNewPredicate:(SapphirePredicate *)newPredicate;
@end

@interface BRMusicNowPlayingController (bypassAccess)
- (void)setPlayer:(BRMusicPlayer *)player;
- (BRMusicPlayer *)player;
@end

@implementation BRMusicNowPlayingController (bypassAccess)
- (void)setPlayer:(BRMusicPlayer *)player
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	BRMusicPlayer * *thePlayer = (BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
	
	[*thePlayer release];
	*thePlayer = [player retain];
}

- (BRMusicPlayer *)player
{
	Class myClass = [self class];
	Ivar ret = class_getInstanceVariable(myClass, "_player");
	return *(BRMusicPlayer * *)(((char *)self)+ret->ivar_offset);	
}

@end

static BOOL is10Version = NO;

@implementation SapphireBrowser

- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta
{
	if ( [super initWithScene: scene] == nil ) return ( nil );
		
	_names = [NSMutableArray new];
	items = [NSMutableArray new];
	metaData = [meta retain];
	predicate = [[SapphireApplianceController predicate] retain];

	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

- (void) dealloc
{
    // always remember to deallocate your resources
	[_names release];
	[items release];
	if([metaData delegate] == self)
		[metaData setDelegate:nil];
	[metaData release];
	[predicate release];
    [super dealloc];
}

- (void)reloadDirectoryContents
{
	/*Tell the metadata to get new data*/
	[metaData reloadDirectoryContents];
}

- (void)directoryContentsChanged
{
	/*Flush our cache*/
	[_names removeAllObjects];
	[items removeAllObjects];
	/*Check predicates*/
	if(predicate == NULL)
	{
		/*No filtering, so just set up the dirs and files into names and the counts*/
		NSArray *dirs = [metaData directories];
		[_names addObjectsFromArray:dirs];
		NSArray *files = [metaData files];
		[_names addObjectsFromArray:files];
		dirCount = [dirs count];
		fileCount = [files count];
	}
	else
	{
		/*Filter the dirs and files into names and counts*/
		NSArray *dirs = [metaData predicatedDirectories:predicate];
		[_names addObjectsFromArray:dirs];
		NSArray *files = [metaData predicatedFiles:predicate];
		[_names addObjectsFromArray:files];
		/*Put in the menu for rescan if fast switching enabled*/
		if([[SapphireSettings sharedSettings] fastSwitching])
			[_names addObject:BRLocalizedString(@"     < Scan for new files >", @"Conduct a scan of the directory for new files")];
		dirCount = [dirs count];
		fileCount = [files count];
	}
	/*Init the cache*/
	int i=0, count=[_names count];
	for(i=0; i<count; i++)
	{
		[items addObject:[NSNull null]];
	}

	/*Remove the dividers*/
	BRListControl *list = [self list];
	if([list respondsToSelector:@selector(removeDividers)])
		[list removeDividers];
	else
		[list setDividerIndex:0];
	[list removeDividerAtIndex:0];
	/*Do a reload*/
	[list reload];
	/*Add dividers*/
	int indexOffset = 0;
	if(dirCount && fileCount)
	{
		[SapphireFrontRowCompat addDividerAtIndex:dirCount toList:list];
		if(!is10Version)
			indexOffset++;
	}
	if(predicate != NULL && [[SapphireSettings sharedSettings] fastSwitching])
		[SapphireFrontRowCompat addDividerAtIndex:dirCount + fileCount + indexOffset toList:list];
	/*Draw*/
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (SapphireDirectoryMetaData *)metaData
{
	return metaData;
}

- (void) wasPushed
{
    // We've just been put on screen, the user can see this controller's content now
	/*Reload upon display*/
	@try {
		[metaData setDelegate:self];
		[self setNewPredicate:[SapphireApplianceController predicate]];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}	
    // always call super
    [super wasPushed];
	/*Get metadata when we can*/
	[metaData resumeImport];
}

- (void) wasPopped
{
    // The user pressed Menu, removing us from the screen
    // always call super

    [super wasPopped];
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	[metaData setDelegate:nil];
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
    // The user chose an option and this controller is no longer on screen

	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;

    // always call super
    [super wasBuriedByPushingController: controller];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
    // handle being revealed when the user presses Menu

	/*Reload our display*/
	[self setNewPredicate:[SapphireApplianceController predicate]];

    // always call super
    [super wasExhumedByPoppingController: controller];
	/*Check to see if dir is empty*/
	if(fileCount + dirCount == 0)
		[[self stack] popController];
	else
		/*Resume importing now that we are up again*/
		[metaData resumeImport];
}

- (long) itemCount
{
    // return the number of items in your menu list here
	if([_names count])
		return ( [ _names count]);
	// Put up an empty item
	return 1;
}

- (id<BRMenuItemLayer>) itemForRow: (long) row
{
	NSString * displayName=nil ;
	FileClass fileCls=0 ;
	/*Check for no items*/
	int nameCount = [_names count];
	if( nameCount == 0)
	{
		BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
		[SapphireFrontRowCompat setTitle:BRLocalizedString(@"< EMPTY >", @"Empty directory") forMenu:result];
		return result;
	}
	if( row >= nameCount ) return ( nil ) ;
	
	/*Check our cache*/
	id cached = [items objectAtIndex:row];
	if(cached != [NSNull null])
		return cached;
	NSString *name = [_names objectAtIndex:row];
	// Pad filename to correcrtly display gem icons
	BRAdornedMenuItemLayer * result = nil;
	BOOL watched = NO;
	BOOL favorite = NO;
	BOOL utility = NO;
	BRRenderScene *scene = [self scene];
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	/*Is this a dir*/
	if(row < dirCount)
	{
		result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:YES];
		SapphireDirectoryMetaData *meta = [metaData metaDataForDirectory:name];
		watched = [meta watchedForPredicate:predicate];
		favorite = [meta favoriteForPredicate:predicate];
	}
	/*Check for a file next*/
	else if(row < dirCount + fileCount)
	{
		result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:NO];
		SapphireFileMetaData *meta = [metaData metaDataForFile:name];
		if(meta != nil)
		{
			fileCls=[meta fileClass] ;
			BOOL rightTextSet;
			if(fileCls==FILE_CLASS_TV_SHOW)
			{
				/*Display episode number if availble*/
				int eps= [meta episodeNumber] ;
				int ep2= [meta secondEpisodeNumber] ;
				displayName=[meta episodeTitle] ;
				if(eps>0)
				{
					if(ep2>0)
						[SapphireFrontRowCompat setRightJustifiedText:[NSString stringWithFormat:@" %02d-%02d",eps, ep2] forMenu:result];
					else
						[SapphireFrontRowCompat setRightJustifiedText:[NSString stringWithFormat:@" %02d",eps] forMenu:result];
					rightTextSet = YES;
				}
			}
			if(fileCls==FILE_CLASS_MOVIE)
			{
				displayName=[meta movieTitle] ;
				/* Find out if we are displaying a virtual directoy we need to filter for */
				NSString *dirFilter=[[[metaData path] pathComponents] objectAtIndex:1];
				/*Add icons & stats (RIGHT)*/
				if([dirFilter isEqualToString:VIRTUAL_DIR_TOP250_KEY])
				{
					/* This list is already filtered so all displayed movies will have a top250 stat */
					[SapphireFrontRowCompat setRightJustifiedText:[meta movieStatsTop250] forMenu:result];
					[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
					rightTextSet = YES;
				}
				else if([meta oscarsWon]>0)
				{
					[SapphireFrontRowCompat setRightJustifiedText:[meta movieStatsOscar] forMenu:result];
					[SapphireFrontRowCompat setRightIcon:[theme gem:OSCAR_GEM_KEY] forMenu:result];
					rightTextSet = YES;
				}
				else if([meta imdbTop250]>0)
				{
					[SapphireFrontRowCompat setRightJustifiedText:[meta movieStatsTop250] forMenu:result];
					[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
					rightTextSet = YES;
				}
			}
			watched = [meta watched];
			favorite = [meta favorite];
			NSString *sizeString = [meta sizeString];
			if(!rightTextSet && [sizeString length] > 1)
				/*Fallback to size*/
				[SapphireFrontRowCompat setRightJustifiedText:sizeString forMenu:result];

		}
	}
	/*Utility*/
	else
	{
		result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:NO];
		utility = YES;
	}
	/*Add icons (LEFT)*/
	if(utility) [SapphireFrontRowCompat setLeftIcon:[theme gem:FAST_GEM_KEY] forMenu:result];
	else if(!watched) [SapphireFrontRowCompat setLeftIcon:[theme gem:BLUE_GEM_KEY] forMenu:result];
	else if(favorite) [SapphireFrontRowCompat setLeftIcon:[theme gem:YELLOW_GEM_KEY] forMenu:result];
	else if(fileCls==FILE_CLASS_AUDIO)[SapphireFrontRowCompat setLeftIcon:[theme gem:GREEN_GEM_KEY] forMenu:result];
	else [SapphireFrontRowCompat setLeftIcon:[theme gem:RED_GEM_KEY] forMenu:result];
			
	// add text
	if(displayName)name= displayName ;
	name=[@"  " stringByAppendingString: name] ;
	[SapphireFrontRowCompat setTitle:name forMenu:result];
	[items replaceObjectAtIndex:row withObject:result];
				
	return ( result ) ;
}

- (NSString *) titleForRow: (long) row
{

	if ( row >= [ _names count] ) return ( nil );
	
	NSString *result = [ _names objectAtIndex: row] ;
	
	return ([@"  ????? " stringByAppendingString: result] ) ;
}

- (long) rowForTitle: (NSString *) title
{
    long result = -1;
    long i, count = [self itemCount];
    for ( i = 0; i < count; i++ )
    {
        if ( [title isEqualToString: [self titleForRow: i]] )
        {
            result = i;
            break;
        }
    }
    
    return ( result );
}

- (void)setNewPredicate:(SapphirePredicate *)newPredicate
{
	[newPredicate retain];
	[predicate release];
	predicate = newPredicate;
	[self setListIcon:[SapphireApplianceController gemForPredicate:predicate]];
	[self reloadDirectoryContents];	
}

- (void) itemSelected: (long) row
{
    // This is called when the user presses play/pause on a list item
	
	if([_names count] == 0)
	{
		/*No items, so leave the empty dir*/
		[[self stack] popController];
		return;
	}
	
	NSString *name = [_names objectAtIndex:row];
	
	/*Check for dir*/
	if(row < dirCount)
	{
		/*Browse the subdir*/
		id controller = [[SapphireBrowser alloc] initWithScene:[self scene] metaData:[metaData metaDataForDirectory:name]];
		[controller setListTitle:[NSString stringWithFormat:@" %@",name]];
		[controller setListIcon:[self listIcon]];
		[[self stack] pushController:controller];
		[controller release];
	}
	else if(row < dirCount + fileCount)
	{
		/*Play the file*/
		SapphireFileMetaData *currentPlayFile = [[metaData metaDataForFile:name] retain];
		if([currentPlayFile updateMetaData])
			[currentPlayFile writeMetaData];
		
		NSString *path = [currentPlayFile path];
		
		/*Anonymous reporting*/
		SapphireSettings *settings = [SapphireSettings sharedSettings];
		if(![settings disableAnonymousReporting])
		{
			NSMutableString *reqData = [NSMutableString string];
			NSMutableArray *reqComp = [NSMutableArray array];
			NSMutableURLRequest *request=nil;
			NSString *ext=nil;
			int fileClass=-1;
			
			if(path != 0)
			{
				[reqComp addObject:[NSString stringWithFormat:@"path=%@", [[path lastPathComponent]lowercaseString]]];
				ext=[[path pathExtension]lowercaseString] ;
			}
			
			if([currentPlayFile fileClass]==FILE_CLASS_TV_SHOW)
			{
				fileClass=1;
				request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/show.php"]];
				int ep = [currentPlayFile episodeNumber];
				int season = [currentPlayFile seasonNumber];
				NSString *showID = [currentPlayFile showID];
				NSString *showName= [currentPlayFile showName];
				 
				if(season != 0)
					[reqComp addObject:[NSString stringWithFormat:@"season=%d", season]];
				if(ep != 0)
					[reqComp addObject:[NSString stringWithFormat:@"ep=%d", ep]];
				if(showName != 0)
					[reqComp addObject:[NSString stringWithFormat:@"showname=%@", showName]];
				if(showID != 0)
					[reqComp addObject:[NSString stringWithFormat:@"showid=%@", showID]];
			}
			else if([currentPlayFile fileClass]==FILE_CLASS_MOVIE)
			{
				fileClass=2;
				request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/movie.php"]];
				NSString *movieTitle=[currentPlayFile movieTitle];
				NSString *movieID=[currentPlayFile movieID];
				NSDate * releaseDate=[currentPlayFile movieReleaseDate];
 				if(movieTitle != 0)
					[reqComp addObject:[NSString stringWithFormat:@"title=%@", movieTitle]];
				if(releaseDate != 0)
					[reqComp addObject:[NSString stringWithFormat:@"year=%@", [releaseDate descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]]];
				if(movieID != 0)
					[reqComp addObject:[NSString stringWithFormat:@"movieid=%@", movieID]];
			}
			else
			{
				request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/ext.php"]];
				if([currentPlayFile fileClass]==FILE_CLASS_UNKNOWN)
					 fileClass=0;
				if([currentPlayFile fileClass]==FILE_CLASS_AUDIO)
					 fileClass=3;
				if([currentPlayFile fileClass]==FILE_CLASS_OTHER)
					fileClass=5;
				else
					fileClass=99;
			}
			
			if(ext!=0)
			{
				[reqComp addObject:[NSString stringWithFormat:@"filetype=%d",fileClass]];
				[reqComp addObject:[NSString stringWithFormat:@"extension=%@", ext]];
				if([SapphireFrontRowCompat usingFrontRow])
					[reqComp addObject:[NSString stringWithFormat:@"ckey=FRONTROW-%@-%d",ext,fileClass]];
				else
					[reqComp addObject:[NSString stringWithFormat:@"ckey=ATV-%@-%d",ext,fileClass]];
			}
			
			int count = [reqComp count];
			int i;
			for(i=0; i<count-1; i++)
			{
				[reqData appendFormat:@"%@&", [reqComp objectAtIndex:i]];
			}
			if(count)
				[reqData appendFormat:@"%@", [reqComp objectAtIndex:i]];
			
			NSData *postData = [reqData dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
			
			[request setHTTPMethod:@"POST"];
			[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
			[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			[request setHTTPBody:postData];
			[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
			/*Trigger the req*/
			NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:nil];
			[download autorelease];
		}
		
		if ([currentPlayFile fileContainerType] == FILE_CONTAINER_TYPE_VIDEO_TS)
		{
			BRDVDMediaAsset *asset = [[BRDVDMediaAsset alloc] initWithPath:path];
			SapphireDVDLoadingController *controller = [[SapphireDVDLoadingController alloc] initWithScene:[self scene] forAsset:asset];
			[asset release];
			[[self stack] pushController:controller];
			[controller release];
		}
		else if([[SapphireMetaData videoExtensions] containsObject:[path pathExtension]] && [currentPlayFile hasVideo])
		{
			/*Video*/
			/*Set the asset resume time*/
			NSURL *url = [NSURL fileURLWithPath:path];
			SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
			[asset setResumeTime:[currentPlayFile resumeTime]];
			
			/*Get the player*/
			SapphireVideoPlayer *player = [[SapphireVideoPlayer alloc] init];
			NSError *error = nil;
			[player setMedia:asset error:&error];
			
			/*and go*/
			SapphireVideoPlayerController *controller = [[SapphireVideoPlayerController alloc] initWithScene:[self scene] player:player];
			[controller setPlayFile:currentPlayFile];
			[controller setAllowsResume:YES];
			[[self stack] pushController:controller];

			[asset release];
			[player release];
			[controller release];
		}
		else
		{
			/*Audio*/
			/*Set the asset*/
			NSURL *url = [NSURL fileURLWithPath:path];
			SapphireAudioMedia *asset  =[[SapphireAudioMedia alloc] initWithMediaURL:url];
			[asset setResumeTime:[currentPlayFile resumeTime]];
			
			SapphireAudioPlayer *player = [[SapphireAudioPlayer alloc] init];
			NSError *error = nil;
			[player setMedia:asset inTracklist:[NSArray arrayWithObject:asset] error:&error];
			
			/*and go*/
			BRMusicNowPlayingController *controller = [BRMusicNowPlayingController alloc];
			if([controller respondsToSelector:@selector(initWithScene:)])
				controller = [controller initWithScene:[self scene]];
			else
				controller = [controller init];
			[controller setPlayer:player];
			[player setElapsedPlaybackTime:[currentPlayFile resumeTime]];
			[player play];
			[[self stack] pushController:controller];
			
			[asset release];
			[player release];
			[controller release];
		}
	}
	else
	{
		/*Do a scan*/
		cancelScan = NO;
		[metaData scanForNewFilesWithDelegate:self skipDirectories:[NSMutableSet set]];
	}
}

- (void)gotSubFiles:(NSArray *)subs
{
	[self reloadDirectoryContents];	
}

- (void)scanningDir:(NSString *)dir
{
}

- (BOOL)getSubFilesCanceled
{
	return cancelScan;
}

- (id<BRMediaPreviewController>) previewControlForItem: (long) row
{
	return [self previewControllerForItem:row];
}

- (id<BRMediaPreviewController>) previewControllerForItem: (long) row
{
    // If subclassing BRMediaMenuController, this function is called when the selection cursor
    // passes over an item.
	if(row >= [_names count])
		return nil;
	/*Check to see if it is a dir or file*/
	NSString *name = [_names objectAtIndex:row];
	if(row < dirCount + fileCount)
	{
		SapphireMediaPreview *preview = [[SapphireMediaPreview alloc] initWithScene:[self scene]];
		/*Check for dir*/
		if(row < dirCount)
			[preview setMetaData:[metaData metaDataForDirectory:name] inMetaData:metaData];
		else
			[preview setMetaData:[metaData metaDataForFile:name] inMetaData:metaData];
		[preview setShowsMetadataImmediately:NO];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventPageUsageHash hashVal = (uint32_t)([event page] << 16 | [event usage]);
	if ([(BRControllerStack *)[self stack] peekController] != self)
		hashVal = 0;
		
	int row = [self getSelection];
	
	switch (hashVal)
	{
		case kBREventTapRight:
		{
			id meta = nil;
			if(row >= [_names count])
				break;
			
			NSString *name = [_names objectAtIndex:row];
			
			/*Get metadata*/
			if(row < dirCount)
				meta = [metaData metaDataForDirectory:name];
			else if (row < dirCount + fileCount)
				meta = [metaData metaDataForFile:name];
			else
				break;
			/*Do mark menu*/
			id controller = [[SapphireMarkMenu alloc] initWithScene:[self scene] metaData:meta];
			[(SapphireMarkMenu *)controller setPredicate:predicate];
			[(SapphireMarkMenu *)controller setListTitle:name];
			[[self stack] pushController:controller];
			[controller release];
			return YES;
		}
		case kBREventTapLeft:
		{
			NSString *oldName=nil;
			if(row < [_names count])
				oldName = [self titleForRow:row];
			[self setNewPredicate:[SapphireApplianceController nextPredicate]];
			/*Attempt to preserve the user's current highlighted selection*/
			if(oldName)
			{
				row=[self rowForTitle:oldName];
				if(row>=0)
				{
					[(BRListControl *)[self list] setSelection:row];
				}
				else
				{
					[(BRListControl *)[self list] setSelection:0];
					[self updatePreviewController];
				}
			}
			/*Force a reload on the mediaPreviewController*/
			/* Not working in FrontRow */
			[self wasPushed];
			return YES;
		}
	}
	return [super brEventAction:event];
}

- (void)updateCompleteForFile:(NSString *)file
{
	/*Get the file*/
	int index = [_names indexOfObject:file];
	if(index != NSNotFound)
		[items replaceObjectAtIndex:index withObject:[NSNull null]];
	/*Relead the list and render*/
	BRListControl *list = [self list];
	[list reload];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

@end
