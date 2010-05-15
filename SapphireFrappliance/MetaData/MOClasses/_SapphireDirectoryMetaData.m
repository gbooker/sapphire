// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireDirectoryMetaData.m instead.

#import "_SapphireDirectoryMetaData.h"

@implementation _SapphireDirectoryMetaData





- (NSString*)path {
	[self willAccessValueForKey:@"path"];
	NSString *result = [self primitiveValueForKey:@"path"];
	[self didAccessValueForKey:@"path"];
	return result;
}

- (void)setPath:(NSString*)value_ {
	[self willChangeValueForKey:@"path"];
	[self setPrimitiveValue:value_ forKey:@"path"];
	[self didChangeValueForKey:@"path"];
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






	
- (void)addLinkedParents:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedParents"] unionSet:value_];
	[self didChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeLinkedParents:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedParents"] minusSet:value_];
	[self didChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addLinkedParentsObject:(SapphireDirectorySymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedParents"] addObject:value_];
	[self didChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeLinkedParentsObject:(SapphireDirectorySymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedParents"] removeObject:value_];
	[self didChangeValueForKey:@"linkedParents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)linkedParentsSet {
	return [self mutableSetValueForKey:@"linkedParents"];
}
	

	

- (SapphireCollectionDirectory*)collectionDirectory {
	[self willAccessValueForKey:@"collectionDirectory"];
	SapphireCollectionDirectory *result = [self primitiveValueForKey:@"collectionDirectory"];
	[self didAccessValueForKey:@"collectionDirectory"];
	return result;
}

- (void)setCollectionDirectory:(SapphireCollectionDirectory*)value_ {
	[self willChangeValueForKey:@"collectionDirectory"];
	[self setPrimitiveValue:value_ forKey:@"collectionDirectory"];
	[self didChangeValueForKey:@"collectionDirectory"];
}

	

	
- (void)addMetaDirs:(NSSet*)value_ {
	[self willChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"metaDirs"] unionSet:value_];
	[self didChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeMetaDirs:(NSSet*)value_ {
	[self willChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"metaDirs"] minusSet:value_];
	[self didChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addMetaDirsObject:(SapphireDirectoryMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"metaDirs"] addObject:value_];
	[self didChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeMetaDirsObject:(SapphireDirectoryMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"metaDirs"] removeObject:value_];
	[self didChangeValueForKey:@"metaDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)metaDirsSet {
	return [self mutableSetValueForKey:@"metaDirs"];
}
	

	
- (void)addLinkedDirs:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedDirs"] unionSet:value_];
	[self didChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeLinkedDirs:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedDirs"] minusSet:value_];
	[self didChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addLinkedDirsObject:(SapphireDirectorySymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedDirs"] addObject:value_];
	[self didChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeLinkedDirsObject:(SapphireDirectorySymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedDirs"] removeObject:value_];
	[self didChangeValueForKey:@"linkedDirs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)linkedDirsSet {
	return [self mutableSetValueForKey:@"linkedDirs"];
}
	

	
- (void)addMetaFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"metaFiles"] unionSet:value_];
	[self didChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeMetaFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"metaFiles"] minusSet:value_];
	[self didChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addMetaFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"metaFiles"] addObject:value_];
	[self didChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeMetaFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"metaFiles"] removeObject:value_];
	[self didChangeValueForKey:@"metaFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)metaFilesSet {
	return [self mutableSetValueForKey:@"metaFiles"];
}
	

	

- (SapphireDirectoryMetaData*)parent {
	[self willAccessValueForKey:@"parent"];
	SapphireDirectoryMetaData *result = [self primitiveValueForKey:@"parent"];
	[self didAccessValueForKey:@"parent"];
	return result;
}

- (void)setParent:(SapphireDirectoryMetaData*)value_ {
	[self willChangeValueForKey:@"parent"];
	[self setPrimitiveValue:value_ forKey:@"parent"];
	[self didChangeValueForKey:@"parent"];
}

	

	
- (void)addLinkedFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedFiles"] unionSet:value_];
	[self didChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeLinkedFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"linkedFiles"] minusSet:value_];
	[self didChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addLinkedFilesObject:(SapphireFileSymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedFiles"] addObject:value_];
	[self didChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeLinkedFilesObject:(SapphireFileSymLink*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"linkedFiles"] removeObject:value_];
	[self didChangeValueForKey:@"linkedFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)linkedFilesSet {
	return [self mutableSetValueForKey:@"linkedFiles"];
}
	

@end
