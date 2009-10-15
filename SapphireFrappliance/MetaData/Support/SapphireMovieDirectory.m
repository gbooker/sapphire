/*
 * SapphireMovieDirectory.m
 * Sapphire
 *
 * Created by Graham Booker on May 27, 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

#import "SapphireMovieDirectory.h"
#import "SapphireEntityDirectory.h"
#import "SapphireFilteredFileDirectory.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireBasicDirectoryFunctionsImports.h"
#import "SapphireFileSorter.h"
#import "SapphireMovieVirtualDirectoryImporter.h"
#import "SapphireMovieVirtualDirectory.h"
#import "SapphireMovie.h"
#import "SapphireCast.h"
#import "SapphireDirector.h"
#import "SapphireGenre.h"

NSArray *multiMovieEntityFetch(NSString *name, NSString *keyFromMovie, NSManagedObjectContext *moc, NSPredicate *filterPredicate)
{
	NSPredicate *entPred = nil;
	if(filterPredicate != nil)
	{
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"movie != nil"];
		NSPredicate *finalPred;
		if(filterPredicate == nil)
			finalPred = fetchPredicate;
		else
			finalPred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filterPredicate, fetchPredicate, nil]];
		NSArray *files = doFetchRequest(SapphireFileMetaDataName, moc, finalPred);
		NSSet *movieIds = [NSSet setWithArray:[files valueForKeyPath:@"movie.objectID"]];
		
		if(![SapphireFrontRowCompat usingLeopard])
		{
			/*	Damn you Apple for not making take 2 Leopard.  Not only does this make obj C 2 not available,
			 but it also means that I have to content with a crippled and slower core data.  The else block here
			 executes on Leopard at several times the speed, but on Tiger throws the exception:
			 "to-many key not allowed here" even though it can be done through a JOIN in the SQL!!!!!*/
			NSPredicate *moviePred = [NSPredicate predicateWithFormat:@"SELF IN %@", movieIds];
			NSArray *movies = doFetchRequest(SapphireMovieName, moc, moviePred);
			NSArray *entSet = [movies valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfSets.%@.objectID", keyFromMovie]];
			
			entPred = [NSPredicate predicateWithFormat:@"SELF IN %@", entSet];
		}
		else
			entPred = [NSPredicate predicateWithFormat:@"ANY movies IN %@", movieIds];
	}
	return doFetchRequest(name, moc, entPred);
}

NSArray *castEntityFetch(NSManagedObjectContext *moc, NSPredicate *filterPredicate)
{
	return multiMovieEntityFetch(SapphireCastName, @"cast", moc, filterPredicate);
}

NSArray *directorEntityFetch(NSManagedObjectContext *moc, NSPredicate *filterPredicate)
{
	return multiMovieEntityFetch(SapphireDirectorName, @"directors", moc, filterPredicate);
}

NSArray *genreEntityFetch(NSManagedObjectContext *moc, NSPredicate *filterPredicate)
{
	return multiMovieEntityFetch(SapphireGenreName, @"genres", moc, filterPredicate);
}

@implementation SapphireMovieDirectory

- (id)initWithContext:(NSManagedObjectContext *)context
{
	self = [super init];
	if(self == nil)
		return self;
	
	moc = [context retain];
	
	/*Define the static virtual directories*/
	NSPredicate *allPred = [NSPredicate predicateWithFormat:@"movie != nil"];
	SapphireFilteredFileDirectory *all = [[SapphireFilteredFileDirectory alloc] initWithPredicate:allPred Context:moc];
	SapphireEntityDirectory *cast = [[SapphireEntityDirectory alloc] initWithEntityFetch:castEntityFetch inContext:moc];
	SapphireEntityDirectory *director = [[SapphireEntityDirectory alloc] initWithEntityFetch:directorEntityFetch inContext:moc];
	SapphireEntityDirectory *genre = [[SapphireEntityDirectory alloc] initWithEntityFetch:genreEntityFetch inContext:moc];
	NSPredicate *top250Pred = [NSPredicate predicateWithFormat:@"movie.imdbTop250Ranking != 0"];
	SapphireFilteredFileDirectory *top250 = [[SapphireFilteredFileDirectory alloc] initWithPredicate:top250Pred Context:moc];
	NSPredicate *oscarPred = [NSPredicate predicateWithFormat:@"movie.oscarsWon != 0"];
	SapphireFilteredFileDirectory *oscar = [[SapphireFilteredFileDirectory alloc] initWithPredicate:oscarPred Context:moc];

	originalSubDirs = [[NSArray alloc] initWithObjects:
					   all,
					   cast,
					   director,
					   genre,
					   top250,
					   oscar,
					   nil];
	
	originalNames = [[NSArray alloc] initWithObjects:
					 BRLocalizedString( @"All Movies", @"Select all movies" ),
					 BRLocalizedString( @"By Cast", @"Select movies based on cast members" ),
					 BRLocalizedString( @"By Director", @"Select movies based on director" ),
					 BRLocalizedString( @"By Genre", @"Select movies based on genre" ),
					 BRLocalizedString( @"IMDB Top 250", @"Show movies in IMDb Top 250 only" ),
					 BRLocalizedString( @"Academy Award Winning", @"Show Oscar winning movies only" ),
					 nil];
					 
	SapphireFileSorter *titleSort = [SapphireMovieTitleSorter sharedInstance];
	SapphireFileSorter *imdbRankSort = [SapphireMovieIMDBTop250RankSorter sharedInstance];
	SapphireFileSorter *awardSort = [SapphireMovieAcademyAwardSorter sharedInstance];
	SapphireFileSorter *dateSort = [SapphireDateSorter sharedInstance];
	SapphireFileSorter *imdbRatingSort = [SapphireMovieIMDBRatingSorter sharedInstance];
	
	NSString *moviePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
	vdImport = [[SapphireMovieVirtualDirectoryImporter alloc] initWithPath:[applicationSupportDir() stringByAppendingPathComponent:@"virtualDirs.xml"]];
	defaultSorters = [[NSArray alloc] initWithObjects:titleSort, dateSort, imdbRatingSort, nil];
	
	/*Finish the static directory setup*/
	[all setPath:VIRTUAL_DIR_ALL_PATH];
	[all setCoverArtPath:moviePath];
	[all setFileSorters:[NSArray arrayWithObjects:titleSort, dateSort, imdbRatingSort, nil]];
	[cast setPath:VIRTUAL_DIR_CAST_PATH];
	[cast setCoverArtPath:moviePath];
	[cast setMetaFileFetchPredicate:[NSPredicate predicateWithFormat:@"movie != nil AND ANY movie.#cast != nil"]];
	[director setPath:VIRTUAL_DIR_DIRECTOR_PATH];
	[director setCoverArtPath:moviePath];
	[director setMetaFileFetchPredicate:[NSPredicate predicateWithFormat:@"movie != nil AND ANY movie.directors != nil"]];
	[genre setPath:VIRTUAL_DIR_GENRE_PATH];
	[genre setCoverArtPath:moviePath];
	[genre setMetaFileFetchPredicate:[NSPredicate predicateWithFormat:@"movie != nil AND ANY movie.genres != nil"]];
	[top250 setPath:VIRTUAL_DIR_TOP250_PATH];
	[top250 setCoverArtPath:moviePath];
	[top250 setFileSorters:[NSArray arrayWithObjects:imdbRankSort, titleSort, dateSort, imdbRatingSort, nil]];
	[oscar setPath:VIRTUAL_DIR_OSCAR_PATH];
	[oscar setCoverArtPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"AMPAS_Oscar_H" ofType:@"png"]];
	[oscar setFileSorters:[NSArray arrayWithObjects:awardSort, titleSort, dateSort, imdbRatingSort, nil]];
	[subDirs makeObjectsPerformSelector:@selector(setNotificationName:) withObject:MOVIE_DID_CHANGE_PREDICATE_MATCHING];
	Basic_Directory_Function_Inits

	[all release];
	[cast release];
	[director release];
	[genre release];
	[top250 release];
	[oscar release];
	return self;
}

