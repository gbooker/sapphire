#import "SapphireFileMetaData.h"
#import "SapphireXMLData.h"
#import "SapphireMovie.h"
#import "SapphireEpisode.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireVideoTsParser.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireMediaPreview.h"
#import "SapphireFileSymLink.h"
#import "SapphireSettings.h"
#import "CoreDataSupportFunctions.h"

#import "SapphireTVShow.h"
#import "SapphireSeason.h"
#import "SapphireTVTranslation.h"
#import "SapphireMovieTranslation.h"

#import "NSArray-Extensions.h"
#import "NSString-Extensions.h"

#import <QTKit/QTKit.h>

@implementation SapphireFileMetaData

//ATV Extra Info
NSString *META_SHOW_BROADCASTER_KEY =		@"Broadcast Company";
NSString *META_SHOW_PUBLISHED_DATE_KEY =	@"Published Date";
NSString *META_SHOW_AQUIRED_DATE =			@"Date Aquired";
NSString *META_SHOW_RATING_KEY =			@"Rating";
NSString *META_SHOW_FAVORITE_RATING_KEY =	@"User Rating";
NSString *META_COPYRIGHT_KEY =				@"Copyright";

//General Keys
NSString *META_TITLE_KEY =					@"Title";
NSString *META_DESCRIPTION_KEY =			@"Show Description";
NSString *META_SUMMARY_KEY =				@"Summary";
NSString *META_RATING_KEY =					@"Rating";
NSString *FILE_CLASS_KEY =					@"File Class";

//IMDB Type Info
NSString *META_MOVIE_TITLE_KEY =				@"Title";
NSString *META_MOVIE_CAST_KEY =					@"Cast";
NSString *META_MOVIE_RELEASE_DATE_KEY =			@"Release Date";
NSString *META_MOVIE_DIRECTOR_KEY =				@"Director";
NSString *META_MOVIE_WIRTERS_KEY =				@"Writers";
NSString *META_MOVIE_GENRES_KEY =				@"Genres";
NSString *META_MOVIE_PLOT_KEY =					@"Plot";
NSString *META_MOVIE_IMDB_RATING_KEY =			@"IMDB Rating";
NSString *META_MOVIE_IMDB_250_KEY =				@"IMDB Top 250";
NSString *META_MOVIE_MPAA_RATING_KEY =			@"MPAA Rating";
NSString *META_MOVIE_OSCAR_KEY =				@"Oscars";
NSString *META_MOVIE_IDENTIFIER_KEY =			@"Movie ID";
NSString *META_SEARCH_IMDB_NUMBER_KEY =			@"Search IMDB Number";
NSString *META_MOVIE_SORT_TITLE_KEY =			@"Movie Sort Title";

//TV Show Specific Keys
NSString *META_SEASON_NUMBER_KEY =			@"Season";
NSString *META_EPISODE_NUMBER_KEY =			@"Episode";
NSString *META_SHOW_NAME_KEY =				@"Show Name";
NSString *META_SHOW_AIR_DATE =				@"Air Date";
NSString *META_ABSOLUTE_EP_NUMBER_KEY =		@"Episode Number";
NSString *META_SHOW_IDENTIFIER_KEY =		@"Show ID";
NSString *META_EPISODE_2_NUMBER_KEY =		@"Episode 2";
NSString *META_ABSOLUTE_EP_2_NUMBER_KEY =	@"Episode Number 2";
NSString *META_SEARCH_SEASON_NUMBER_KEY =	@"Search Season";
NSString *META_SEARCH_EPISODE_NUMBER_KEY =	@"Search Episode";
NSString *META_SEARCH_EPISODE_2_NUMBER_KEY =	@"Search Episode 2";

//File Specific Keys
NSString *META_FILE_MODIFIED_KEY =				@"Modified";
NSString *META_FILE_WATCHED_KEY = 				@"Watched";
NSString *META_FILE_FAVORITE_KEY = 				@"Favorite";
NSString *META_FILE_RESUME_KEY = 				@"Resume Time";
NSString *META_FILE_SIZE_KEY = 					@"Size";
NSString *META_FILE_DURATION_KEY = 				@"Duration";
NSString *META_FILE_AUDIO_DESC_KEY = 			@"Audio Description";
NSString *META_FILE_SAMPLE_RATE_KEY = 			@"Sample Rate";
NSString *META_FILE_VIDEO_DESC_KEY = 			@"Video Description";
NSString *META_FILE_AUDIO_FORMAT_KEY = 			@"Audio Format";
NSString *META_FILE_SUBTITLES_KEY = 			@"Subtitles";
NSString *META_FILE_JOINED_FILE_KEY = 			@"Joined File";

static NSSet *displayedMetaData;
static NSArray *displayedMetaDataOrder;
static NSSet *secondaryFiles;

