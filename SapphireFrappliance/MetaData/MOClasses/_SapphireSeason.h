// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireSeason.h instead.

#import <CoreData/CoreData.h>
#import "SapphireCategoryDirectory.h"


@class SapphireTVShow;

@class SapphireEpisode;


@interface _SapphireSeason : SapphireCategoryDirectory {}


- (NSNumber*)seasonNumber;
- (void)setSeasonNumber:(NSNumber*)value_;

- (short)seasonNumberValue;
- (void)setSeasonNumberValue:(short)value_;

//- (BOOL)validateSeasonNumber:(id*)value_ error:(NSError**)error_;



- (NSString*)seasonDescription;
- (void)setSeasonDescription:(NSString*)value_;

//- (BOOL)validateSeasonDescription:(id*)value_ error:(NSError**)error_;




- (SapphireTVShow*)tvShow;
- (void)setTvShow:(SapphireTVShow*)value_;
//- (BOOL)validateTvShow:(id*)value_ error:(NSError**)error_;



- (void)addEpisodes:(NSSet*)value_;
- (void)removeEpisodes:(NSSet*)value_;
- (void)addEpisodesObject:(SapphireEpisode*)value_;
- (void)removeEpisodesObject:(SapphireEpisode*)value_;
- (NSMutableSet*)episodesSet;


@end
