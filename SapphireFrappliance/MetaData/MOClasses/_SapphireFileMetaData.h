// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireFileMetaData.h instead.

#import <CoreData/CoreData.h>



@class SapphireFileSymLink;

@class SapphireJoinedFile;

@class SapphireJoinedFile;

@class SapphireXMLData;

@class SapphireDirectoryMetaData;

@class SapphireEpisode;

@class SapphireMovie;


@interface _SapphireFileMetaData : NSManagedObject {}


- (NSNumber*)hasVideo;
- (void)setHasVideo:(NSNumber*)value_;

- (BOOL)hasVideoValue;
- (void)setHasVideoValue:(BOOL)value_;

//- (BOOL)validateHasVideo:(id*)value_ error:(NSError**)error_;



- (NSNumber*)audioFormatID;
- (void)setAudioFormatID:(NSNumber*)value_;

- (int)audioFormatIDValue;
- (void)setAudioFormatIDValue:(int)value_;

//- (BOOL)validateAudioFormatID:(id*)value_ error:(NSError**)error_;



- (NSNumber*)sampleRate;
- (void)setSampleRate:(NSNumber*)value_;

- (double)sampleRateValue;
- (void)setSampleRateValue:(double)value_;

//- (BOOL)validateSampleRate:(id*)value_ error:(NSError**)error_;



- (NSString*)subtitlesDescription;
- (void)setSubtitlesDescription:(NSString*)value_;

//- (BOOL)validateSubtitlesDescription:(id*)value_ error:(NSError**)error_;



- (NSNumber*)resumeTime;
- (void)setResumeTime:(NSNumber*)value_;

- (int)resumeTimeValue;
- (void)setResumeTimeValue:(int)value_;

//- (BOOL)validateResumeTime:(id*)value_ error:(NSError**)error_;



- (NSNumber*)fileClass;
- (void)setFileClass:(NSNumber*)value_;

- (short)fileClassValue;
- (void)setFileClassValue:(short)value_;

//- (BOOL)validateFileClass:(id*)value_ error:(NSError**)error_;



- (NSString*)path;
- (void)setPath:(NSString*)value_;

//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;



- (NSNumber*)size;
- (void)setSize:(NSNumber*)value_;

- (long long)sizeValue;
- (void)setSizeValue:(long long)value_;

//- (BOOL)validateSize:(id*)value_ error:(NSError**)error_;



- (NSNumber*)favorite;
- (void)setFavorite:(NSNumber*)value_;

- (BOOL)favoriteValue;
- (void)setFavoriteValue:(BOOL)value_;

//- (BOOL)validateFavorite:(id*)value_ error:(NSError**)error_;



- (NSNumber*)watched;
- (void)setWatched:(NSNumber*)value_;

- (BOOL)watchedValue;
- (void)setWatchedValue:(BOOL)value_;

//- (BOOL)validateWatched:(id*)value_ error:(NSError**)error_;





- (NSNumber*)duration;
- (void)setDuration:(NSNumber*)value_;

- (float)durationValue;
- (void)setDurationValue:(float)value_;

//- (BOOL)validateDuration:(id*)value_ error:(NSError**)error_;



- (NSNumber*)importType;
- (void)setImportType:(NSNumber*)value_;

- (int)importTypeValue;
- (void)setImportTypeValue:(int)value_;

//- (BOOL)validateImportType:(id*)value_ error:(NSError**)error_;



- (NSNumber*)fileContainerType;
- (void)setFileContainerType:(NSNumber*)value_;

- (short)fileContainerTypeValue;
- (void)setFileContainerTypeValue:(short)value_;

//- (BOOL)validateFileContainerType:(id*)value_ error:(NSError**)error_;



- (NSString*)videoDescription;
- (void)setVideoDescription:(NSString*)value_;

//- (BOOL)validateVideoDescription:(id*)value_ error:(NSError**)error_;



- (NSDate*)added;
- (void)setAdded:(NSDate*)value_;

//- (BOOL)validateAdded:(id*)value_ error:(NSError**)error_;



- (NSDate*)modified;
- (void)setModified:(NSDate*)value_;

//- (BOOL)validateModified:(id*)value_ error:(NSError**)error_;



- (NSData*)otherPropertiesData;
- (void)setOtherPropertiesData:(NSData*)value_;

//- (BOOL)validateOtherPropertiesData:(id*)value_ error:(NSError**)error_;



- (NSString*)audioDescription;
- (void)setAudioDescription:(NSString*)value_;

//- (BOOL)validateAudioDescription:(id*)value_ error:(NSError**)error_;




- (void)addLinkedParents:(NSSet*)value_;
- (void)removeLinkedParents:(NSSet*)value_;
- (void)addLinkedParentsObject:(SapphireFileSymLink*)value_;
- (void)removeLinkedParentsObject:(SapphireFileSymLink*)value_;
- (NSMutableSet*)linkedParentsSet;



- (SapphireJoinedFile*)joinedToFile;
- (void)setJoinedToFile:(SapphireJoinedFile*)value_;
//- (BOOL)validateJoinedToFile:(id*)value_ error:(NSError**)error_;



- (SapphireJoinedFile*)joinedFile;
- (void)setJoinedFile:(SapphireJoinedFile*)value_;
//- (BOOL)validateJoinedFile:(id*)value_ error:(NSError**)error_;



- (SapphireXMLData*)xmlData;
- (void)setXmlData:(SapphireXMLData*)value_;
//- (BOOL)validateXmlData:(id*)value_ error:(NSError**)error_;



- (SapphireDirectoryMetaData*)parent;
- (void)setParent:(SapphireDirectoryMetaData*)value_;
//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;



- (SapphireEpisode*)tvEpisode;
- (void)setTvEpisode:(SapphireEpisode*)value_;
//- (BOOL)validateTvEpisode:(id*)value_ error:(NSError**)error_;



- (SapphireMovie*)movie;
- (void)setMovie:(SapphireMovie*)value_;
//- (BOOL)validateMovie:(id*)value_ error:(NSError**)error_;


@end