+ (void)load
{
	displayedMetaDataOrder = [[NSArray alloc] initWithObjects:
							  META_MOVIE_IMDB_250_KEY,
							  META_MOVIE_IMDB_RATING_KEY,					  
							  META_MOVIE_DIRECTOR_KEY,
							  META_MOVIE_CAST_KEY,
							  META_MOVIE_GENRES_KEY,
							  META_EPISODE_AND_SEASON_KEY,
							  META_SEASON_NUMBER_KEY,
							  META_EPISODE_NUMBER_KEY,
							  META_MOVIE_IMDB_STATS_KEY,
							  META_FILE_SIZE_KEY,
							  META_FILE_DURATION_KEY,
							  VIDEO_DESC_LABEL_KEY,
							  VIDEO2_DESC_LABEL_KEY,
							  AUDIO_DESC_LABEL_KEY,
							  AUDIO2_DESC_LABEL_KEY,
							  META_FILE_SUBTITLES_KEY,
							  nil];
	displayedMetaData = [[NSSet alloc] initWithArray:displayedMetaDataOrder];
	secondaryFiles = [[NSSet alloc] initWithObjects:
					  @"xml",
					  @"srt",
					  @"sub",
					  @"idx",
					  @"ass",
					  @"ssa",
					  nil];
}

+ (SapphireFileMetaData *)fileWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	SapphireMetaData *meta = [SapphireMetaData metaDataWithPath:path inContext:moc];
	if([meta isKindOfClass:[SapphireFileMetaData class]])
		return (SapphireFileMetaData *)meta;
	return nil;
}

+ (SapphireFileMetaData *)internalCreateFileWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc
{
	SapphireFileMetaData *ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireFileMetaDataName inManagedObjectContext:moc];
	ret.parent = parent;
	ret.path = path;
	
	return ret;
}

+ (SapphireFileMetaData *)createFileWithPath:(NSString *)path inContext:(NSManagedObjectContext *)moc
{
	SapphireFileMetaData *ret = [SapphireFileMetaData fileWithPath:path inContext:moc];
	if(ret != nil)
		return ret;
	
	SapphireDirectoryMetaData *parent = [SapphireDirectoryMetaData createDirectoryWithPath:[path stringByDeletingLastPathComponent] inContext:moc];
	ret = [SapphireFileMetaData internalCreateFileWithPath:path parent:parent inContext:moc];
	
	return ret;
}

+ (SapphireFileMetaData *)createFileWithPath:(NSString *)path parent:(SapphireDirectoryMetaData *)parent inContext:(NSManagedObjectContext *)moc
{
	SapphireFileMetaData *ret = [SapphireFileMetaData fileWithPath:path inContext:moc];
	if(ret != nil)
		return ret;
	
	return [SapphireFileMetaData internalCreateFileWithPath:path parent:parent inContext:moc];
}

+ (NSDictionary *)upgradeV1FilesFromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc withMovies:(NSDictionary *)movieLookup directories:(NSDictionary *)dirLookup
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSArray *files = doFetchRequest(SapphireFileMetaDataName, oldMoc, nil);
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSManagedObject *oldFile;
	while((oldFile = [fileEnum nextObject]) != nil)
	{
		SapphireFileMetaData *newFile = [NSEntityDescription insertNewObjectForEntityForName:SapphireFileMetaDataName inManagedObjectContext:newMoc];
		NSString *path = [oldFile valueForKey:@"path"];
		newFile.path = path;
		newFile.parent = [dirLookup objectForKey:[oldFile valueForKeyPath:@"parent.path"]];
		newFile.audioDescription = [oldFile valueForKey:@"audioDescription"];
		newFile.audioFormatID = [oldFile valueForKey:@"audioFormatID"];
		newFile.duration = [oldFile valueForKey:@"duration"];
		newFile.favorite = [oldFile valueForKey:@"favorite"];
		newFile.fileClass = [oldFile valueForKey:@"fileClass"];
		newFile.fileContainerType = [oldFile valueForKey:@"fileContainerType"];
		newFile.hasVideo = [oldFile valueForKey:@"hasVideo"];
		newFile.importTypeValue = [[oldFile valueForKey:@"importType"] intValue] & ~IMPORT_TYPE_XML_MASK;
		newFile.modified = [oldFile valueForKey:@"modified"];
		newFile.resumeTime = [oldFile valueForKey:@"resumeTime"];
		newFile.sampleRate = [oldFile valueForKey:@"sampleRate"];
		newFile.size = [oldFile valueForKey:@"size"];
		newFile.subtitlesDescription = [oldFile valueForKey:@"subtitlesDescription"];
		newFile.videoDescription = [oldFile valueForKey:@"videoDescription"];
		newFile.watched = [oldFile valueForKey:@"watched"];
		NSNumber *oldMovieNumber = [oldFile valueForKeyPath:@"movie.imdbNumber"];
		if(oldMovieNumber != nil)
			newFile.movie = [movieLookup objectForKey:oldMovieNumber];
		
		[lookup setObject:newFile forKey:path];
	}
	return lookup;
}

