// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireSubEpisode.m instead.

#import "_SapphireSubEpisode.h"

@implementation _SapphireSubEpisode



- (NSDate*)airDate {
	[self willAccessValueForKey:@"airDate"];
	NSDate *result = [self primitiveValueForKey:@"airDate"];
	[self didAccessValueForKey:@"airDate"];
	return result;
}

- (void)setAirDate:(NSDate*)value_ {
	[self willChangeValueForKey:@"airDate"];
	[self setPrimitiveValue:value_ forKey:@"airDate"];
	[self didChangeValueForKey:@"airDate"];
}






- (NSNumber*)episodeNumber {
	[self willAccessValueForKey:@"episodeNumber"];
	NSNumber *result = [self primitiveValueForKey:@"episodeNumber"];
	[self didAccessValueForKey:@"episodeNumber"];
	return result;
}

- (void)setEpisodeNumber:(NSNumber*)value_ {
	[self willChangeValueForKey:@"episodeNumber"];
	[self setPrimitiveValue:value_ forKey:@"episodeNumber"];
	[self didChangeValueForKey:@"episodeNumber"];
}



- (short)episodeNumberValue {
	NSNumber *result = [self episodeNumber];
	return result ? [result shortValue] : 0;
}

- (void)setEpisodeNumberValue:(short)value_ {
	[self setEpisodeNumber:[NSNumber numberWithShort:value_]];
}






- (NSNumber*)absoluteEpisodeNumber {
	[self willAccessValueForKey:@"absoluteEpisodeNumber"];
	NSNumber *result = [self primitiveValueForKey:@"absoluteEpisodeNumber"];
	[self didAccessValueForKey:@"absoluteEpisodeNumber"];
	return result;
}

- (void)setAbsoluteEpisodeNumber:(NSNumber*)value_ {
	[self willChangeValueForKey:@"absoluteEpisodeNumber"];
	[self setPrimitiveValue:value_ forKey:@"absoluteEpisodeNumber"];
	[self didChangeValueForKey:@"absoluteEpisodeNumber"];
}



- (short)absoluteEpisodeNumberValue {
	NSNumber *result = [self absoluteEpisodeNumber];
	return result ? [result shortValue] : 0;
}

- (void)setAbsoluteEpisodeNumberValue:(short)value_ {
	[self setAbsoluteEpisodeNumber:[NSNumber numberWithShort:value_]];
}






- (NSString*)episodeDescription {
	[self willAccessValueForKey:@"episodeDescription"];
	NSString *result = [self primitiveValueForKey:@"episodeDescription"];
	[self didAccessValueForKey:@"episodeDescription"];
	return result;
}

- (void)setEpisodeDescription:(NSString*)value_ {
	[self willChangeValueForKey:@"episodeDescription"];
	[self setPrimitiveValue:value_ forKey:@"episodeDescription"];
	[self didChangeValueForKey:@"episodeDescription"];
}






- (NSString*)episodeTitle {
	[self willAccessValueForKey:@"episodeTitle"];
	NSString *result = [self primitiveValueForKey:@"episodeTitle"];
	[self didAccessValueForKey:@"episodeTitle"];
	return result;
}

- (void)setEpisodeTitle:(NSString*)value_ {
	[self willChangeValueForKey:@"episodeTitle"];
	[self setPrimitiveValue:value_ forKey:@"episodeTitle"];
	[self didChangeValueForKey:@"episodeTitle"];
}






	

- (SapphireEpisode*)episode {
	[self willAccessValueForKey:@"episode"];
	SapphireEpisode *result = [self primitiveValueForKey:@"episode"];
	[self didAccessValueForKey:@"episode"];
	return result;
}

- (void)setEpisode:(SapphireEpisode*)value_ {
	[self willChangeValueForKey:@"episode"];
	[self setPrimitiveValue:value_ forKey:@"episode"];
	[self didChangeValueForKey:@"episode"];
}

	

@end
