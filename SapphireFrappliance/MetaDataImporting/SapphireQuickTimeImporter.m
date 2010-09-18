//
//	SapphireQuickTimeImporter.m
//	Sapphire
//
//	Created by Thomas Cool on 7/20/10.
//	Copyright 2010 tomcool.org. All rights reserved.
//

#import "SapphireQuickTimeImporter.h"
#import "SapphireFileMetaData.h"
#import "SapphireQTMovieParser.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireEpisode.h"
#import "SapphireMovie.h"

@implementation SapphireQuickTimeImporter

NSSet *validExtensions;

+ (void)initialize
{
	validExtensions = [[NSSet alloc] initWithObjects:@"m4v", @"m4a", @"mp4", @"mov", nil];
}

- (id)init
{
	self = [super init];
	if(!self)
		return self;
	
	return self;
}

- (BOOL)stillNeedsDisplayOfChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
	//No choosers displayed
	return NO;
}

- (void)exhumedChooser:(BRLayerController <SapphireChooser> *)chooser withContext:(id)context
{
}

- (void)setDelegate:(id <SapphireImporterDelegate>)delegate
{
	//No backgrounding here, so we don't need to tell the delegate anything
}

- (void)cancelImports
{
	//No backgrounding here, so nothing to do
}

- (NSString *)completionText
{
	return BRLocalizedString(@"All available metadata has been imported", @"The group metadata import complete");
}

- (NSString *)initialText
{
	return BRLocalizedString(@"Import Quicktime Metadata", @"Title");
}

- (NSString *)informativeText
{
	return BRLocalizedString(@"This tool will import all the metadata included in the media files supported by QT such as m4v", @"Description of QT meta import");
}

- (NSString *)buttonTitle
{
	return BRLocalizedString(@"Start Importing Data", @"Button");
}

- (ImportState)importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path
{
	if([metaData importTypeValue] & ImportTypeMaskQT)
		return ImportStateNotUpdated;
	
	if(![validExtensions containsObject:[[path pathExtension] lowercaseString]])
	{
		[metaData didImportType:ImportTypeMaskQT];
		return ImportStateNotUpdated;
	}
	
	SapphireQTMovieParser *parser = [[SapphireQTMovieParser alloc] initWithFile:path];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	NSDictionary *info = [parser info];
	id value = [info objectForKey:TC_QT_TITLE];
	if(value != nil) 
		[dict setObject:value forKey:META_TITLE_KEY];
	
	value = [info objectForKey:TC_QT_LONG_DESC];
	if(value == nil)
		value = [info objectForKey:TC_QT_DESC];
	if(value != nil)
	{
		[dict setObject:value forKey:META_SUMMARY_KEY];
		[dict setObject:value forKey:META_MOVIE_PLOT_KEY];
	}

	value = [info objectForKey:TC_QT_TV_SEASON_NB];
	if(value != nil)
		[dict setObject:value forKey:META_SEASON_NUMBER_KEY];
	
	value = [info objectForKey:TC_QT_TV_EPISODE_NB];
	if(value != nil)
		[dict setObject:value forKey:META_EPISODE_NUMBER_KEY];
	
	value = [info objectForKey:TC_QT_TV_SHOW];
	if(value != nil)
		[dict setObject:value forKey:META_SHOW_NAME_KEY];
	
	value = [info objectForKey:TC_QT_RELEASE];
	if(value != nil)
	{
		[dict setObject:value forKey:META_SHOW_AIR_DATE];
		[dict setObject:value forKey:META_MOVIE_RELEASE_DATE_KEY];
	}

	int type = [[info valueForKey:TC_QT_TYPE] intValue];
	if(type==9)
		[dict setObject:[NSNumber numberWithInt:FileClassMovie] forKey:FILE_CLASS_KEY];
	else if(type==10) 
		[dict setObject:[NSNumber numberWithInt:FileClassTVShow] forKey:FILE_CLASS_KEY];

	value = [info objectForKey:TC_QT_COPYRIGHT];
	if(value != nil)
		[dict setObject:value forKey:META_COPYRIGHT_KEY];

	value = [info objectForKey:TC_QT_TV_NETWORK];
	if(value != nil)
		[dict setObject:value forKey:META_SHOW_BROADCASTER_KEY];
	
	BOOL doImport = YES;
	if(type==10)
	{
		if([metaData importTypeValue] & ImportTypeMaskTVShow)
			doImport = NO;
	}
	else if(type == 9)
	{
		if([metaData importTypeValue] & ImportTypeMaskMovie)
			doImport = NO;
	}

	NSManagedObjectContext *moc = [metaData managedObjectContext];
	if(doImport)
	{
		if(type==10) 
		{
			SapphireEpisode *ep = [SapphireEpisode episodeWithDictionaries:[NSArray arrayWithObject:dict] inContext:moc];
			metaData.tvEpisode = ep;
		}
		else if(type==9)
		{
			SapphireMovie *mv = [SapphireMovie movieWithDictionary:dict inContext:moc];
			metaData.movie = mv;
		}
	}
	[dict release];
	[parser release];
	[metaData didImportType:ImportTypeMaskQT];
	return ImportStateUpdated;
}

@end
