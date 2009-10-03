// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireTVShow.h instead.

#import <CoreData/CoreData.h>
#import "SapphireCategoryDirectory.h"


@class SapphireSeason;

@class SapphireTVTranslation;

@class SapphireEpisode;


@interface _SapphireTVShow : SapphireCategoryDirectory {}


- (NSString*)showDescription;
- (void)setShowDescription:(NSString*)value_;

//- (BOOL)validateShowDescription:(id*)value_ error:(NSError**)error_;



- (NSNumber*)showID;
- (void)setShowID:(NSNumber*)value_;

- (int)showIDValue;
- (void)setShowIDValue:(int)value_;

//- (BOOL)validateShowID:(id*)value_ error:(NSError**)error_;



- (NSString*)name;
- (void)setName:(NSString*)value_;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (NSString*)showPath;
- (void)setShowPath:(NSString*)value_;

//- (BOOL)validateShowPath:(id*)value_ error:(NSError**)error_;




- (void)addSeasons:(NSSet*)value_;
- (void)removeSeasons:(NSSet*)value_;
- (void)addSeasonsObject:(SapphireSeason*)value_;
- (void)removeSeasonsObject:(SapphireSeason*)value_;
- (NSMutableSet*)seasonsSet;



- (void)addTranslations:(NSSet*)value_;
- (void)removeTranslations:(NSSet*)value_;
- (void)addTranslationsObject:(SapphireTVTranslation*)value_;
- (void)removeTranslationsObject:(SapphireTVTranslation*)value_;
- (NSMutableSet*)translationsSet;



- (void)addEpisodes:(NSSet*)value_;
- (void)removeEpisodes:(NSSet*)value_;
- (void)addEpisodesObject:(SapphireEpisode*)value_;
- (void)removeEpisodesObject:(SapphireEpisode*)value_;
- (NSMutableSet*)episodesSet;


@end
