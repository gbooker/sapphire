//
//  SapphireBrowser.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

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
#import "SapphireFrontRowCompat.h"

#import <AudioUnit/AudioUnit.h>
#import <objc/objc-class.h>

#define PASSTHROUGH_KEY		(CFStringRef)@"attemptPassthrough"
#define A52_DOMIAN			(CFStringRef)@"com.cod3r.a52codec"

@interface SapphireBrowser (private)
- (void)reloadDirectoryContents;
- (void)processFiles:(NSArray *)files;
- (void)filesProcessed:(NSDictionary *)files;
- (NSMutableDictionary *)metaDataForPath:(NSString *)path;
- (void)setNewPredicate:(SapphirePredicate *)newPredicate;
@end

@interface BRTVShowsSortControl (bypassAccess)
- (BRTVShowsSortSelectorStateLayer *)gimmieDate;
- (BRTVShowsSortSelectorStateLayer *)gimmieShow;
- (int)gimmieState;
@end

@interface BRTVShowsSortSelectorStateLayer (bypassAccess)
- (BRTextLayer *)gimmieDate;
- (BRTextLayer *)gimmieShow;
@end

@interface BRMusicNowPlayingController (bypassAccess)
- (void)setPlayer:(BRMusicPlayer *)player;
- (BRMusicPlayer *)player;
@end

/*Private variables access, but only on BR 1.0; not used otherwise*/
@implementation BRTVShowsSortControl (bypassAccess)
- (BRTVShowsSortSelectorStateLayer *)gimmieDate
{
	return _sortedByDateWidget;
}

- (BRTVShowsSortSelectorStateLayer *)gimmieShow
{
	return _sortedByShowWidget;
}

- (int)gimmieState
{
	return _state;
}

@end

@implementation BRTVShowsSortSelectorStateLayer (bypassAccess)
- (BRTextLayer *)gimmieDate
{
	return _dateLayer;
}

- (BRTextLayer *)gimmieShow
{
	return _showLayer;
}

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

/*!
 * @brief Replace the text in a control with a string
 *
 * @param control The control on which to change the text
 * @param str The text to put into tho control
 */
- (void)replaceControlText:(BRTextLayer *)control withString:(NSString *)str
{
	/*Create a mutable copy of the control's attributed string*/
	NSMutableAttributedString  *dateString = [[control attributedString] mutableCopy];
	[dateString replaceCharactersInRange:NSMakeRange(0, [dateString length]) withString:str];
	/*Set the new string and we are done with it*/
	[control setAttributedString:dateString];
	[dateString release];
}

/*!
 * @brief Creates the mode control in a compatible way
 *
 * @param scene The scene
 * @param names The names in the menu
 *
- (void)createModeControlWithScene:(BRRenderScene *)scene names:(NSArray *)names
{
	/*Check for the new way to do this*
	Class modeClass = NSClassFromString(@"BRSegmentedSortControl");
	if(modeClass != nil)
		/*Use the new method*
		//Ignore this warning if compiling with backrow 1.0
		modeControl = [[modeClass alloc] initWithScene:scene segmentNames:names selectedSegment:0];
	else
	{
		/*Hack in the old way*
		modeControl = [[BRTVShowsSortControl alloc] initWithScene:scene state:1];
		NSString *name1 = [names objectAtIndex:0];
		NSString *name2 = [names objectAtIndex:1];
		[self replaceControlText:[[modeControl gimmieDate] gimmieDate] withString:name1];
		[self replaceControlText:[[modeControl gimmieDate] gimmieShow] withString:name2];
		[self replaceControlText:[[modeControl gimmieShow] gimmieDate] withString:name1];
		[self replaceControlText:[[modeControl gimmieShow] gimmieShow] withString:name2];
		is10Version = YES;
	}
}

/*!
 * @brief Creates a new predicated browser
 *
 * @param scene The scene
 * @praam meta The metadata for the directory to browse
 * @param newPredicate The predicate to use
 * @return The Browser
 */