- (void)insertDictionary:(NSDictionary *)dict withDefer:(NSMutableDictionary *)defer
{
	self.audioDescription = [dict objectForKey:META_FILE_AUDIO_DESC_KEY];
	self.audioFormatID = [dict objectForKey:META_FILE_AUDIO_FORMAT_KEY];
	self.duration = [dict objectForKey:META_FILE_DURATION_KEY];
	self.favoriteValue = [[dict objectForKey:META_FILE_FAVORITE_KEY] boolValue];
	self.fileClass = [dict objectForKey:@"File Class"];
	self.fileContainerType = [dict objectForKey:@"File Container Type"];
	id value = [dict objectForKey:META_FILE_MODIFIED_KEY];
	if(value != nil)
		self.modified = [NSDate dateWithTimeIntervalSince1970:[value intValue]];
	self.resumeTimeValue = [[dict objectForKey:META_FILE_RESUME_KEY] unsignedIntValue];
	self.sampleRate = [dict objectForKey:META_FILE_SAMPLE_RATE_KEY];
	self.size = [dict objectForKey:META_FILE_SIZE_KEY];
	self.subtitlesDescription = [dict objectForKey:META_FILE_SUBTITLES_KEY];
	self.videoDescription = [dict objectForKey:META_FILE_VIDEO_DESC_KEY];
	self.watchedValue = [[dict objectForKey:META_FILE_WATCHED_KEY] boolValue];
	self.hasVideoValue = self.videoDescription != nil;
	value = [dict objectForKey:@"XML Source"];
	if(value != nil)
	{
		NSDictionary *xmlDict = (NSDictionary *)value;
		SapphireXMLData *xml = self.xmlData;
		if(xml == nil)
		{
			xml = [NSEntityDescription insertNewObjectForEntityForName:SapphireXMLDataName inManagedObjectContext:[self managedObjectContext]];
			self.xmlData = xml;
		}
		[xml insertDictionary:xmlDict];
		xml.modified = [NSDate dateWithTimeIntervalSince1970:[[xmlDict objectForKey:META_FILE_MODIFIED_KEY] intValue]];
		self.importTypeValue |= IMPORT_TYPE_XML_MASK;
	}
	value = [dict objectForKey:@"TVRage Source"];
	if(value != nil)
	{
		SapphireEpisode *ep = [SapphireEpisode episodeWithDictionary:(NSDictionary *)value inContext:[self managedObjectContext]];
		self.tvEpisode = ep;
		if(ep != nil)
		{
			self.fileClassValue = FILE_CLASS_TV_SHOW;
			NSString *epCoverPath = [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:[ep path]];
			NSString *oldBasePath = [[epCoverPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[self.path lastPathComponent]];
			NSString *oldCoverPath = searchCoverArtExtForPath([oldBasePath stringByDeletingPathExtension]);
			if(oldCoverPath != nil)
			{
				NSString *newPath = [epCoverPath stringByAppendingPathExtension:[oldCoverPath pathExtension]];
				NSFileManager *fm = [NSFileManager defaultManager];
				[fm movePath:oldCoverPath toPath:newPath handler:nil];
			}
		}
		self.importTypeValue |= IMPORT_TYPE_TVSHOW_MASK;
	}
	value = [dict objectForKey:@"IMDB Source"];
	if(value != nil)
	{
		SapphireMovie *movie = [SapphireMovie movieWithDictionary:(NSDictionary *)value inContext:[self managedObjectContext] lookup:defer];
		self.movie = movie;
		if(movie != nil)
		{
			self.fileClassValue = FILE_CLASS_MOVIE;
			NSString *movieCoverPath = [movie coverArtPath];
			NSString *oldBasePath = [[[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:@"@MOVIES"] stringByAppendingPathComponent:[self.path lastPathComponent]];
			NSString *oldCoverPath = searchCoverArtExtForPath([oldBasePath stringByDeletingPathExtension]);
			if(oldCoverPath != nil)
			{
				NSString *newPath = [movieCoverPath stringByAppendingPathExtension:[oldCoverPath pathExtension]];
				NSFileManager *fm = [NSFileManager defaultManager];
				[fm movePath:oldCoverPath toPath:newPath handler:nil];
			}
		}
		self.importTypeValue |= IMPORT_TYPE_MOVIE_MASK;
	}
	NSString *joinPath = [dict objectForKey:META_FILE_JOINED_FILE_KEY];
	if(joinPath != nil)
	{
		NSMutableDictionary *joinDict = [defer objectForKey:@"Join"];
		NSMutableArray *joinList = [joinDict objectForKey:joinPath];
		if(joinList == nil)
		{
			joinList = [NSMutableArray array];
			[joinDict setObject:joinList forKey:joinPath];
		}
		[joinList addObject:self];
	}
}

/*Custom TV Episode handler*/
- (NSComparisonResult) episodeCompare:(SapphireFileMetaData *)other
{
	/*Sort by episode*/
	SapphireEpisode *myEp = self.tvEpisode;
	SapphireEpisode *theirEp = nil;
	if([other isKindOfClass:[SapphireFileSymLink class]])
		theirEp = ((SapphireFileSymLink *)other).file.tvEpisode;
	else
		theirEp = other.tvEpisode;
	
	if(myEp != nil)
	{
		if(theirEp != nil)
			return [myEp compare:theirEp];
		else
			return NSOrderedAscending;
	}
	else if (theirEp != nil)
		return NSOrderedDescending;

	return NSOrderedSame;
}

- (NSComparisonResult) movieCompare:(SapphireFileMetaData *)other
{
	SapphireMovie *myMovie = self.movie;
	SapphireMovie *theirMovie = other.movie;
	
	if(myMovie != nil)
		if(theirMovie != nil)
		{
			NSComparisonResult ret = [myMovie titleCompare:theirMovie];
			if(ret == NSOrderedSame)
				ret = [myMovie releaseDateCompare:theirMovie];
			return ret;
		}
		else
			return NSOrderedAscending;
	else if(theirMovie != nil)
		return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (BOOL) needsUpdating
{
	/*Check modified date*/
	NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:self.path traverseLink:YES];
	int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
	
	if(props == nil)
	/*No file*/
		return FALSE;
	
	/*Has it been modified since last import?*/
	if(modTime != [self.modified timeIntervalSince1970])
		return YES;
	
	if(self.hasVideo == nil)
		return YES;
	
	return NO;
}

- (oneway void)addFileData:(bycopy NSDictionary *)fileMeta
{
	self.audioDescription = [fileMeta objectForKey:META_FILE_AUDIO_DESC_KEY];
	self.audioFormatID = [fileMeta objectForKey:META_FILE_AUDIO_FORMAT_KEY];
	self.duration = [fileMeta objectForKey:META_FILE_DURATION_KEY];
	id value = [fileMeta objectForKey:META_FILE_MODIFIED_KEY];
	if(value != nil)
		self.modified = [NSDate dateWithTimeIntervalSince1970:[value intValue]];
	self.sampleRate = [fileMeta objectForKey:META_FILE_SAMPLE_RATE_KEY];
	self.size = [fileMeta objectForKey:META_FILE_SIZE_KEY];
	self.subtitlesDescription = [fileMeta objectForKey:META_FILE_SUBTITLES_KEY];
	NSString *videoDesc = [fileMeta objectForKey:META_FILE_VIDEO_DESC_KEY];
	self.videoDescription = videoDesc;
	if(videoDesc != nil)
		self.hasVideoValue = YES;
}


BOOL updateMetaData(SapphireFileMetaData *file)
{
	BOOL updated =FALSE;
	if([file needsUpdating])
	{
		/*We did an update*/
		updated=TRUE ;
		NSMutableDictionary *fileMeta = [NSMutableDictionary dictionary];
		NSString *path = [file path];
		
		NSDictionary *props = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		int modTime = [[props objectForKey:NSFileModificationDate] timeIntervalSince1970];
		/*Set modified, size, and version*/
		[fileMeta setObject:[NSNumber numberWithInt:modTime] forKey:META_FILE_MODIFIED_KEY];
		[fileMeta setObject:[props objectForKey:NSFileSize] forKey:META_FILE_SIZE_KEY];
		
		if([file fileContainerTypeValue] == FILE_CONTAINER_TYPE_QT_MOVIE)
		{
			/*Open the movie*/
			NSError *error = nil;
			QTMovie *movie = [QTMovie movieWithFile:path error:&error];
			QTTime duration = [movie duration];
			[fileMeta setObject:[NSNumber numberWithFloat:(float)duration.timeValue/(float)duration.timeScale] forKey:META_FILE_DURATION_KEY];
			NSArray *audioTracks = [movie tracksOfMediaType:@"soun"];
			NSNumber *audioSampleRate = nil;
			int trackCount = [audioTracks count];
			int i;
			BOOL foundAC3 = NO;
			for(i=0; i<trackCount; i++)
			{
				/*Get the audio track*/
				QTTrack *track = [audioTracks objectAtIndex:i];
				QTMedia *media = [track media];
				if(media != nil)
				{
					/*Get the audio format*/
					Media qtMedia = [media quickTimeMedia];
					Handle sampleDesc = NewHandle(1);
					GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc);
					AudioStreamBasicDescription asbd;
					ByteCount	propSize = 0;
					QTSoundDescriptionGetProperty((SoundDescriptionHandle)sampleDesc, kQTPropertyClass_SoundDescription, kQTSoundDescriptionPropertyID_AudioStreamBasicDescription, sizeof(asbd), &asbd, &propSize);
					
					if(propSize != 0 && !foundAC3)
					{
						/*Set the format and sample rate*/
						NSNumber *format = [NSNumber numberWithUnsignedInt:asbd.mFormatID];
						[fileMeta setObject:format forKey:META_FILE_AUDIO_FORMAT_KEY];
						audioSampleRate = [NSNumber numberWithDouble:asbd.mSampleRate];
					}
					
					CFStringRef userText = nil;
					propSize = 0;
					QTSoundDescriptionGetProperty((SoundDescriptionHandle)sampleDesc, kQTPropertyClass_SoundDescription, kQTSoundDescriptionPropertyID_UserReadableText, sizeof(userText), &userText, &propSize);
					if(userText != nil)
					{
						if([(NSString *)userText hasPrefix:@"AC3"])
							foundAC3 = YES;
						/*Set the description*/
						NSString *prevDesc = [fileMeta objectForKey:META_FILE_AUDIO_DESC_KEY];
						NSString *newDesc;
						if(prevDesc != nil)
							newDesc = [prevDesc stringByAppendingFormat:@"\n%@", userText];
						else
							newDesc = (NSString *)userText;
						[fileMeta setObject:newDesc forKey:META_FILE_AUDIO_DESC_KEY];
						CFRelease(userText);
					}
					DisposeHandle(sampleDesc);
				}
			}
			/*Set the sample rate*/
			if(audioSampleRate != nil)
				[fileMeta setObject:audioSampleRate forKey:META_FILE_SAMPLE_RATE_KEY];
			NSArray *videoTracks = [movie tracksOfMediaType:@"vide"];
			trackCount = [videoTracks count];
			for(i=0; i<trackCount; i++)
			{
				/*Get the video track*/
				QTTrack *track = [videoTracks objectAtIndex:i];
				QTMedia *media = [track media]; 
				if(media != nil) 
				{
					/*Get the video description*/ 
					Media qtMedia = [media quickTimeMedia]; 
					Handle sampleDesc = NewHandle(1); 
					GetMediaSampleDescription(qtMedia, 1, (SampleDescriptionHandle)sampleDesc); 
					CFStringRef userText = nil; 
					ByteCount propSize = 0; 
					ICMImageDescriptionGetProperty((ImageDescriptionHandle)sampleDesc, kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_SummaryString, sizeof(userText), &userText, &propSize); 
					DisposeHandle(sampleDesc); 
					
					if(userText != nil) 
					{ 
						/*Set the description*/ 
						NSString *prevDesc = [fileMeta objectForKey:META_FILE_VIDEO_DESC_KEY];
						NSString *newDesc;
						if(prevDesc != nil)
							newDesc = [prevDesc stringByAppendingFormat:@"\n%@", userText];
						else
							newDesc = (NSString *)userText;
						[fileMeta setObject:newDesc forKey:META_FILE_VIDEO_DESC_KEY];
						CFRelease(userText);
					} 
				} 
			}
		} //QTMovie
		else if([file fileContainerTypeValue] == FILE_CONTAINER_TYPE_VIDEO_TS)
		{
			SapphireVideoTsParser *dvd = [[SapphireVideoTsParser alloc] initWithPath:path];
			
			[fileMeta setObject:[dvd videoFormatsString ] forKey:META_FILE_VIDEO_DESC_KEY];
			[fileMeta setObject:[dvd audioFormatsString ] forKey:META_FILE_AUDIO_DESC_KEY];
			[fileMeta setObject:[dvd subtitlesString    ] forKey:META_FILE_SUBTITLES_KEY ];
			[fileMeta setObject:[dvd mainFeatureDuration] forKey:META_FILE_DURATION_KEY  ];
			[fileMeta setObject:[dvd totalSize          ] forKey:META_FILE_SIZE_KEY      ];
			
			[dvd release];
		} // VIDEO_TS
		[file addFileData:fileMeta];
	}
	return updated;
}

- (BOOL)updateMetaData
{
	return updateMetaData(self);
}

- (NSString *)sizeString
{
	/*Get size*/
	float size = [self sizeValue];
	if(size == 0)
		return @"-";
	
	/*The letter for magnitude*/
	char letter = ' ';
	if(size >= 1024000)
	{
		if(size >= 1024*1024000)
		{
			/*GB*/
			size /= 1024 * 1024 * 1024;
			letter = 'G';
		}
		else
		{
			/*MB*/
			size /= 1024 * 1024;
			letter = 'M';
		}
	}
	else if (size >= 1000)
	{
		/*KB*/
		size /= 1024;
		letter = 'K';
	}
	return [NSString stringWithFormat:@"%.1f%cB", size, letter];	
}

- (void)setToReimportFromMask:(NSNumber *)mask
{
	[self setToReimportFromMaskValue:[mask intValue]];
}

- (void)setToReimportFromMaskValue:(int)mask
{
	int currentMask = self.importTypeValue;
	self.importTypeValue = currentMask & ~mask;
	if(mask & IMPORT_TYPE_MOVIE_MASK)
	{
		SapphireMovie *movie = self.movie;
		self.movie = nil;
		if(movie != nil && [movie.filesSet count] == 0)
			[[self managedObjectContext] deleteObject:movie];
	}
	if(mask & IMPORT_TYPE_TVSHOW_MASK)
	{
		SapphireEpisode *ep = self.tvEpisode;
		self.tvEpisode = nil;
		if(ep != nil && [ep.filesSet count] == 0)
			[[self managedObjectContext] deleteObject:ep];
	}
}

- (void)setToResetImportDecisions
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSString *lowerFileName = [[self.path lastPathComponent] lowercaseString];

	SapphireEpisode *ep = self.tvEpisode;
	if(ep != nil)
	{
		NSSet *translations = ep.tvShow.translationsSet;
		SapphireTVTranslation *tran;
		NSEnumerator *tranEnum = [translations objectEnumerator];
		while((tran = [tranEnum nextObject]) != nil)
		{
			if([lowerFileName hasPrefix:tran.name])
			{
				SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Deleting TV import translation for %@", tran.name);
				[moc deleteObject:tran];
			}
		}
	}
	NSString *lookupName;
	if([[SapphireSettings sharedSettings] dirLookup])
		lookupName = [[[self.path stringByDeletingLastPathComponent] lastPathComponent] lowercaseString];
	else
		lookupName = lowerFileName;
	SapphireMovieTranslation *movieTran = [SapphireMovieTranslation movieTranslationWithName:[lookupName stringByDeletingPathExtension] inContext:moc];
	if(movieTran != nil)
	{
		SapphireLog(SAPPHIRE_LOG_METADATA_STORE, SAPPHIRE_LOG_LEVEL_DETAIL, @"Deleting Movie import translation for %@", movieTran.name);
		[moc deleteObject:movieTran];
	}
	
	[self setToReimportFromMaskValue:IMPORT_TYPE_ALL_MASK];
}

