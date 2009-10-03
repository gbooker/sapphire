/*
 * SapphireFileSorter.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 16, 2008.
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

#import "SapphireFileSorter.h"
#import "SapphireFileMetaData.h"
#import "SapphireMovie.h"
#import "SapphireEpisode.h"
#import "SapphireFileSymLink.h"
#import "NSString-Extensions.h"

@interface SapphireFileMetaData (sorting)
- (NSComparisonResult)movieIMDBRankCompare:(SapphireFileMetaData *)other;
- (NSComparisonResult)movieOscarsWonCompare:(SapphireFileMetaData *)other;
- (NSComparisonResult)movieIMDBRatingCompare:(SapphireFileMetaData *)other;
- (NSComparisonResult)moviePremierDateCompare:(SapphireFileMetaData *)other;
- (NSComparisonResult)episodeAirDateCompare:(SapphireFileMetaData *)other;
@end


@implementation SapphireFileSorter

+ (SapphireFileSorter *)sharedInstance
{
	return nil;
}

+ (BOOL)sortFiles:(NSMutableArray *)files withSorter:(int)sorter inAllowedSorts:(NSArray *)allowed;
{
	if(![allowed count])
		return NO;
	SapphireFileSorter *sorterObj;
	if(sorter == 0)
		sorterObj = [allowed objectAtIndex:0];
	else
	{
		NSEnumerator *sortEnum = [allowed objectEnumerator];
		while((sorterObj = [sortEnum nextObject]) != nil)
		{
			if([sorterObj sortNumber] == sorter)
				break;
		}
	}
	BOOL ret = NO;
	if(sorterObj == nil)
	{
		ret = YES;
		sorterObj = [allowed objectAtIndex:0];
	}
	[sorterObj sortFiles:files];
	
	return ret;
}

- (NSString *)displayName
{
	return nil;
}

- (NSString *)displayDescription
{
	return nil;
}

- (int)sortNumber
{
	return -1;
}

- (void)sortFiles:(NSMutableArray *)files
{
}

@end

@implementation SapphireTVEpisodeSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireTVEpisodeSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireTVEpisodeSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By Episode", @"[Sort] By Episode number");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by Episode Order.", @"Sort by Episode Order description");
}

- (int)sortNumber
{
	return 1;
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingSelector:@selector(episodeCompare:)];
}

@end

@implementation SapphireMovieTitleSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireMovieTitleSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireMovieTitleSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By Movie Title", @"[Sort] By Movie Title");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by Movie Title.", @"Sort by Movie Title description");
}

- (int)sortNumber
{
	return 2;
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingSelector:@selector(movieCompare:)];
}

@end

@implementation SapphireMovieIMDBTop250RankSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireMovieIMDBTop250RankSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireMovieIMDBTop250RankSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By IMDB Rank", @"[Sort] By IMDB Rank");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by IMDB Top 250 Rank.", @"Sort by IMDB Top 250 Rank description");
}

- (int)sortNumber
{
	return 3;
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingSelector:@selector(movieIMDBRankCompare:)];
}

@end

@implementation SapphireMovieAcademyAwardSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireMovieAcademyAwardSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireMovieAcademyAwardSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By Awards Won", @"[Sort] By Awards Won");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by Number of Awards Won.", @"Sort by Number of Awards Won description");
}

- (int)sortNumber
{
	return 4;
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingSelector:@selector(movieOscarsWonCompare:)];
}

@end

@implementation SapphireDateSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireDateSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireDateSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By Date", @"[Sort] By Date");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by Date.  With TV Episodes, this is Air Date.  With Movies, this is Premier Date.", @"Sort by Date description");
}

- (int)sortNumber
{
	return 5;
}

NSComparisonResult fileAndLinkDateCompare(id file1, id file2, void *context)
{
	/*Resolve link and try to sort by episodes*/
	SapphireFileMetaData *first;
	if([file1 isKindOfClass:[SapphireFileMetaData class]])
		first = (SapphireFileMetaData *)file1;
	else
		first = ((SapphireFileSymLink *)file1).file;
	
	SapphireFileMetaData *second;
	if([file2 isKindOfClass:[SapphireFileMetaData class]])
		second = (SapphireFileMetaData *)file2;
	else
		second = ((SapphireFileSymLink *)file2).file;
	
	NSComparisonResult result = [first episodeAirDateCompare:second];
	if(result != NSOrderedSame)
		return result;
	
	result = [first moviePremierDateCompare:second];
	if(result != NSOrderedSame)
		return result;
	
	/*Finally sort by path*/
	return [[[file1 valueForKey:@"path"] lastPathComponent] nameCompare:[[file2 valueForKey:@"path"] lastPathComponent]];
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingFunction:fileAndLinkDateCompare context:nil];
}