- (id) initWithScene: (BRRenderScene *) scene metaData: (SapphireDirectoryMetaData *)meta
{
	if ( [super initWithScene: scene] == nil ) return ( nil );
		
	_names = [NSMutableArray new];
	items = [NSMutableArray new];
	metaData = [meta retain];
	[metaData setDelegate:self];
	predicate = [[SapphireApplianceController predicate] retain];

	/*Create the mode menu*/
/*	NSArray *names = [NSArray arrayWithObjects:
		BRLocalizedString(@"Select", @"Select Menu Item"),
		BRLocalizedString(@"Mark File", @"Mark File Menu Item"),
		BRLocalizedString(@"Filter", @"Filter Menu Item"),
		nil];
	[self createModeControlWithScene:scene names:names];
	[self addControl:modeControl];*/
	
	// set the datasource *after* you've setup your array
	[[self list] setDatasource: self] ;
		
	return ( self );
}

/*!
 * @brief Override the layout
 *
- (void)_doLayout
{
	[super _doLayout];
	NSRect listFrame = [[_listControl layer] frame];
	/*Position the mode menu below the list*
	NSRect modeRect;
	modeRect.size = [modeControl preferredSizeForScreenHeight:[self masterLayerFrame].size.height];
	modeRect.origin.y = listFrame.origin.y * 1.5f;
	modeRect.origin.x = (listFrame.size.width - modeRect.size.width)/2 + listFrame.origin.x;
	/*Shrink the list to make room for the mode*
	listFrame.size.height -= listFrame.origin.y;
	listFrame.origin.y *= 2;
	[[_listControl layer] setFrame:listFrame];
	[modeControl setFrame:modeRect];
}

/*!
 * @brief Reload the display
 */