- (void)clearMetaData
{
	self.audioDescription = nil;
	self.audioFormatID = nil;
	self.duration = nil;
	self.favoriteValue = 0;
	self.fileClassValue = nil;
	self.fileContainerType = nil;
	self.hasVideo = nil;
	self.importTypeValue = 0;
	self.modified = nil;
	self.resumeTime = nil;
	self.sampleRate = nil;
	self.size = nil;
	self.subtitlesDescription = nil;
	self.videoDescription = nil;
	self.watchedValue = 0;
	self.movie = nil;
	self.tvEpisode = nil;
	if(self.xmlData != nil)
	{
		[[self managedObjectContext] deleteObject:self.xmlData];
	}
}

- (NSString *)coverArtPath
{
	/*Find cover art for the current file in the "Cover Art" dir */
	NSString *subPath = [self path];
	if([self fileContainerTypeValue] != FILE_CONTAINER_TYPE_VIDEO_TS)
		subPath = [subPath stringByDeletingPathExtension];
	
	NSString *fileName = [subPath lastPathComponent];
	NSString * myArtPath=nil;
	
	if([self fileClassValue]==FILE_CLASS_TV_SHOW)
		myArtPath=[[self tvEpisode] coverArtPath];
	if([self fileClassValue]==FILE_CLASS_MOVIE)
		myArtPath=[[self movie] coverArtPath];
	
	/* Check the Collection Art location */
	NSString *ret=searchCoverArtExtForPath(myArtPath);
	
	if(ret != nil)
		return ret;
	
	/* Try Legacy Folders with the file */
	ret=searchCoverArtExtForPath([[[subPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Cover Art"] stringByAppendingPathComponent:fileName]);
	
	if(ret != nil)
		return ret;
	
	/*Find cover art for the current file in the current dir*/
	ret = searchCoverArtExtForPath(subPath);
	
	if(ret != nil)
		return ret;
	
	
	return nil;
}

- (NSString *)durationString
{
	/*Create duration string*/
	return [NSString colonSeparatedTimeStringForSeconds:[self durationValue]];
}

static BOOL moving = NO;
static BOOL moveSuccess = NO;
static NSString *movingFromPath = @"From";
static NSString *movingToPath = @"To";

- (void)threadedMove:(NSDictionary *)pathInfo
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	moveSuccess = [[NSFileManager defaultManager] movePath:[pathInfo objectForKey:movingFromPath] toPath:[pathInfo objectForKey:movingToPath] handler:nil];
	moving = NO;
	[pool drain];
}

- (NSString *)moveToPath:(NSString *)newPath pathForMoveError:(NSString *)errorPath inDir:(SapphireDirectoryMetaData *)newParent
{
	NSString *oldPath = [[[self path] retain] autorelease];
	NSFileManager *fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:newPath])
		return [NSString stringWithFormat:BRLocalizedString(@"The name %@ is already taken", @"Name taken on a file/directory rename; parameter is name"), [newPath lastPathComponent]];
	if(newParent != nil)
	{
		moving = YES;
		[NSThread detachNewThreadSelector:@selector(threadedMove:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
																							 oldPath, movingFromPath,
																							 newPath, movingToPath,
																							 nil]];
		while(moving)
			[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:1]];		
	}
	else
		moveSuccess = [fm movePath:oldPath toPath:newPath handler:nil];
	NSLog(@"Move %d", moveSuccess);
	if(!moveSuccess)
		return [NSString stringWithFormat:BRLocalizedString(@"Could not move %@.  Is the filesystem read-only?", @"Unknown error renaming file/directory; parameter is name"), errorPath];
	[self setPath:newPath];
	NSLog(@"path set to %@", newPath);
	if(newParent != nil)
	{
		SapphireDirectoryMetaData *oldParent = self.parent;
		self.parent = newParent;
		[oldParent clearPredicateCache];
		[newParent clearPredicateCache];
	}
	NSLog(@"new parent set");
	[SapphireMetaDataSupport save:[self managedObjectContext]];
	NSLog(@"Save done");
	NSString *extLessPath = [oldPath stringByDeletingPathExtension];
	NSEnumerator *secondaryExtEnum = [secondaryFiles objectEnumerator];
	NSString *extension;
	
	while((extension = [secondaryExtEnum nextObject]) != nil)
	{
		NSString *secondaryPath = [extLessPath stringByAppendingPathExtension:extension];
		if([fm fileExistsAtPath:secondaryPath])
		{
			NSString *newSecondaryPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
			if(newParent != nil)
			{
				moving = YES;
				[NSThread detachNewThreadSelector:@selector(threadedMove:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
																									 secondaryPath, movingFromPath,
																									 newSecondaryPath, movingToPath,
																									 nil]];
				while(moving)
					[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:1]];		
			}
			else
				moveSuccess = [fm movePath:secondaryPath toPath:newSecondaryPath handler:nil];			
			if(!moveSuccess)
				return [NSString stringWithFormat:BRLocalizedString(@"Could not move %@ file for %@.  Is the filesystem read-only?", @"Unknown error renaming file/directory; parameter is extension, name"), extension, errorPath];
		}
	}
	NSLog(@"Secondary files done");
	NSString *coverArtPath = searchCoverArtExtForPath(extLessPath);
	if(coverArtPath != nil)
	{
		NSString *newCoverArtPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:[coverArtPath pathExtension]];
		if(newParent != nil)
		{
			moving = YES;
			[NSThread detachNewThreadSelector:@selector(threadedMove:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:
																								 coverArtPath, movingFromPath,
																								 newCoverArtPath, movingToPath,
																								 nil]];
			while(moving)
				[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:1]];		
		}
		else
			moveSuccess = [fm movePath:coverArtPath toPath:newCoverArtPath handler:nil];
		if(!moveSuccess)
			return [NSString stringWithFormat:BRLocalizedString(@"Could not move cover art for %@.  Is the filesystem read-only?", @"Unknown error renaming file/directory; parameter is name"), errorPath];
	}
	NSLog(@"Covert art done");
	return nil;
}

