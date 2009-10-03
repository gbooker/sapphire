// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireCollectionDirectory.m instead.

#import "_SapphireCollectionDirectory.h"

@implementation _SapphireCollectionDirectory



- (NSString*)name {
	[self willAccessValueForKey:@"name"];
	NSString *result = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];
	return result;
}

- (void)setName:(NSString*)value_ {
	[self willChangeValueForKey:@"name"];
	[self setPrimitiveValue:value_ forKey:@"name"];
	[self didChangeValueForKey:@"name"];
}








- (NSNumber*)isMount {
	[self willAccessValueForKey:@"isMount"];
	NSNumber *result = [self primitiveValueForKey:@"isMount"];
	[self didAccessValueForKey:@"isMount"];
	return result;
}

- (void)setIsMount:(NSNumber*)value_ {
	[self willChangeValueForKey:@"isMount"];
	[self setPrimitiveValue:value_ forKey:@"isMount"];
	[self didChangeValueForKey:@"isMount"];
}



- (BOOL)isMountValue {
	NSNumber *result = [self isMount];
	return result ? [result boolValue] : 0;
}

- (void)setIsMountValue:(BOOL)value_ {
	[self setIsMount:[NSNumber numberWithBool:value_]];
}






- (NSNumber*)hidden {
	[self willAccessValueForKey:@"hidden"];
	NSNumber *result = [self primitiveValueForKey:@"hidden"];
	[self didAccessValueForKey:@"hidden"];
	return result;
}

- (void)setHidden:(NSNumber*)value_ {
	[self willChangeValueForKey:@"hidden"];
	[self setPrimitiveValue:value_ forKey:@"hidden"];
	[self didChangeValueForKey:@"hidden"];
}



- (BOOL)hiddenValue {
	NSNumber *result = [self hidden];
	return result ? [result boolValue] : 0;
}

- (void)setHiddenValue:(BOOL)value_ {
	[self setHidden:[NSNumber numberWithBool:value_]];
}






- (NSNumber*)skip {
	[self willAccessValueForKey:@"skip"];
	NSNumber *result = [self primitiveValueForKey:@"skip"];
	[self didAccessValueForKey:@"skip"];
	return result;
}

- (void)setSkip:(NSNumber*)value_ {
	[self willChangeValueForKey:@"skip"];
	[self setPrimitiveValue:value_ forKey:@"skip"];
	[self didChangeValueForKey:@"skip"];
}



- (BOOL)skipValue {
	NSNumber *result = [self skip];
	return result ? [result boolValue] : 0;
}

- (void)setSkipValue:(BOOL)value_ {
	[self setSkip:[NSNumber numberWithBool:value_]];
}






- (NSNumber*)manualCollection {
	[self willAccessValueForKey:@"manualCollection"];
	NSNumber *result = [self primitiveValueForKey:@"manualCollection"];
	[self didAccessValueForKey:@"manualCollection"];
	return result;
}

- (void)setManualCollection:(NSNumber*)value_ {
	[self willChangeValueForKey:@"manualCollection"];
	[self setPrimitiveValue:value_ forKey:@"manualCollection"];
	[self didChangeValueForKey:@"manualCollection"];
}



- (BOOL)manualCollectionValue {
	NSNumber *result = [self manualCollection];
	return result ? [result boolValue] : 0;
}

- (void)setManualCollectionValue:(BOOL)value_ {
	[self setManualCollection:[NSNumber numberWithBool:value_]];
}






- (NSData*)mountInformationData {
	[self willAccessValueForKey:@"mountInformationData"];
	NSData *result = [self primitiveValueForKey:@"mountInformationData"];
	[self didAccessValueForKey:@"mountInformationData"];
	return result;
}

- (void)setMountInformationData:(NSData*)value_ {
	[self willChangeValueForKey:@"mountInformationData"];
	[self setPrimitiveValue:value_ forKey:@"mountInformationData"];
	[self didChangeValueForKey:@"mountInformationData"];
}






	

- (SapphireDirectoryMetaData*)directory {
	[self willAccessValueForKey:@"directory"];
	SapphireDirectoryMetaData *result = [self primitiveValueForKey:@"directory"];
	[self didAccessValueForKey:@"directory"];
	return result;
}

- (void)setDirectory:(SapphireDirectoryMetaData*)value_ {
	[self willChangeValueForKey:@"directory"];
	[self setPrimitiveValue:value_ forKey:@"directory"];
	[self didChangeValueForKey:@"directory"];
}

	

@end