- (void)reloadDirectoryContents
{
	/*Tell the metadata to get new data*/
	[metaData reloadDirectoryContents];
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
			[_names addObject:BRLocalizedString(@"< Scan for new files >", @"Conduct a scan of the directory for new files")];
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

- (void) dealloc
{
    // always remember to deallocate your resources
	[_names release];
	[items release];
	[metaData release];
	[predicate release];
//	[modeControl release];
    [super dealloc];
}

- (void) willBePushed
{
    // We're about to be placed on screen, but we're not yet there
    
    // always call super
    [super willBePushed];
	/*Reload upon display*/
	[self setNewPredicate:[SapphireApplianceController predicate]];
}

- (void) wasPushed
{
    // We've just been put on screen, the user can see this controller's content now
    
    // always call super
    [super wasPushed];
	/*Get metadata when we can*/
	[metaData resumeDelayedImport];
}

- (void) willBePopped
{
    // The user pressed Menu, but we've not been removed from the screen yet
    
    // always call super
    [super willBePopped];
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	[metaData setDelegate:nil];
}

- (void) wasPopped
{
    // The user pressed Menu, removing us from the screen
    // always call super
    [super wasPopped];
}

- (void) willBeBuried
{
    // The user just chose an option, and we will be taken off the screen
    
	/*Cancel everything we were doing*/
	[metaData cancelImport];
	cancelScan = YES;
	// always call super
    [super willBeBuried];
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
    // The user chose an option and this controller is no longer on screen
    
    // always call super
    [super wasBuriedByPushingController: controller];
}

- (void) willBeExhumed
{
    // the user pressed Menu, but we've not been revealed yet
    
	/*Check to see if the user stopped playing something*/
	id controller = [[self stack] peekController];
	float elapsed = 0.0;
	float duration = 0.0000001; //prevent a div by 0
	if([controller isKindOfClass:[BRVideoPlayerController class]])
	{
		/*Check for 90% completion*/
		BRVideoPlayer *player = [(BRVideoPlayerController *)controller player];
		elapsed = [player elapsedPlaybackTime];
		duration = [player trackDuration];
	}
	else if([controller isKindOfClass:[BRMusicNowPlayingController class]])
	{
		BRMusicPlayer *player = [(BRMusicNowPlayingController *)controller player];
		elapsed = [player elapsedPlaybackTime];
		duration = [player trackDuration];
		[player stop];
	}
	if(elapsed / duration > 0.9f)
		/*Mark as watched and reload info*/
		[currentPlayFile setWatched:YES];
	
	/*Get the resume time to save*/
	if(elapsed < duration - 2)
		[currentPlayFile setResumeTime:elapsed];
	else
		[currentPlayFile setResumeTime:0];
	[currentPlayFile writeMetaData];

	/*cleanup*/
	[currentPlayFile release];
	currentPlayFile = nil;
	/*Reload our display*/
	[self setNewPredicate:[SapphireApplianceController predicate]];
    // always call super
    [super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
    // handle being revealed when the user presses Menu
    
    // always call super
    [super wasExhumedByPoppingController: controller];
	/*Check to see if dir is empty*/
	if(fileCount + dirCount == 0)
		[[self stack] popController];
	else
		/*Resume importing now that we are up again*/
		[metaData resumeDelayedImport];
	//Turn off the AC3 Passthrough hack
	CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:0], A52_DOMIAN);
	CFPreferencesAppSynchronize(A52_DOMIAN);
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
/*
    // build a BRTextMenuItemLayer or a BRAdornedMenuItemLayer, etc. here
    // return that object, it will be used to display the list item.
    return ( nil );
*/
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
	BOOL gear = NO;
	BRRenderScene *scene = [self scene];
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
			if(fileCls==FILE_CLASS_TV_SHOW)
			{
				/*Display episode number if availble*/
				int eps= [meta episodeNumber] ;
				displayName=[meta episodeTitle] ;
				if(eps>0)
					[SapphireFrontRowCompat setRightJustifiedText:[NSString stringWithFormat:@" %02d",eps] forMenu:result];
				else
					/*Fallback to size*/
					[SapphireFrontRowCompat setRightJustifiedText:[meta sizeString] forMenu:result];
			}
			if(fileCls==FILE_CLASS_MOVIE)
			{
				displayName=[meta movieTitle] ;
			}
			watched = [meta watched];
			favorite = [meta favorite] ;
		}
	}
	/*Utility*/
	else
	{
		result = [SapphireFrontRowCompat textMenuItemForScene:scene folder:NO];
		gear = YES;
	}
	/*Add icons*/
	SapphireTheme *theme = [SapphireTheme sharedTheme];
	if(gear) [SapphireFrontRowCompat setLeftIcon:[theme gem:GEAR_GEM_KEY] forMenu:result];
	else if(!watched) [SapphireFrontRowCompat setLeftIcon:[theme gem:BLUE_GEM_KEY] forMenu:result];
	else if(favorite) [SapphireFrontRowCompat setLeftIcon:[theme gem:YELLOW_GEM_KEY] forMenu:result];
	else if(fileCls==FILE_CLASS_AUDIO)[SapphireFrontRowCompat setLeftIcon:[theme gem:GREEN_GEM_KEY] forMenu:result];
	else [SapphireFrontRowCompat setLeftIcon:[theme gem:RED_GEM_KEY] forMenu:result];
			
	// add text
	if(displayName)name= displayName ;
	name=[@"   " stringByAppendingString: name] ;
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