- (NSString *)moveToDir:(SapphireDirectoryMetaData *)dir
{
	NSString *destination = [dir path];
	NSString *newPath = [destination stringByAppendingPathComponent:[[self path] lastPathComponent]];
	return [self moveToPath:newPath pathForMoveError:[newPath lastPathComponent] inDir:dir];
}

- (NSString *)rename:(NSString *)newFilename
{
	int componentCount = [[newFilename pathComponents] count];
	if(componentCount != 1)
		return BRLocalizedString(@"A File name should not contain any '/' characters", @"");
	NSString *oldPath = [self path];
	newFilename = [newFilename stringByAppendingPathExtension:[oldPath pathExtension]];
	NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFilename];
	if([oldPath isEqualToString:newPath])
		return nil;
	NSLog(@"Going to move path %@ to %@ with error %@", [self path], newPath, newFilename);
	return [self moveToPath:newPath pathForMoveError:newFilename inDir:nil];
}

- (NSString *)prettyName
{
	if(self.tvEpisode != nil)
	{
		//TV Episode
		SapphireEpisode *ep = self.tvEpisode;
		NSString *tvShowName = ep.tvShow.name;
		NSString *epName = [ep episodeTitle];
		int season = ep.season.seasonNumberValue;
		int firstEp = [ep episodeNumberValue];
		int lastEp = [ep lastEpisodeNumberValue];
		
		NSString *SEString;
		if(firstEp == 0)
			//Single Special Episode
			SEString = [NSString stringWithFormat:@"S%02dES1", season];
		else if(lastEp == firstEp)
			//Single normal episode
			SEString = [NSString stringWithFormat:@"S%02dE%02d", season, firstEp];
		else
			//Double episode
			SEString = [NSString stringWithFormat:@"S%02dE%02d-E%02d", season, firstEp, lastEp];
		
		return [NSString stringWithFormat:@"%@ %@ %@", tvShowName, SEString, epName];
	}
	else if(self.movie != nil)
	{
		//Movie
		NSDate *releaseDate = [self.movie releaseDate];
		NSCalendarDate *releaseCalDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[releaseDate timeIntervalSinceReferenceDate]];
		return [NSString stringWithFormat:@"%@ (%d)", [self.movie title], [releaseCalDate yearOfCommonEra]];
	}
	return nil;
}

