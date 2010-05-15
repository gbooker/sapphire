// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMovie.h instead.

#import <CoreData/CoreData.h>



@class SapphireDirector;

@class SapphireFileMetaData;

@class SapphireGenre;

@class SapphireCast;

@class SapphireMovieTranslation;

@class SapphireXMLData;


@interface _SapphireMovie : NSManagedObject {}


- (NSData*)orderedDirectorsData;
- (void)setOrderedDirectorsData:(NSData*)value_;

//- (BOOL)validateOrderedDirectorsData:(id*)value_ error:(NSError**)error_;



- (NSNumber*)rottonTomatoesCertifiedFresh;
- (void)setRottonTomatoesCertifiedFresh:(NSNumber*)value_;

- (BOOL)rottonTomatoesCertifiedFreshValue;
- (void)setRottonTomatoesCertifiedFreshValue:(BOOL)value_;

//- (BOOL)validateRottonTomatoesCertifiedFresh:(id*)value_ error:(NSError**)error_;



- (NSString*)plot;
- (void)setPlot:(NSString*)value_;

//- (BOOL)validatePlot:(id*)value_ error:(NSError**)error_;





- (NSData*)otherPropertiesData;
- (void)setOtherPropertiesData:(NSData*)value_;

//- (BOOL)validateOtherPropertiesData:(id*)value_ error:(NSError**)error_;



- (NSData*)orderedGenresData;
- (void)setOrderedGenresData:(NSData*)value_;

//- (BOOL)validateOrderedGenresData:(id*)value_ error:(NSError**)error_;





- (NSData*)overriddenDirectorsData;
- (void)setOverriddenDirectorsData:(NSData*)value_;

//- (BOOL)validateOverriddenDirectorsData:(id*)value_ error:(NSError**)error_;





- (NSNumber*)rottonTomatoesRating;
- (void)setRottonTomatoesRating:(NSNumber*)value_;

- (short)rottonTomatoesRatingValue;
- (void)setRottonTomatoesRatingValue:(short)value_;

//- (BOOL)validateRottonTomatoesRating:(id*)value_ error:(NSError**)error_;



- (NSData*)overriddenGenresData;
- (void)setOverriddenGenresData:(NSData*)value_;

//- (BOOL)validateOverriddenGenresData:(id*)value_ error:(NSError**)error_;



- (NSNumber*)imdbTop250Ranking;
- (void)setImdbTop250Ranking:(NSNumber*)value_;

- (short)imdbTop250RankingValue;
- (void)setImdbTop250RankingValue:(short)value_;

//- (BOOL)validateImdbTop250Ranking:(id*)value_ error:(NSError**)error_;



- (NSString*)MPAARating;
- (void)setMPAARating:(NSString*)value_;

//- (BOOL)validateMPAARating:(id*)value_ error:(NSError**)error_;





- (NSData*)orderedCastData;
- (void)setOrderedCastData:(NSData*)value_;

//- (BOOL)validateOrderedCastData:(id*)value_ error:(NSError**)error_;



- (NSDate*)releaseDate;
- (void)setReleaseDate:(NSDate*)value_;

//- (BOOL)validateReleaseDate:(id*)value_ error:(NSError**)error_;



- (NSString*)title;
- (void)setTitle:(NSString*)value_;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;



- (NSNumber*)oscarsWon;
- (void)setOscarsWon:(NSNumber*)value_;

- (short)oscarsWonValue;
- (void)setOscarsWonValue:(short)value_;

//- (BOOL)validateOscarsWon:(id*)value_ error:(NSError**)error_;



- (NSData*)overriddenCastData;
- (void)setOverriddenCastData:(NSData*)value_;

//- (BOOL)validateOverriddenCastData:(id*)value_ error:(NSError**)error_;



- (NSNumber*)imdbRating;
- (void)setImdbRating:(NSNumber*)value_;

- (float)imdbRatingValue;
- (void)setImdbRatingValue:(float)value_;

//- (BOOL)validateImdbRating:(id*)value_ error:(NSError**)error_;



- (NSNumber*)imdbNumber;
- (void)setImdbNumber:(NSNumber*)value_;

- (int)imdbNumberValue;
- (void)setImdbNumberValue:(int)value_;

//- (BOOL)validateImdbNumber:(id*)value_ error:(NSError**)error_;




- (void)addDirectors:(NSSet*)value_;
- (void)removeDirectors:(NSSet*)value_;
- (void)addDirectorsObject:(SapphireDirector*)value_;
- (void)removeDirectorsObject:(SapphireDirector*)value_;
- (NSMutableSet*)directorsSet;



- (void)addFiles:(NSSet*)value_;
- (void)removeFiles:(NSSet*)value_;
- (void)addFilesObject:(SapphireFileMetaData*)value_;
- (void)removeFilesObject:(SapphireFileMetaData*)value_;
- (NSMutableSet*)filesSet;



- (void)addGenres:(NSSet*)value_;
- (void)removeGenres:(NSSet*)value_;
- (void)addGenresObject:(SapphireGenre*)value_;
- (void)removeGenresObject:(SapphireGenre*)value_;
- (NSMutableSet*)genresSet;



- (void)addCast:(NSSet*)value_;
- (void)removeCast:(NSSet*)value_;
- (void)addCastObject:(SapphireCast*)value_;
- (void)removeCastObject:(SapphireCast*)value_;
- (NSMutableSet*)castSet;



- (void)addTranslations:(NSSet*)value_;
- (void)removeTranslations:(NSSet*)value_;
- (void)addTranslationsObject:(SapphireMovieTranslation*)value_;
- (void)removeTranslationsObject:(SapphireMovieTranslation*)value_;
- (NSMutableSet*)translationsSet;



- (void)addXml:(NSSet*)value_;
- (void)removeXml:(NSSet*)value_;
- (void)addXmlObject:(SapphireXMLData*)value_;
- (void)removeXmlObject:(SapphireXMLData*)value_;
- (NSMutableSet*)xmlSet;


@end
