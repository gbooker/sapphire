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
#import "SapphireDirectoryMetaData.h"
#import "SapphireFileMetaData.h"
#import "SapphireEpisode.h"
#import "SapphireSeason.h"
#import "SapphireTVShow.h"
#import "SapphireMovie.h"
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
#import "SapphireMetaDataSupport.h"
#import "SapphireDisplayMenu.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import <SapphireCompatClasses/SapphireDVDLoadingController.h>
#import "SapphireErrorDisplayController.h"
#import "SapphireAudioNowPlayingController.h"


#import "SapphireCMPWrapper.h"

#import <objc/objc-class.h>

#import "NSFileManager-Extensions.h"

@interface SapphireBrowser ()
- (void)reloadDirectoryContents;
- (void)setNewPredicate:(NSPredicate *)newPredicate;
@end

static BOOL is10Version = NO;

@implementation SapphireBrowser

- (id) initWithScene: (BRRenderScene *) scene metaData:(id <SapphireDirectory>)meta
{
	if([super initWithScene:scene] == nil)
		return nil;
		
	_names = [NSMutableArray new];
	items = [NSMutableDictionary new];
	metaData = [meta retain];
	predicate = [[SapphireApplianceController predicate] retain];
	[metaData setFilterPredicate:predicate];

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
	if(![metaData objectIsDeleted])
		[metaData reloadDirectoryContents];
	else
	{
		[_names removeAllObjects];
		[items removeAllObjects];
		dirCount = fileCount = 0;
		[[self list] reload];
		[self resetPreviewController];
		[SapphireFrontRowCompat renderScene:[self scene]];
	}
}