- (NSString *)renameToPrettyName
{
	NSString *prettyName = [self prettyName];
	if(prettyName == nil)
	{
		return BRLocalizedString(@"No pretty name to construct", @"");
	}
	
	NSMutableString *mutStr = [prettyName mutableCopy];
	[mutStr replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, [mutStr length])];
	NSLog(@"Going to rename %@ to %@", [self path], mutStr);
	
	return [self rename:[mutStr autorelease]];
}

- (NSMutableDictionary *)getDisplayedMetaDataInOrder:(NSArray * *)order;
{
	NSString *name = [[self path] lastPathComponent];
	NSString *durationStr = [self durationString];
	/*Set the order*/
	if(order != nil)
		*order = displayedMetaDataOrder;
	
	NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
	
	SapphireMovie *movie = [self movie];
	SapphireEpisode *ep = [self tvEpisode];
	if(movie != nil)
	{
		[movie insertDisplayMetaData:ret];
	}
	else if (ep != nil)
	{
		[ep insertDisplayMetaData:ret];
	}
	
	id value = [self videoDescription];
	if(value != nil)
	{
		NSString *valueString = (NSString *)value;
		NSMutableArray *valueArray = [[valueString componentsSeparatedByString:@"\n"] mutableCopy];
		[valueArray uniqueObjects];
		int count = [valueArray count];
		if(count > 1)
		{
			NSString *first = nil;
			int i;
			for(i=0; i<count; i++)
			{
				NSString *trackName = [valueArray objectAtIndex:i];
				if(![trackName hasPrefix:@"VobSub"])
				{
					first = [[trackName retain] autorelease];
					[valueArray removeObjectAtIndex:i];
					break;
				}
			}
			if(first == nil)
			{
				first = [[[valueArray objectAtIndex:0] retain] autorelease];
				[valueArray removeObjectAtIndex:0];
			}
			[ret setObject:first forKey:VIDEO_DESC_LABEL_KEY];
			[ret setObject:[valueArray componentsJoinedByString:@"\n"] forKey:VIDEO2_DESC_LABEL_KEY];
		}
		else
			[ret setObject:value forKey:VIDEO_DESC_LABEL_KEY];
		[valueArray release];
	}
	value = [self audioDescription];
	if(value != nil)
	{
		NSString *valueString = (NSString *)value;
		NSMutableArray *valueArray = [[valueString componentsSeparatedByString:@"\n"] mutableCopy];
		[valueArray uniqueObjects];
		if([valueArray count] > 1)
		{
			[ret setObject:[valueArray objectAtIndex:0] forKey:AUDIO_DESC_LABEL_KEY];
			[valueArray removeObjectAtIndex:0];
			[ret setObject:[valueArray componentsJoinedByString:@"\n"] forKey:AUDIO2_DESC_LABEL_KEY];
		}
		else
			[ret setObject:value forKey:AUDIO_DESC_LABEL_KEY];
		[valueArray release];
	}
	value = [self subtitlesDescription];
	if(value != nil)
		[ret setObject:value forKey:META_FILE_SUBTITLES_KEY];
	if([self durationValue])
	{
		if([self sizeValue])
		{
			int resumeTime = [self resumeTimeValue];
			NSString *fullDurationString = [NSString stringWithFormat:@"%@ (%@)", durationStr, [self sizeString]];
			if(resumeTime != 0)
				fullDurationString = [fullDurationString stringByAppendingFormat:BRLocalizedString(@" %@ Remaining", @"Time left to display in preview pane next to file runtime"), [NSString colonSeparatedTimeStringForSeconds:[self durationValue] - resumeTime]];
			[ret setObject:fullDurationString forKey:META_FILE_DURATION_KEY];
		}
		else
			[ret setObject:durationStr forKey:META_FILE_DURATION_KEY];
	}
	else
		[ret setObject:[self sizeString] forKey:META_FILE_SIZE_KEY];
	
	/*Set the title*/
	if([ret objectForKey:META_TITLE_KEY] == nil)
		[ret setObject:name forKey:META_TITLE_KEY];
	return [ret autorelease];
}

