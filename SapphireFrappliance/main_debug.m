/*
 * main_debug.c
 * Sapphire
 *
 * Created by Graham Booker on Aug. 2, 2008.
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

#import "SapphireImportHelper.h"
#import <CoreData/CoreData.h>

#include "../SapphireCompatibilityClasses/Sapphire_Prefix.pch"

//Debug Imports
#import "SapphireCollectionDirectory.h"
#import "SapphireDirectoryMetaData.h"
#import "SapphireApplianceController.h"
#import "SapphireMetaDataUpgrading.h"
#import "SapphireMovie.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireFileMetaData.h"
#import "SapphireFileDataImporter.h"
#import "SapphireXMLFileDataImporter.h"
#import "SapphireTVShowImporter.h"
#import "SapphireMovieImporter.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireAllImporter.h"
#import "SapphireTVShow.h"
#import "SapphireGenre.h"
#import "SapphireCast.h"
#import "SapphireDirector.h"
#import "SapphireXMLData.h"
#import "SapphireMovieDirectory.h"
#import "SapphireNfoImporter.h"

void overrideApplicationSupportdir(NSString *override);

@interface TestFileScanning : NSObject <SapphireMetaDataScannerDelegate>
{
	int i;
	NSArray	*collections;
	NSMutableSet *skip;
}
- (id)initWithCollections:(NSArray *)col;
@end

@implementation TestFileScanning

- (id)initWithCollections:(NSArray *)col
{
	self = [super init];
	
	collections = [col retain];
	skip = [[NSMutableSet alloc] init];
	i=-1;
	
	return self;
}

- (void) dealloc
{
	[collections release];
	[skip release];
	[super dealloc];
}

- (void)gotSubFiles:(NSArray *)subs
{
	i++;
	if(i==[collections count])
		NSLog(@"DONE!!!");
	else
	{
		[[(SapphireCollectionDirectory *)[collections objectAtIndex:i] directory] getSubFileMetasWithDelegate:self skipDirectories:skip];
	}
}

- (void)scanningDir:(NSString *)dir
{
}

- (BOOL)getSubFilesCanceled
{
	return NO;
}

@end

@interface SapphireMetaDataUpgrading (debug)
- (void)doUpgrade:(id)obj;
@end

@interface SapphireMetaDataSupport (debug)
+ (void)deletePendingObjects;
@end

static BOOL completedImports = YES;

@interface TestImportManager : NSObject <SapphireImporterDelegate>
{
	NSMutableArray		*waitingImports;
}

- (void)importer:(id <SapphireImporter>)importer importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path;
@end

@implementation TestImportManager

- (id)init
{
	self = [super init];
	if (self != nil) {
		waitingImports = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[waitingImports release];
	[super dealloc];
}

- (void)importer:(id <SapphireImporter>)importer importMetaData:(SapphireFileMetaData *)metaData path:(NSString *)path;
{
	[importer setDelegate:self];
	ImportState state = [importer importMetaData:metaData path:path];
	if(state == ImportStateBackground || state == ImportStateMultipleSuspend)
	{
		[waitingImports addObject:importer];
		completedImports = NO;
	}
}

- (void)backgroundImporter:(id <SapphireImporter>)importer completedImportOnPath:(NSString *)path withState:(ImportState)state
{
	[waitingImports removeObject:importer];
	if(![waitingImports count])
		completedImports = YES;
}

- (BOOL)canDisplayChooser
{
	return NO;
}

- (id)chooserScene
{
	return nil;
}

- (void)displayChooser:(BRLayerController <SapphireChooser> *)chooser forImporter:(id <SapphireImporter>)importer withContext:(id)context
{
}

@end



int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	{
		NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[0] length:strlen(argv[0])];
		
		path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Sapphire.frappliance"];
		
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		[bundle load];		
	}
	
//	overrideApplicationSupportdir([NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Frontrow"]);
//#define TESTING_UPGRADE
#ifdef TESTING_UPGRADE
	{
		SapphireMetaDataUpgrading *upgrade = [[SapphireMetaDataUpgrading alloc] init];
		[upgrade doUpgrade:nil];
		[upgrade release];
	}
#endif
	
	NSString *storeFile = [applicationSupportDir() stringByAppendingPathComponent:@"metaData.sapphireDataV2"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:storeFile];
	if(!exists)
		return 0;
	
	NSManagedObjectContext *moc = [SapphireApplianceController newManagedObjectContextForFile:storeFile withOptions:nil];
	[SapphireMetaDataSupport setMainContext:moc];
	SapphireXMLFileDataImporter *xmlImpr = [[SapphireXMLFileDataImporter alloc] init];
	SapphireFileDataImporter *fileImp = [[SapphireFileDataImporter alloc] init];
	SapphireNfoImporter *nfoImp = [[SapphireNfoImporter alloc] init];
	SapphireTVShowImporter *tvImp = [[SapphireTVShowImporter alloc] init];
	SapphireMovieImporter *movImp = [[SapphireMovieImporter alloc] init];
	SapphireAllImporter *allImporter = [[SapphireAllImporter alloc] initWithImporters:[NSArray arrayWithObjects:xmlImpr,nfoImp,tvImp,movImp,fileImp,nil]];
	[xmlImpr release];
	[fileImp release];
	[nfoImp release];
	[tvImp release];
	[movImp release];
	
	TestImportManager *importManager = [[TestImportManager alloc] init];
	
	//Debug code goes here:
//#define LISTING_MOVIES
#ifdef LISTING_MOVIES
	{
		NSArray *allMovies = doFetchRequest(SapphireMovieName, moc, nil);
		NSEnumerator *movieEnum = [allMovies objectEnumerator];
		SapphireMovie *movie;
		while((movie = [movieEnum nextObject]) != nil)
		{
			NSLog(@"Looking at movie %@ with xml: %d", [movie title], [[movie xmlSet] count]);
			NSLog(@"Cast is %@", [movie valueForKeyPath:@"cast.name"]);
			NSLog(@"Directors is %@", [movie valueForKeyPath:@"directors.name"]);
			NSLog(@"Genres is %@", [movie valueForKeyPath:@"genres.name"]);
			NSLog(@"Plot is %@", [movie plot]);
		}		
	}
#endif
//#define TESTING_XML_IMPORT
#ifdef TESTING_XML_IMPORT
	{
		NSString *path = @"/Users/gbooker/Movies/MovieTests/Little Eistiens: Our Big Huge Adventure (2005).avi";
		SapphireFileMetaData *meta = [SapphireFileMetaData fileWithPath:path inContext:moc];
		[meta clearMetaData];
		[SapphireMetaDataSupport save:moc];
		SapphireXMLFileDataImporter *importer = [[SapphireXMLFileDataImporter alloc] init];
		[importManager importer:importer importMetaData:meta path:[meta path]];
		[importer release];		
	}
#endif
//#define TESTING_FILE_SCANNING
#ifdef TESTING_FILE_SCANNING
	{
		NSMutableArray *collections = [[SapphireCollectionDirectory allCollectionsInContext:moc] mutableCopy];
		//remove / and ~/Movies
		[collections removeObjectAtIndex:0];
		[collections removeObjectAtIndex:0];
		TestFileScanning *debug = [[TestFileScanning alloc] initWithCollections:collections];
		[NSTimer scheduledTimerWithTimeInterval:0 target:debug selector:@selector(gotSubFiles:) userInfo:nil repeats:NO];
		[debug release];
		
		NSRunLoop *currentRL = [NSRunLoop currentRunLoop];
		while([currentRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
			;		
	}
#endif
//#define TESTING_UPDATED_VALUES
#ifdef TESTING_UPDATED_VALUES
	{
		NSString *path = @"/Users/gbooker/Movies/Little Einsteins.avi";
		SapphireFileMetaData *meta = [SapphireFileMetaData fileWithPath:path inContext:moc];
		[meta clearMetaData];
		[importManager importer:allImporter importMetaData:meta path:[meta path]];
		
		NSDictionary *changes = [SapphireMetaDataSupport changesDictionaryForContext:moc];
		[moc reset];
		[SapphireMetaDataSupport applyChanges:changes toContext:moc];
		[allImporter release];
	}
#endif
//#define TESTING_DIRECTORY_RESCAN
#ifdef TESTING_DIRECTORY_RESCAN
	{
		SapphireMovie *movie = [SapphireMovie movieWithTitle:@"Little Eistiens: Our Big Huge Adventure" inContext:moc];
		SapphireFileMetaData *file = [SapphireFileMetaData fileWithPath:@"/Users/gbooker/Movies/Little Einsteins.avi" inContext:moc];
		[moc deleteObject:file];
		[moc processPendingChanges];
		SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData directoryWithPath:@"/Users/gbooker/Movies" inContext:moc];
		[dir reloadDirectoryContents];
	}
#endif
//#define TESTING_AUTO_PRUNING
#ifdef TESTING_AUTO_PRUNING
	{
		SapphireFileMetaData *file = [SapphireFileMetaData fileWithPath:@"/Users/gbooker/Movies/MovieTests/Little Einsteins.avi" inContext:moc];
		SapphireXMLData *xml = [file xmlData];
		[moc deleteObject:xml];
		[SapphireMetaDataSupport deletePendingObjects];
		SapphireDirectoryMetaData *dir = [SapphireDirectoryMetaData directoryWithPath:@"/Users/gbooker/Movies/MovieTests" inContext:moc];
		[moc deleteObject:dir];
		[SapphireMetaDataSupport deletePendingObjects];
		dir = [SapphireDirectoryMetaData directoryWithPath:@"/Users/gbooker/Movies/TVShowsTests" inContext:moc];
		[moc deleteObject:dir];
		[SapphireMetaDataSupport deletePendingObjects];
		NSArray *allMovies = doFetchRequest(SapphireMovieName, moc, nil);
		NSArray *allShows = doFetchRequest(SapphireTVShowName, moc, nil);
		NSArray *allGenres = doFetchRequest(SapphireGenreName, moc, nil);
		NSArray *allCast = doFetchRequest(SapphireCastName, moc, nil);
		NSArray *allDirectors = doFetchRequest(SapphireDirectorName, moc, nil);
		
		NSLog(@"Movies: %@\nShows: %@\nCast: %@\nGenres: %@\nDirectors: %@", allMovies, allShows, allCast, allGenres, allDirectors);
	}
#endif
#define TESTING_MOVIE_IMPORT
#ifdef TESTING_MOVIE_IMPORT
	{
		SapphireFileMetaData *file = [SapphireFileMetaData fileWithPath:@"/Users/gbooker/Movies/MovieTests/FIFTH_ELEMENT.mov" inContext:moc];
		SapphireMovieImporter *import = [[SapphireMovieImporter alloc] init];
		[file setToReimportFromMaskValue:IMPORT_TYPE_MOVIE_MASK];
		[importManager importer:import importMetaData:file path:[file path]];
		[import release];
	}
#endif
//#define TESTING_TV_SHOW_IMPORT
#ifdef TESTING_TV_SHOW_IMPORT
	{
		SapphireFileMetaData *file = [SapphireFileMetaData fileWithPath:@"/Users/gbooker/Movies/TVShowsTests/Doctor Who (2005) S03ES1 Voyage of the Damned.avi" inContext:moc];
		SapphireTVShowImporter *import = [[SapphireTVShowImporter alloc] init];
		[file setToReimportFromMaskValue:IMPORT_TYPE_TVSHOW_MASK];
		[importManager importer:import importMetaData:file path:[file path]];
		[import release];
	}
#endif
//#define TESTING_MULTIPLE_AND_SINGLE_TV_SHOW_IMPORT
#ifdef TESTING_MULTIPLE_AND_SINGLE_TV_SHOW_IMPORT
	{
		SapphireFileMetaData *file = [SapphireFileMetaData createFileWithPath:@"/Users/gbooker/Movies/TVShowsTests/Stargate Atlantis S01E01-E02.avi" inContext:moc];
		SapphireTVShowImporter *import = [[SapphireTVShowImporter alloc] init];
		[file setToReimportFromMaskValue:IMPORT_TYPE_TVSHOW_MASK];
		[importManager importer:import importMetaData:file path:[file path]];
		[import release];
		
		import = [[SapphireTVShowImporter alloc] init];
		file = [SapphireFileMetaData createFileWithPath:@"/Users/gbooker/Movies/TVShowsTests/Stargate Atlantis S01E02.avi" inContext:moc];
//		[importManager importer:import importMetaData:file path:[file path]];
		[import release];
	}
#endif
//#define TESTING_MOVIE_VIRTUAL_DIRS_IN_XML
#ifdef TESTING_MOVIE_VIRTUAL_DIRS_IN_XML
	{
		SapphireMovieDirectory *movieDir = [[SapphireMovieDirectory alloc] init];
		[movieDir reloadDirectoryContents];
		[movieDir reloadDirectoryContents];
		[movieDir release];
	}
#endif
//#define TESTING_TV_IMPORT_THROUGH_XML
#ifdef TESTING_TV_IMPORT_THROUGH_XML
	{
		SapphireFileMetaData *file = [SapphireFileMetaData createFileWithPath:@"/Users/gbooker/Movies/TVShowsTests/life on mars.avi" inContext:moc];
		[importManager importer:allImporter importMetaData:file path:[file path]];
	}
#endif
	
	[allImporter release];
	
	[moc release];
	[pool drain];
	
	pool = [[NSAutoreleasePool alloc] init];
	NSRunLoop *currentRL = [NSRunLoop currentRunLoop];
	while(!completedImports && [currentRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
		;
	
	[importManager release];
	[pool drain];
	return 0;
}