BOOL findCorrectDescriptionForStream(AudioStreamID streamID, int sampleRate)
{
	OSStatus err;
	UInt32 propertySize = 0;
	err = AudioStreamGetPropertyInfo(streamID, 0, kAudioStreamPropertyPhysicalFormats, &propertySize, NULL);
	
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioStreamBasicDescription *descs = malloc(propertySize);
	if(descs == NULL)
		return NO;
	
	int formatCount = propertySize / sizeof(AudioStreamBasicDescription);
	err = AudioStreamGetProperty(streamID, 0, kAudioStreamPropertyPhysicalFormats, &propertySize, descs);
	
	if(err != noErr)
	{
		free(descs);
		return NO;
	}
	
	int i;
	BOOL ret = NO;
	for(i=0; i<formatCount; i++)
	{
		if (descs[i].mBitsPerChannel == 16 && descs[i].mFormatID == kAudioFormatLinearPCM)
		{
			if(descs[i].mSampleRate == sampleRate)
			{
				err = AudioStreamSetProperty(streamID, NULL, 0, kAudioStreamPropertyPhysicalFormat, sizeof(AudioStreamBasicDescription), descs + i);
				if(err != noErr)
					continue;
				ret = YES;
				break;
			}
		}
	}
	free(descs);
	return ret;
}

BOOL setupDevice(AudioDeviceID devID, int sampleRate)
{
	OSStatus err;
	UInt32 propertySize = 0;
	err = AudioDeviceGetPropertyInfo(devID, 0, FALSE, kAudioDevicePropertyStreams, &propertySize, NULL);
	
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioStreamID *streams = malloc(propertySize);
	if(streams == NULL)
		return NO;
	
	int streamCount = propertySize / sizeof(AudioStreamID);
	err = AudioDeviceGetProperty(devID, 0, FALSE, kAudioDevicePropertyStreams, &propertySize, streams);
	if(err != noErr)
	{
		free(streams);
		return NO;
	}
	
	int i;
	BOOL ret = NO;
	for(i=0; i<streamCount; i++)
	{
		if(findCorrectDescriptionForStream(streams[i], sampleRate))
		{
			ret = YES;
			break;
		}
	}
	free(streams);
	return ret;
}

BOOL setupAudioOutput(int sampleRate)
{
	OSErr err;
	UInt32 propertySize = 0;
	
	err = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, NULL);
	if(err != noErr || propertySize == 0)
		return NO;
	
	AudioDeviceID *devs = malloc(propertySize);
	if(devs == NULL)
		return NO;
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, devs);
	if(err != noErr)
	{
		free(devs);
		return NO;
	}
	
	int i, devCount = propertySize/sizeof(AudioDeviceID);
	BOOL ret = NO;
	for(i=0; i<devCount; i++)
	{
		if(setupDevice(devs[i], sampleRate))
		{
			err = AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, sizeof(AudioDeviceID), devs + i);
			if(err != noErr)
				continue;
			ret = YES;
			break;
		}
	}
	free(devs);
	return ret;
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
		[controller setListTitle:name];
		[controller setListIcon:[self listIcon]];
		[[self stack] pushController:controller];
		[controller release];
	}
	else if(row < dirCount + fileCount)
	{
		/*Play the file*/
		currentPlayFile = [[metaData metaDataForFile:name] retain];
		
		NSString *path = [currentPlayFile path];
		
		/*Anonymous reporting*/
		SapphireSettings *settings = [SapphireSettings sharedSettings];
		if(![settings disableAnonymousReporting])
		{
			NSMutableString *reqData = [NSMutableString string];
			NSMutableArray *reqComp = [NSMutableArray array];
			NSMutableURLRequest *request=nil;
			
			if([currentPlayFile fileClass]==FILE_CLASS_TV_SHOW)
			{
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
				if(path != 0)
					[reqComp addObject:[NSString stringWithFormat:@"path=%@", [path lastPathComponent]]];
			}
			else if([currentPlayFile fileClass]==FILE_CLASS_MOVIE)
			{
				request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://appletv.nanopi.net/movie.php"]];
				NSString *movieTitle=[currentPlayFile movieTitle];
				NSDate * releaseDate=[currentPlayFile movieReleaseDate];
			
 				if(movieTitle != 0)
					[reqComp addObject:[NSString stringWithFormat:@"title=%@", movieTitle]];
				if(releaseDate != 0)
					[reqComp addObject:[NSString stringWithFormat:@"year=%@", [releaseDate descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]]];
				if(path != 0)
					[reqComp addObject:[NSString stringWithFormat:@"path=%@", [path lastPathComponent]]];
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
		
		/*AC3 passthrough*/
		BOOL useAC3Passthrough = NO;
		if([currentPlayFile updateMetaData])
			[currentPlayFile writeMetaData];
		if([settings useAC3Passthrough])
		{
			Float64 sampleRate = [currentPlayFile sampleRate];
			UInt32 type = [currentPlayFile audioFormatID];
			
			if((type == 'ac-3' || type == 0x6D732000) && setupAudioOutput((int)sampleRate))
				useAC3Passthrough = YES;
		}
		
		if(useAC3Passthrough)
			CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:1], A52_DOMIAN);			
		else
			CFPreferencesSetAppValue(PASSTHROUGH_KEY, (CFNumberRef)[NSNumber numberWithInt:0], A52_DOMIAN);
		CFPreferencesAppSynchronize(A52_DOMIAN);
		
		if([[SapphireMetaData videoExtensions] containsObject:[path pathExtension]] && [currentPlayFile hasVideo])
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
			BRVideoPlayerController *controller = [BRVideoPlayerController alloc];
			if([controller respondsToSelector:@selector(initWithScene:)])
				controller = [controller initWithScene:[self scene]];
			else
				controller = [controller init];
			[controller setAllowsResume:YES];
			[controller setVideoPlayer:player];
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

/*!
 * @brief Finished scanning the dir
 *
 * @param subs nil in this case
 */
- (void)gotSubFiles:(NSArray *)subs
{
	[self reloadDirectoryContents];	
}

/*!
* @brief Meta data delegate method to inform on its scanning progress
 *
 * @param dir The current directory it is scanning
 */
- (void)scanningDir:(NSString *)dir
{
}

/*!
 * @brief Check to see if the scan should be canceled
 *
 * @return YES if the scan should be canceled
 */
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
			[preview setMetaData:[metaData metaDataForDirectory:name]];
		else
			[preview setMetaData:[metaData metaDataForFile:name]];
		[preview setShowsMetadataImmediately:NO];
		/*And go*/
		return [preview autorelease];
	}
    return ( nil );
}