- (NSString *)searchShowName
{
	return self.xmlData.searchShowName;
}

- (int)searchSeasonNumber
{
	NSNumber *value = self.xmlData.searchSeasonNumber;
	if(value != nil)
		return [value intValue];
	return -1;
}

- (int)searchEpisodeNumber
{
	NSNumber *value = self.xmlData.searchEpisode;
	if(value != nil)
		return [value intValue];
	return -1;
}

- (int)searchLastEpisodeNumber
{
	NSNumber *value = self.xmlData.searchLastEpisodeNumber;
	if(value != nil)
		return [value intValue];
	return -1;
}

- (int)searchIMDBNumber
{
	NSNumber *value = self.xmlData.searchIMDBNumber;
	if(value != nil)
		return [value intValue];
	return -1;
}

- (FileContainerType)fileContainerTypeValue
{
	return super.fileContainerTypeValue;
}

- (ImportTypeMask)importTypeValue
{
	return super.importTypeValue;
}

- (long)importedTimeFromSource:(int)source
{
	if(source == IMPORT_TYPE_FILE_MASK)
		return [self.modified timeIntervalSince1970];
	else if(source == IMPORT_TYPE_XML_MASK)
		return [self.xmlData.modified timeIntervalSince1970];
	return 0;
}

- (void)didImportType:(ImportTypeMask)type
{
	self.importTypeValue |= type;
}