- (void)directoryContentsChanged
{
	BOOL isTake2 = [SapphireFrontRowCompat usingATypeOfTakeTwo];
	BOOL isReallyFrontrow = [SapphireFrontRowCompat usingLeopard];
	NSString *oldName=nil;
	int oldRow = [self getSelection];
	
	if(oldRow < [_names count] && oldRow > 0)
		oldName = [[_names objectAtIndex:oldRow] retain];

	/*Flush our cache*/
	[_names removeAllObjects];
	[items removeAllObjects];
	/*Set up the dirs and files into names and the counts*/
	if(![metaData objectIsDeleted])
	{
		NSArray *dirs = [metaData directories];
		[_names addObjectsFromArray:dirs];
		NSArray *files = [metaData files];
		[_names addObjectsFromArray:files];		
		dirCount = [dirs count];
		fileCount = [files count];
	}
	else
	{
		dirCount = 0;
		fileCount = 0;
	}
	if(predicate != NULL)
	{
		/*Put in the menu for rescan if fast switching enabled*/
		if([[SapphireSettings sharedSettings] fastSwitching])
			[_names addObject:BRLocalizedString(@"     < Scan for new files >", @"Conduct a scan of the directory for new files")];
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
		if(!is10Version && !isTake2)
			indexOffset++;
	}
	if(predicate != NULL && [[SapphireSettings sharedSettings] fastSwitching])
		if(!isReallyFrontrow || indexOffset == 0) //Frontrow cannot display a list with two dividers correctly!!!!!
			[SapphireFrontRowCompat addDividerAtIndex:dirCount + fileCount + indexOffset toList:list];
	if([[self stack] peekController] == self)
		[metaData resumeImport];
	
	/*Attempt to preserve the user's current highlighted selection*/
	if(oldName)
	{
		int row = [_names indexOfObject:oldName];
		if(row == NSNotFound)
			row = oldRow;
		if(row >= [_names count])
			row--;
		[(BRListControl *)[self list] setSelection:row];
		[oldName release];
	}
	else if(fileCount != 0)
		[(BRListControl *)[self list] setSelection:dirCount];
	else
		[(BRListControl *)[self list] setSelection:0];
	/*Draw*/
	[self resetPreviewController];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

- (id <SapphireDirectory>)metaData
{
	return metaData;
}

- (void)setKillMusic:(BOOL)kill
{
	killMusic = kill;
}

- (void)doInitialPush
{
	/*Reload upon display*/
	@try {
		[metaData setDelegate:self];
		[self setNewPredicate:[SapphireApplianceController predicate]];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	[super doInitialPush];
}

- (void)wasPushed
{
    [super wasPushed];
	/*Get metadata when we can*/
	[metaData resumeImport];
}

- (void)wasPopped
{
    [super wasPopped];
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	[metaData setDelegate:nil];
	if(killMusic)
		[SapphireApplianceController setMusicNowPlayingController:nil];
}

- (void)wasBuried
{
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	[metaData setDelegate:nil];

    // always call super
    [super wasBuried];
}

- (void)doInitialExhume
{
	/*Reload our display*/
	[metaData setDelegate:self];
	[self setNewPredicate:[SapphireApplianceController predicate]];
	[super doInitialExhume];
}

- (void)wasExhumed
{
	[super wasExhumed];
	/*Check to see if dir is empty*/
	if(fileCount + dirCount == 0)
		[[self stack] performSelector:@selector(popController) withObject:nil afterDelay:0.01f];
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
	@try{
		NSString * displayName=nil ;
		/*Check for no items*/
		int nameCount = [_names count];
		FileClass fileCls=0;
		if( nameCount == 0)
		{
			BRAdornedMenuItemLayer *result = [SapphireFrontRowCompat textMenuItemForScene:[self scene] folder:NO];
			[SapphireFrontRowCompat setTitle:BRLocalizedString(@"< EMPTY >", @"Empty directory") forMenu:result];
			return result;
		}
		if( row >= nameCount ) return ( nil ) ;
		
		/*Check our cache*/
		NSString *lookupName = [_names objectAtIndex:row];
		id cached = [items objectForKey:lookupName];
		if(cached != nil)
			return cached;
		// Pad filename to correcrtly display gem icons
		BRAdornedMenuItemLayer * result = nil;
		BOOL watched = NO;
		BOOL favorite = NO;
		BOOL utility = NO;
		BOOL partiallyWatched = NO;
		BRRenderScene *scene = [self scene];
		SapphireTheme *theme = [SapphireTheme sharedTheme];
		/*Is this a dir*/
		if(row < dirCount)
		{
			result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:YES];
			id <SapphireDirectory> meta = [metaData metaDataForDirectory:lookupName];
			watched = ![meta containsFileMatchingPredicate:[SapphireApplianceController unwatchedPredicate]];
			favorite = [meta containsFileMatchingPredicate:[SapphireApplianceController favoritePredicate]];
		}
		/*Check for a file next*/
		else if(row < dirCount + fileCount)
		{
			result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:NO];
			SapphireFileMetaData *meta = [metaData metaDataForFile:lookupName];
			if(meta != nil)
			{
				fileCls=[meta fileClassValue];
				BOOL rightTextSet = NO;
				if(fileCls==FileClassTVShow)
				{
					SapphireEpisode *ep = [meta tvEpisode];
					/*Display episode number if available*/
					int eps= [ep episodeNumberValue];
					int ep2= [ep lastEpisodeNumberValue];
					displayName=[ep episodeTitle] ;
					if(eps>0)
					{
						NSArray *comp = [[metaData path] pathComponents];
						NSString *prefix = @"";
						if([comp count] == 2 && [[comp objectAtIndex:0] isEqual:@"@TV"])
							/*Eps listed outside of seasons*/
							prefix = [NSString stringWithFormat:@"%02dx", [[ep season] seasonNumberValue]];
						if(ep2>0 && ep2 != eps)
							[SapphireFrontRowCompat setRightJustifiedText:[NSString stringWithFormat:@" %@%02d-%02d", prefix, eps, ep2] forMenu:result];
						else
							[SapphireFrontRowCompat setRightJustifiedText:[NSString stringWithFormat:@" %@%02d", prefix, eps] forMenu:result];
						rightTextSet = YES;
					}
				}
				if(fileCls==FileClassMovie)
				{
					SapphireMovie *movie = [meta movie];
					displayName=[movie title];
					/* Find out if we are displaying a virtual directoy we need to filter for */
					NSString *dirPath=[metaData path];
					/*Add icons & stats (RIGHT)*/
					int top250 = [movie imdbTop250RankingValue];
					if([dirPath hasPrefix:VIRTUAL_DIR_TOP250_PATH] && top250 > 0)
					{
						NSString *movieStatsTop250 = [NSString stringWithFormat:@"#%d ", top250];
						/* This list is already filtered so all displayed movies will have a top250 stat */
						[SapphireFrontRowCompat setRightJustifiedText:movieStatsTop250 forMenu:result];
						[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
					}
					else if([movie oscarsWonValue] > 0)
					{
						NSString *movieStatsOscar = [NSString stringWithFormat:@"%dx", [movie oscarsWonValue]];
						[SapphireFrontRowCompat setRightJustifiedText:movieStatsOscar forMenu:result];
						[SapphireFrontRowCompat setRightIcon:[theme gem:OSCAR_GEM_KEY] forMenu:result];
					}
					else if(top250 > 0)
					{
						NSString *movieStatsTop250 = [NSString stringWithFormat:@"#%d ", top250];
						[SapphireFrontRowCompat setRightJustifiedText:movieStatsTop250 forMenu:result];
						[SapphireFrontRowCompat setRightIcon:[theme gem:IMDB_GEM_KEY] forMenu:result];
					}
					else
					{
						[SapphireFrontRowCompat setRightJustifiedText:[meta durationString] forMenu:result];
					}
					rightTextSet = YES;
				}
				watched = [meta watchedValue];
				favorite = [meta favoriteValue];
				partiallyWatched = [meta resumeTimeValue] != 0;
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
		NSString *gemString = nil;
		/*Add icons (LEFT)*/
		if(utility) gemString = FAST_GEM_KEY;
		else if(partiallyWatched) gemString = RED_BLUE_GEM_KEY;
		else if(!watched) gemString = BLUE_GEM_KEY;
		else if(favorite) gemString = YELLOW_GEM_KEY;
		else if(fileCls==FileClassAudio) gemString = GREEN_GEM_KEY;
		else gemString = RED_GEM_KEY;;
		[SapphireFrontRowCompat setLeftIcon:[theme gem:gemString] forMenu:result];
		
		// add text
		NSString *name;
		if(displayName)
			name = displayName;
		else
			name = lookupName;
		name=[@"  " stringByAppendingString: name] ;
		[SapphireFrontRowCompat setTitle:name forMenu:result];
		[items setObject:result forKey:lookupName];
					
		return ( result ) ;
	} @catch (NSException *e) {
		[SapphireApplianceController logException:e];
	}
	return nil;
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

- (void)setNewPredicate:(NSPredicate *)newPredicate
{
	[newPredicate retain];
	[predicate release];
	predicate = newPredicate;
	if([metaData filterPredicate] != predicate)
		[metaData setFilterPredicate:predicate];
	[self setListIcon:[SapphireApplianceController gemForPredicate:predicate]];
	[self reloadDirectoryContents];
}

- (void)anonymousReportFile:(SapphireFileMetaData *)currentPlayFile withPath:(NSString *)path
{
	NSMutableString *reqData = [NSMutableString string];
	NSMutableArray *reqComp = [NSMutableArray array];
	NSMutableURLRequest *request=nil;
	NSString *ext=nil;
	int fileClass=-1;
	
	if(path != nil)
	{
		[reqComp addObject:[NSString stringWithFormat:@"path=%@", [[path lastPathComponent]lowercaseString]]];
		ext=[[path pathExtension]lowercaseString] ;
	}
	
	if([currentPlayFile fileClassValue] == FileClassTVShow)
	{
		SapphireEpisode *episode = [currentPlayFile tvEpisode];
		fileClass=1;
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/show.php"]];
		int ep = [episode episodeNumberValue];
		int season = [[episode season] seasonNumberValue];
		SapphireTVShow *show = [episode tvShow];
		NSString *showName= [show name];
		
		if(season != 0)
			[reqComp addObject:[NSString stringWithFormat:@"season=%d", season]];
		if(ep != 0)
			[reqComp addObject:[NSString stringWithFormat:@"ep=%d", ep]];
		if(showName != 0)
			[reqComp addObject:[NSString stringWithFormat:@"showname=%@", showName]];
	}
	else if([currentPlayFile fileClassValue] == FileClassMovie)
	{
		fileClass=2;
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/movie.php"]];
		SapphireMovie *movie = [currentPlayFile movie];
		NSString *movieTitle=[movie title];
		int movieID=[movie imdbNumberValue];
		NSDate * releaseDate=[movie releaseDate];
		if(movieTitle != 0)
			[reqComp addObject:[NSString stringWithFormat:@"title=%@", movieTitle]];
		if(releaseDate != 0)
			[reqComp addObject:[NSString stringWithFormat:@"year=%@", [releaseDate descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]]];
		if(movieID != 0)
			[reqComp addObject:[NSString stringWithFormat:@"movieid=%d", movieID]];
	}
	else
	{
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/ext.php"]];
		//The fileClass is never used in these cases later
		//				if([currentPlayFile fileClassValue] == FileClassUnknown)
		//					 fileClass=0;
		//				if([currentPlayFile fileClassValue] == FileClassAudio)
		//					 fileClass=3;
		if([currentPlayFile fileClassValue] == FileClassOther)
			fileClass=5;
		else
			fileClass=99;
	}
	
	if(ext!=0)
	{
		[reqComp addObject:[NSString stringWithFormat:@"filetype=%d",fileClass]];
		[reqComp addObject:[NSString stringWithFormat:@"extension=%@", ext]];
		if([SapphireFrontRowCompat usingATypeOfTakeTwo])
			[reqComp addObject:[NSString stringWithFormat:@"ckey=ATVT2-%@-%d",ext,fileClass]];
		else if([SapphireFrontRowCompat usingLeopard])
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

- (void)playFile:(SapphireFileMetaData *)currentPlayFile
{
	NSString *path = [currentPlayFile path];
	if(![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		NSString *errorTitle = BRLocalizedString(@"File Not Present", @"File Not Present title");
		NSString *errorString = [NSString stringWithFormat:BRLocalizedString(@"The File %@ is not present.  Either a drive is not mounted or your metadata has not been imported recently", @"File not present error string"), path];
		SapphireErrorDisplayController *display = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:errorTitle longError:errorString];
		[[self stack] pushController:display];
		[display release];
		return;
	}
	if([currentPlayFile updateMetaData])
		[SapphireMetaDataSupport save:[currentPlayFile managedObjectContext]];
	
	
	/*Anonymous reporting*/
	SapphireSettings *settings = [SapphireSettings sharedSettings];
	if(![settings disableAnonymousReporting])
	{
		[self anonymousReportFile:currentPlayFile withPath:path];
	}
	
	if([currentPlayFile fileContainerTypeValue] == FileContainerTypeVideoTS && path != nil)
	{
		SapphireCMPWrapper *wrapper = [[SapphireCMPWrapper alloc] initWithFile:currentPlayFile scene:[self scene]];
		id controller = [wrapper controller];
		[wrapper release];
//			SapphireErrorDisplayController *controller = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Playback Error", @"Short error indicating an error while playing a file") longError:BRLocalizedString(@"DVD Playback is not supported on the AppleTV", @"Error message saying DVD on ATV not supported")];
		[[self stack] pushController:controller];
	}
	else if([[NSFileManager defaultManager] acceptFilePath:path] && [currentPlayFile hasVideoValue])
	{
		/*Video*/
		/*Set the asset resume time*/
		NSURL *url = [NSURL fileURLWithPath:path];
		SapphireMedia *asset  =[[SapphireMedia alloc] initWithMediaURL:url];
		[asset setResumeTime:[currentPlayFile resumeTimeValue]];
		[asset setFileMetaData:currentPlayFile];
		
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
	else if(path != nil)
	{
		/*Audio*/
		/*Set the asset*/
		NSURL *url = [NSURL fileURLWithPath:path];
		SapphireAudioMedia *asset  =[[SapphireAudioMedia alloc] initWithMediaURL:url];
		[asset setResumeTime:[currentPlayFile resumeTimeValue]];
		[asset setFileMetaData:currentPlayFile];
		
		SapphireAudioPlayer *player = [[SapphireAudioPlayer alloc] init];
		/*and go*/
		BRMusicNowPlayingController *controller;
		if([SapphireFrontRowCompat usingLeopardOrATypeOfTakeTwo])
			controller = [[SapphireAudioNowPlayingController alloc] initWithPlayer:player];
		else
		{
			controller = [[BRMusicNowPlayingController alloc] initWithScene:[self scene]];
			[controller setPlayer:player];
		}
		NSError *error = nil;
		[player setMedia:asset inTracklist:[NSArray arrayWithObject:asset] error:&error];
		[player play];
		[SapphireApplianceController setMusicNowPlayingController:controller];
		[[self stack] pushController:controller];
		
		[asset release];
		[player release];
		[controller release];
	}
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
		/*First stop any music*/
		[SapphireApplianceController setMusicNowPlayingController:nil];
		/*Play the file*/
		[self playFile:[metaData metaDataForFile:name]];
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
		[preview setShowsMetadataImmediately:YES];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventRemoteAction remoteAction = [SapphireFrontRowCompat remoteActionForEvent:event];
	if ([(BRControllerStack *)[self stack] peekController] != self)
		remoteAction = 0;
		
	int row = [self getSelection];
	
	switch (remoteAction)
	{
		case kBREventRemoteActionRight:
		case kBREventRemoteActionSwipeRight:
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
			[(SapphireMarkMenu *)controller setListTitle:[name lastPathComponent]];
			[[self stack] pushController:controller];
			[controller release];
			return YES;
		}
		case kBREventRemoteActionLeft:
		case kBREventRemoteActionSwipeLeft:
		{
			id controller = [[SapphireDisplayMenu alloc] initWithScene:[self scene] directory:metaData];
			[(SapphireDisplayMenu *)controller setListTitle:[self listTitle]];
			[[self stack] pushController:controller];
			[controller release];				
			return YES;
		}
		default:
			break;
	}
	return [super brEventAction:event];
}

- (void)updateCompleteForFile:(NSString *)file
{
	/*Get the file*/
	[items removeObjectForKey:file];
	/*Relead the list and render*/
	BRListControl *list = [self list];
	[list reload];
	/*Reload the preview pane*/
	[self resetPreviewController];
	[SapphireFrontRowCompat renderScene:[self scene]];
}

@end