@end

@implementation SapphireMovieIMDBRatingSorter

+ (SapphireFileSorter *)sharedInstance
{
	static SapphireMovieIMDBRatingSorter *shared = nil;
	if(shared == nil)
		shared = [[SapphireMovieIMDBRatingSorter alloc] init];
	return shared;
}

- (NSString *)displayName
{
	return BRLocalizedString(@"By IMDB Rating", @"[Sort] By IMDB Rating");
}

- (NSString *)displayDescription
{
	return BRLocalizedString(@"Sort by IMDB User Rating.", @"Sort by IMDB User Rating description");
}

- (int)sortNumber
{
	return 6;
}

- (void)sortFiles:(NSMutableArray *)files
{
	[files sortUsingSelector:@selector(movieIMDBRatingCompare:)];
}

@end

@implementation SapphireFileMetaData (sorting)

- (NSComparisonResult)movieIMDBRankCompare:(SapphireFileMetaData *)other
{
	SapphireMovie *myMovie = self.movie;
	SapphireMovie *theirMovie = other.movie;
	
	if(myMovie != nil)
		if(theirMovie != nil)
		{
			NSComparisonResult ret = [myMovie imdbTop250RankingCompare:theirMovie];
			if(ret == NSOrderedSame)
				ret = [self movieCompare:other];
			return ret;
		}
		else
			return NSOrderedAscending;
		else if(theirMovie != nil)
			return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)movieOscarsWonCompare:(SapphireFileMetaData *)other
{
	SapphireMovie *myMovie = self.movie;
	SapphireMovie *theirMovie = other.movie;
	
	if(myMovie != nil)
		if(theirMovie != nil)
		{
			NSComparisonResult ret = [theirMovie oscarsWonCompare:myMovie];
			if(ret == NSOrderedSame)
				ret = [self movieCompare:other];
			return ret;
		}
		else
			return NSOrderedAscending;
		else if(theirMovie != nil)
			return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)movieIMDBRatingCompare:(SapphireFileMetaData *)other
{
	SapphireMovie *myMovie = self.movie;
	SapphireMovie *theirMovie = other.movie;
	
	if(myMovie != nil)
		if(theirMovie != nil)
		{
			NSComparisonResult ret = [myMovie imdbRatingCompare:theirMovie];
			if(ret == NSOrderedSame)
				ret = [self movieCompare:other];
			return -ret;
		}
		else
			return NSOrderedAscending;
		else if(theirMovie != nil)
			return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)moviePremierDateCompare:(SapphireFileMetaData *)other
{
	SapphireMovie *myMovie = self.movie;
	SapphireMovie *theirMovie = other.movie;
	
	if(myMovie != nil)
		if(theirMovie != nil)
		{
			NSComparisonResult ret = [myMovie releaseDateCompare:theirMovie];
			if(ret == NSOrderedSame)
				ret = [self movieCompare:other];
			return ret;
		}
		else
			return NSOrderedAscending;
		else if(theirMovie != nil)
			return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)episodeAirDateCompare:(SapphireFileMetaData *)other
{
	SapphireEpisode *myEp = self.tvEpisode;
	SapphireEpisode *theirEp = other.tvEpisode;
	
	if(myEp != nil)
	{
		if(theirEp != nil)
		{
			NSComparisonResult ret = [myEp airDateCompare:theirEp];
			if(ret == NSOrderedSame)
				ret = [self episodeCompare:other];
			return ret;
		}
		else
			return NSOrderedAscending;
	}
	else if (theirEp != nil)
		return NSOrderedDescending;
	
	return NSOrderedSame;
}

@end