- (int)getSelection
{
	BRListControl *list = [self list];
	int row;
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(selection)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(selection)];
	[selInv invokeWithTarget:list];
	if([signature methodReturnLength] == 8)
	{
		double retDoub = 0;
		[selInv getReturnValue:&retDoub];
		row = retDoub;
	}
	else
		[selInv getReturnValue:&row];
	return row;
}

- (BOOL)brEventAction:(BREvent *)event
{
	/*Cancel imports on an action*/
	[metaData resumeDelayedImport];
	
	BREventPageUsageHash hashVal = [event pageUsageHash];
	if ([(BRControllerStack *)[self stack] peekController] != self)
		hashVal = 0;
	
	switch (hashVal)
	{
		case kBREventTapRight:
		{
			id meta = nil;
			int row = [self getSelection];
			if(row > [_names count])
				return NO;
			
			NSString *name = [_names objectAtIndex:row];
			
			/*Get metadata*/
			if(row < dirCount)
				meta = [metaData metaDataForDirectory:name];
			else if (row < dirCount + fileCount)
				meta = [metaData metaDataForFile:name];
			else
				return NO;
			/*Do mark menu*/
			id controller = [[SapphireMarkMenu alloc] initWithScene:[self scene] metaData:meta];
			[(SapphireMarkMenu *)controller setPredicate:predicate];
			[[self stack] pushController:controller];
			[controller release];
			return YES;
		}
		case kBREventTapLeft:
			[self setNewPredicate:[SapphireApplianceController nextPredicate]];
			return YES;
		default:
			return [super brEventAction:event];
	}
	return NO;
}

/*!
 * @brief The import on a file completed
 *
 * @param file Filename to the file which completed
 */
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