- (void)setMovie:(SapphireMovie *)movie
{
	SapphireMovie *oldMovie = self.movie;
	super.movie = movie;
	if([self isDeleted])
		return;
	if(movie != nil)
	{
		[self setFileClassValue:FILE_CLASS_MOVIE];
		self.importTypeValue |= IMPORT_TYPE_MOVIE_MASK;
	}
	if(movie != oldMovie)
		self.xmlData.movie = movie;
}

- (void)setTvEpisode:(SapphireEpisode *)ep
{
	SapphireEpisode *oldEp = self.tvEpisode;
	super.tvEpisode = ep;
	if([self isDeleted])
		return;
	if(ep != nil)
	{
		[self setFileClassValue:FILE_CLASS_TV_SHOW];
		self.importTypeValue |= IMPORT_TYPE_TVSHOW_MASK;
	}
	if(ep != oldEp)
		self.xmlData.episode = ep;
}

- (void)setXmlData:(SapphireXMLData *)data
{
	super.xmlData = data;
	if([self isDeleted])
		return;
	if(data != nil)
	{
		data.episode = self.tvEpisode;
		data.movie = self.movie;
	}
}

- (FileClass)fileClassValue
{
	FileClass xmlClass = self.xmlData.fileClassValue;
	if(xmlClass != FILE_CLASS_UNKNOWN)
		return xmlClass;
	return super.fileClassValue;
}

- (void)setFileClassValue:(FileClass)fileClass
{
	FileClass xmlClass = self.xmlData.fileClassValue;
	if(xmlClass != FILE_CLASS_UNKNOWN)
		self.xmlData.fileClassValue = FILE_CLASS_UNKNOWN;
	super.fileClassValue = fileClass;
}

- (void)setWatched:(NSNumber*)value_ {
	NSNumber *oldValue = [self.watched retain];
	super.watched = value_;
	if(![oldValue isEqualToNumber:value_])
	{
		self.resumeTime = nil;
		[self.parent clearPredicateCache];
		[self.tvEpisode clearPredicateCache];
		[self.movie clearPredicateCache];
	}
}

- (void)setFavorite:(NSNumber*)value_ {
	NSNumber *oldValue = [self.favorite retain];
	super.favorite = value_;
	if(![oldValue isEqualToNumber:value_])
	{
		[self.parent clearPredicateCache];
		[self.tvEpisode clearPredicateCache];
		[self.movie clearPredicateCache];
	}
}

@end
