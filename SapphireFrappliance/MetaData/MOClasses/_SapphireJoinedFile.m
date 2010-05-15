// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireJoinedFile.m instead.

#import "_SapphireJoinedFile.h"

@implementation _SapphireJoinedFile





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






	

- (SapphireFileMetaData*)file {
	[self willAccessValueForKey:@"file"];
	SapphireFileMetaData *result = [self primitiveValueForKey:@"file"];
	[self didAccessValueForKey:@"file"];
	return result;
}

- (void)setFile:(SapphireFileMetaData*)value_ {
	[self willChangeValueForKey:@"file"];
	[self setPrimitiveValue:value_ forKey:@"file"];
	[self didChangeValueForKey:@"file"];
}

	

	
- (void)addJoinedFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"joinedFiles"] unionSet:value_];
	[self didChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeJoinedFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"joinedFiles"] minusSet:value_];
	[self didChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addJoinedFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"joinedFiles"] addObject:value_];
	[self didChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeJoinedFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"joinedFiles"] removeObject:value_];
	[self didChangeValueForKey:@"joinedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)joinedFilesSet {
	return [self mutableSetValueForKey:@"joinedFiles"];
}
	

@end
