// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMoviePoster.m instead.

#import "_SapphireMoviePoster.h"

@implementation _SapphireMoviePoster



- (NSData*)otherPropertiesData {
	[self willAccessValueForKey:@"otherPropertiesData"];
	NSData *result = [self primitiveValueForKey:@"otherPropertiesData"];
	[self didAccessValueForKey:@"otherPropertiesData"];
	return result;
}

- (void)setOtherPropertiesData:(NSData*)value_ {
	[self willChangeValueForKey:@"otherPropertiesData"];
	[self setPrimitiveValue:value_ forKey:@"otherPropertiesData"];
	[self didChangeValueForKey:@"otherPropertiesData"];
}








- (NSString*)link {
	[self willAccessValueForKey:@"link"];
	NSString *result = [self primitiveValueForKey:@"link"];
	[self didAccessValueForKey:@"link"];
	return result;
}

- (void)setLink:(NSString*)value_ {
	[self willChangeValueForKey:@"link"];
	[self setPrimitiveValue:value_ forKey:@"link"];
	[self didChangeValueForKey:@"link"];
}






- (NSNumber*)index {
	[self willAccessValueForKey:@"index"];
	NSNumber *result = [self primitiveValueForKey:@"index"];
	[self didAccessValueForKey:@"index"];
	return result;
}

- (void)setIndex:(NSNumber*)value_ {
	[self willChangeValueForKey:@"index"];
	[self setPrimitiveValue:value_ forKey:@"index"];
	[self didChangeValueForKey:@"index"];
}



- (short)indexValue {
	NSNumber *result = [self index];
	return result ? [result shortValue] : 0;
}

- (void)setIndexValue:(short)value_ {
	[self setIndex:[NSNumber numberWithShort:value_]];
}






	

- (SapphireMovieTranslation*)movieTranslation {
	[self willAccessValueForKey:@"movieTranslation"];
	SapphireMovieTranslation *result = [self primitiveValueForKey:@"movieTranslation"];
	[self didAccessValueForKey:@"movieTranslation"];
	return result;
}

- (void)setMovieTranslation:(SapphireMovieTranslation*)value_ {
	[self willChangeValueForKey:@"movieTranslation"];
	[self setPrimitiveValue:value_ forKey:@"movieTranslation"];
	[self didChangeValueForKey:@"movieTranslation"];
}

	

@end
