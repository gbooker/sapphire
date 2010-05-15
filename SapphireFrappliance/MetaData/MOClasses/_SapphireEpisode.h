// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireEpisode.h instead.

#import <CoreData/CoreData.h>



@class SapphireSubEpisode;

@class SapphireFileMetaData;

@class SapphireSeason;

@class SapphireTVShow;

@class SapphireXMLData;


@interface _SapphireEpisode : NSManagedObject {}




- (NSData*)otherPropertiesData;
- (void)setOtherPropertiesData:(NSData*)value_;

//- (BOOL)validateOtherPropertiesData:(id*)value_ error:(NSError**)error_;




- (void)addSubEpisodes:(NSSet*)value_;
- (void)removeSubEpisodes:(NSSet*)value_;
- (void)addSubEpisodesObject:(SapphireSubEpisode*)value_;
- (void)removeSubEpisodesObject:(SapphireSubEpisode*)value_;
- (NSMutableSet*)subEpisodesSet;



- (void)addFiles:(NSSet*)value_;
- (void)removeFiles:(NSSet*)value_;
- (void)addFilesObject:(SapphireFileMetaData*)value_;
- (void)removeFilesObject:(SapphireFileMetaData*)value_;
- (NSMutableSet*)filesSet;



- (SapphireSeason*)season;
- (void)setSeason:(SapphireSeason*)value_;
//- (BOOL)validateSeason:(id*)value_ error:(NSError**)error_;



- (SapphireTVShow*)tvShow;
- (void)setTvShow:(SapphireTVShow*)value_;
//- (BOOL)validateTvShow:(id*)value_ error:(NSError**)error_;



- (void)addXml:(NSSet*)value_;
- (void)removeXml:(NSSet*)value_;
- (void)addXmlObject:(SapphireXMLData*)value_;
- (void)removeXmlObject:(SapphireXMLData*)value_;
- (NSMutableSet*)xmlSet;


@end
