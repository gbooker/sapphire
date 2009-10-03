// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireSeason.m instead.

#import "_SapphireSeason.h"

@implementation _SapphireSeason



- (NSNumber*)seasonNumber {
	[self willAccessValueForKey:@"seasonNumber"];
	NSNumber *result = [self primitiveValueForKey:@"seasonNumber"];
	[self didAccessValueForKey:@"seasonNumber"];
	return result;
}

- (void)setSeasonNumber:(NSNumber*)value_ {
	[self willChangeValueForKey:@"seasonNumber"];
	[self setPrimitiveValue:value_ forKey:@"seasonNumber"];
	[self didChangeValueForKey:@"seasonNumber"];
}



- (short)seasonNumberValue {
	NSNumber *result = [self seasonNumber];
	return result ? [result shortValue] : 0;
}

- (void)setSeasonNumberValue:(short)value_ {
	[self setSeasonNumber:[NSNumber numberWithShort:value_]];
}






- (NSString*)seasonDescription {
	[self willAccessValueForKey:@"seasonDescription"];
	NSString *result = [self primitiveValueForKey:@"seasonDescription"];
	[self didAccessValueForKey:@"seasonDescription"];
	return result;
}

- (void)setSeasonDescription:(NSString*)value_ {
	[self willChangeValueForKey:@"seasonDescription"];
	[self setPrimitiveValue:value_ forKey:@"seasonDescription"];
	[self didChangeValueForKey:@"seasonDescription"];
}






	
- (void)addEpisodes:(NSSet*)value_ {
	[self willChangeValueForKey:@"episodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"episodes"] unionSet:value_];
	[self didChangeValueForKey:@"episodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeEpisodes:(NSSet*)value_ {
	[self willChangeValueForKey:@"episodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"episodes"] minusSet:value_];
	[self didChangeValueForKey:@"episodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addEpisodesObject:(SapphireEpisode*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"episodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"episodes"] addObject:value_];
	[self didChangeValueForKey:@"episodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeEpisodesObject:(SapphireEpisode*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"episodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"episodes"] removeObject:value_];
	[self didChangeValueForKey:@"episodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)episodesSet {
	return [self mutableSetValueForKey:@"episodes"];
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

	

@end
