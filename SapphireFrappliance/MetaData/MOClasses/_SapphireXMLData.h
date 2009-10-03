// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireXMLData.h instead.

#import <CoreData/CoreData.h>



@class SapphireEpisode;

@class SapphireFileMetaData;

@class SapphireMovie;


@interface _SapphireXMLData : NSManagedObject {}


- (NSString*)contentDescription;
- (void)setContentDescription:(NSString*)value_;

//- (BOOL)validateContentDescription:(id*)value_ error:(NSError**)error_;



- (NSNumber*)searchIMDBNumber;
- (void)setSearchIMDBNumber:(NSNumber*)value_;

- (int)searchIMDBNumberValue;
- (void)setSearchIMDBNumberValue:(int)value_;

//- (BOOL)validateSearchIMDBNumber:(id*)value_ error:(NSError**)error_;



- (NSString*)summary;
- (void)setSummary:(NSString*)value_;

//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;



- (NSNumber*)absoluteEpisodeNumber;
- (void)setAbsoluteEpisodeNumber:(NSNumber*)value_;

- (short)absoluteEpisodeNumberValue;
- (void)setAbsoluteEpisodeNumberValue:(short)value_;

//- (BOOL)validateAbsoluteEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSData*)orderedDirectorsData;
- (void)setOrderedDirectorsData:(NSData*)value_;

//- (BOOL)validateOrderedDirectorsData:(id*)value_ error:(NSError**)error_;



- (NSNumber*)oscarsWon;
- (void)setOscarsWon:(NSNumber*)value_;

- (short)oscarsWonValue;
- (void)setOscarsWonValue:(short)value_;

//- (BOOL)validateOscarsWon:(id*)value_ error:(NSError**)error_;



- (NSData*)orderedCastData;
- (void)setOrderedCastData:(NSData*)value_;

//- (BOOL)validateOrderedCastData:(id*)value_ error:(NSError**)error_;



- (NSNumber*)lastEpisodeNumber;
- (void)setLastEpisodeNumber:(NSNumber*)value_;

- (short)lastEpisodeNumberValue;
- (void)setLastEpisodeNumberValue:(short)value_;

//- (BOOL)validateLastEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSNumber*)searchEpisode;
- (void)setSearchEpisode:(NSNumber*)value_;

- (short)searchEpisodeValue;
- (void)setSearchEpisodeValue:(short)value_;

//- (BOOL)validateSearchEpisode:(id*)value_ error:(NSError**)error_;



- (NSData*)orderedGenresData;
- (void)setOrderedGenresData:(NSData*)value_;

//- (BOOL)validateOrderedGenresData:(id*)value_ error:(NSError**)error_;





- (NSNumber*)imdbTop250Ranking;
- (void)setImdbTop250Ranking:(NSNumber*)value_;

- (short)imdbTop250RankingValue;
- (void)setImdbTop250RankingValue:(short)value_;

//- (BOOL)validateImdbTop250Ranking:(id*)value_ error:(NSError**)error_;



- (NSDate*)modified;
- (void)setModified:(NSDate*)value_;

//- (BOOL)validateModified:(id*)value_ error:(NSError**)error_;



- (NSNumber*)fileClass;
- (void)setFileClass:(NSNumber*)value_;

- (short)fileClassValue;
- (void)setFileClassValue:(short)value_;

//- (BOOL)validateFileClass:(id*)value_ error:(NSError**)error_;



- (NSNumber*)searchSeasonNumber;
- (void)setSearchSeasonNumber:(NSNumber*)value_;

- (short)searchSeasonNumberValue;
- (void)setSearchSeasonNumberValue:(short)value_;

//- (BOOL)validateSearchSeasonNumber:(id*)value_ error:(NSError**)error_;



- (NSString*)searchShowName;
- (void)setSearchShowName:(NSString*)value_;

//- (BOOL)validateSearchShowName:(id*)value_ error:(NSError**)error_;







- (NSString*)title;
- (void)setTitle:(NSString*)value_;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;



- (NSDate*)releaseDate;
- (void)setReleaseDate:(NSDate*)value_;

//- (BOOL)validateReleaseDate:(id*)value_ error:(NSError**)error_;



- (NSNumber*)episodeNumber;
- (void)setEpisodeNumber:(NSNumber*)value_;

- (short)episodeNumberValue;
- (void)setEpisodeNumberValue:(short)value_;

//- (BOOL)validateEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSNumber*)imdbRating;
- (void)setImdbRating:(NSNumber*)value_;

- (float)imdbRatingValue;
- (void)setImdbRatingValue:(float)value_;

//- (BOOL)validateImdbRating:(id*)value_ error:(NSError**)error_;



- (NSNumber*)searchLastEpisodeNumber;
- (void)setSearchLastEpisodeNumber:(NSNumber*)value_;

- (short)searchLastEpisodeNumberValue;
- (void)setSearchLastEpisodeNumberValue:(short)value_;

//- (BOOL)validateSearchLastEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSString*)MPAARating;
- (void)setMPAARating:(NSString*)value_;

//- (BOOL)validateMPAARating:(id*)value_ error:(NSError**)error_;




- (SapphireEpisode*)episode;
- (void)setEpisode:(SapphireEpisode*)value_;
//- (BOOL)validateEpisode:(id*)value_ error:(NSError**)error_;



- (SapphireFileMetaData*)file;
- (void)setFile:(SapphireFileMetaData*)value_;
//- (BOOL)validateFile:(id*)value_ error:(NSError**)error_;



- (SapphireMovie*)movie;
- (void)setMovie:(SapphireMovie*)value_;
//- (BOOL)validateMovie:(id*)value_ error:(NSError**)error_;


@end