- (void) dealloc
{
	[originalSubDirs release];
	[originalNames release];
	[subDirs release];
	[names release];
	[virtualDirs release];
	[defaultSorters release];
	[vdImport release];
	Basic_Directory_Function_Deallocs
	[super dealloc];
}

- (NSArray *)files
{
	return [NSArray array];
}

- (NSArray *)directories
{
	if(filterPredicate == nil)
		return names;
	
	NSMutableArray *ret = [NSMutableArray array];
	int i, count = [names count];
	for(i=0; i<count; i++)
	{
		if([[subDirs objectAtIndex:i] containsFileMatchingFilterPredicate:filterPredicate])
			[ret addObject:[names objectAtIndex:i]];
	}
	return ret;
}

- (NSArray *)metaFiles
{
	NSPredicate *allPred = [NSPredicate predicateWithFormat:@"movie != nil"];
	return doFetchRequest(SapphireFileMetaDataName, moc, allPred);
}

- (NSPredicate *)metaFileFetchPredicate
{
	return nil;
}

- (SapphireFileMetaData *)metaDataForFile:(NSString *)file
{
	return nil;
}

- (id <SapphireDirectory>)metaDataForDirectory:(NSString *)directory
{
	int index = [names indexOfObject:directory];
	if(index == NSNotFound)
		return nil;
	return [subDirs objectAtIndex:index];
}

- (void)reloadDirectoryContents
{
	/*Import any defined movie virtual directories*/
	NSArray *newVirtualDirs = [vdImport virtualDirectories];
	if(![virtualDirs isEqualToArray:newVirtualDirs])
	{
		[virtualDirs release];
		[names release];
		[subDirs release];
		virtualDirs = [newVirtualDirs retain];
		names = [originalNames mutableCopy];
		subDirs = [originalSubDirs mutableCopy];
		
		NSString *moviePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"video_H" ofType:@"png"];
		NSEnumerator *mvdEnum = [newVirtualDirs objectEnumerator];
		SapphireMovieVirtualDirectory *virtualDir;
		while((virtualDir = [mvdEnum nextObject]) != nil)
		{
			SapphireFilteredFileDirectory *custom = [[SapphireFilteredFileDirectory alloc] initWithPredicate:[virtualDir predicate] Context:moc];
			[subDirs addObject:custom];
			[names addObject:BRLocalizedString([virtualDir title], [virtualDir description])];
			[custom setPath:[[VIRTUAL_DIR_ROOT_PATH stringByAppendingString:@"/"] stringByAppendingString:[virtualDir description]]];
			[custom setCoverArtPath:moviePath]; // Change this to be part of the XML?
			[custom setFileSorters:defaultSorters];
			[custom release];
		}
	}
	
	[subDirs makeObjectsPerformSelector:@selector(setFilterPredicate:) withObject:filterPredicate];
	[delegate directoryContentsChanged];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return moc;
}

- (BOOL)objectIsDeleted
{
	return NO;
}

- (NSString *)path
{
	return @"@MOVIES";
}

- (NSString *)coverArtPath
{
	return [[SapphireMetaDataSupport collectionArtPath] stringByAppendingPathComponent:@"@MOVIES"];
}

- (void)faultAllObjects
{
}

- (id <SapphireDirectory>)parentDirectory
{
	return nil;
}

#include "SapphireBasicDirectoryFunctions.h"

@end
