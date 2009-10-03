// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireSubEpisode.h instead.

#import <CoreData/CoreData.h>



@class SapphireEpisode;


@interface _SapphireSubEpisode : NSManagedObject {}


- (NSDate*)airDate;
- (void)setAirDate:(NSDate*)value_;

//- (BOOL)validateAirDate:(id*)value_ error:(NSError**)error_;



- (NSNumber*)episodeNumber;
- (void)setEpisodeNumber:(NSNumber*)value_;

- (short)episodeNumberValue;
- (void)setEpisodeNumberValue:(short)value_;

//- (BOOL)validateEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSNumber*)absoluteEpisodeNumber;
- (void)setAbsoluteEpisodeNumber:(NSNumber*)value_;

- (short)absoluteEpisodeNumberValue;
- (void)setAbsoluteEpisodeNumberValue:(short)value_;

//- (BOOL)validateAbsoluteEpisodeNumber:(id*)value_ error:(NSError**)error_;



- (NSString*)episodeDescription;
- (void)setEpisodeDescription:(NSString*)value_;

//- (BOOL)validateEpisodeDescription:(id*)value_ error:(NSError**)error_;



- (NSString*)episodeTitle;
- (void)setEpisodeTitle:(NSString*)value_;

//- (BOOL)validateEpisodeTitle:(id*)value_ error:(NSError**)error_;




- (SapphireEpisode*)episode;
- (void)setEpisode:(SapphireEpisode*)value_;
//- (BOOL)validateEpisode:(id*)value_ error:(NSError**)error_;


@end
