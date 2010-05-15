// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireCategoryDirectory.m instead.

#import "_SapphireCategoryDirectory.h"

@implementation _SapphireCategoryDirectory



- (NSNumber*)sortMethod {
	[self willAccessValueForKey:@"sortMethod"];
	NSNumber *result = [self primitiveValueForKey:@"sortMethod"];
	[self didAccessValueForKey:@"sortMethod"];
	return result;
}

- (void)setSortMethod:(NSNumber*)value_ {
	[self willChangeValueForKey:@"sortMethod"];
	[self setPrimitiveValue:value_ forKey:@"sortMethod"];
	[self didChangeValueForKey:@"sortMethod"];
}



- (int)sortMethodValue {
	NSNumber *result = [self sortMethod];
	return result ? [result intValue] : 0;
}

- (void)setSortMethodValue:(int)value_ {
	[self setSortMethod:[NSNumber numberWithInt:value_]];
}








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






@end
