// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireEpisode.m instead.

#import "_SapphireEpisode.h"

@implementation _SapphireEpisode



	
- (void)addSubEpisodes:(NSSet*)value_ {
	[self willChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"subEpisodes"] unionSet:value_];
	[self didChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeSubEpisodes:(NSSet*)value_ {
	[self willChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"subEpisodes"] minusSet:value_];
	[self didChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addSubEpisodesObject:(SapphireSubEpisode*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"subEpisodes"] addObject:value_];
	[self didChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeSubEpisodesObject:(SapphireSubEpisode*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"subEpisodes"] removeObject:value_];
	[self didChangeValueForKey:@"subEpisodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)subEpisodesSet {
	return [self mutableSetValueForKey:@"subEpisodes"];
}
	

	

- (SapphireTVShow*)tvShow {
	[self willAccessValueForKey:@"tvShow"];
	SapphireTVShow *result = [self primitiveValueForKey:@"tvShow"];
	[self didAccessValueForKey:@"tvShow"];
	return result;
}

- (void)setTvShow:(SapphireTVShow*)value_ {
	[self willChangeValueForKey:@"tvShow"];
	[self setPrimitiveValue:value_ forKey:@"tvShow"];
	[self didChangeValueForKey:@"tvShow"];
}

	

	
- (void)addFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"files"] unionSet:value_];
	[self didChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeFiles:(NSSet*)value_ {
	[self willChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"files"] minusSet:value_];
	[self didChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"files"] addObject:value_];
	[self didChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeFilesObject:(SapphireFileMetaData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"files"] removeObject:value_];
	[self didChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)filesSet {
	return [self mutableSetValueForKey:@"files"];
}
	

	
- (void)addXml:(NSSet*)value_ {
	[self willChangeValueForKey:@"xml" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"xml"] unionSet:value_];
	[self didChangeValueForKey:@"xml" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeXml:(NSSet*)value_ {
	[self willChangeValueForKey:@"xml" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"xml"] minusSet:value_];
	[self didChangeValueForKey:@"xml" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addXmlObject:(SapphireXMLData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"xml" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"xml"] addObject:value_];
	[self didChangeValueForKey:@"xml" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeXmlObject:(SapphireXMLData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"xml" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"xml"] removeObject:value_];
	[self didChangeValueForKey:@"xml" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)xmlSet {
	return [self mutableSetValueForKey:@"xml"];
}
	

	

- (SapphireSeason*)season {
	[self willAccessValueForKey:@"season"];
	SapphireSeason *result = [self primitiveValueForKey:@"season"];
	[self didAccessValueForKey:@"season"];
	return result;
}

- (void)setSeason:(SapphireSeason*)value_ {
	[self willChangeValueForKey:@"season"];
	[self setPrimitiveValue:value_ forKey:@"season"];
	[self didChangeValueForKey:@"season"];
}

	

@end
