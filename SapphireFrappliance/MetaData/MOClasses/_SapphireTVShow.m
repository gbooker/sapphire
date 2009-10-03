// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireTVShow.m instead.

#import "_SapphireTVShow.h"

@implementation _SapphireTVShow



- (NSString*)showDescription {
	[self willAccessValueForKey:@"showDescription"];
	NSString *result = [self primitiveValueForKey:@"showDescription"];
	[self didAccessValueForKey:@"showDescription"];
	return result;
}

- (void)setShowDescription:(NSString*)value_ {
	[self willChangeValueForKey:@"showDescription"];
	[self setPrimitiveValue:value_ forKey:@"showDescription"];
	[self didChangeValueForKey:@"showDescription"];
}






- (NSNumber*)showID {
	[self willAccessValueForKey:@"showID"];
	NSNumber *result = [self primitiveValueForKey:@"showID"];
	[self didAccessValueForKey:@"showID"];
	return result;
}

- (void)setShowID:(NSNumber*)value_ {
	[self willChangeValueForKey:@"showID"];
	[self setPrimitiveValue:value_ forKey:@"showID"];
	[self didChangeValueForKey:@"showID"];
}



- (int)showIDValue {
	NSNumber *result = [self showID];
	return result ? [result intValue] : 0;
}

- (void)setShowIDValue:(int)value_ {
	[self setShowID:[NSNumber numberWithInt:value_]];
}






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






- (NSString*)showPath {
	[self willAccessValueForKey:@"showPath"];
	NSString *result = [self primitiveValueForKey:@"showPath"];
	[self didAccessValueForKey:@"showPath"];
	return result;
}

- (void)setShowPath:(NSString*)value_ {
	[self willChangeValueForKey:@"showPath"];
	[self setPrimitiveValue:value_ forKey:@"showPath"];
	[self didChangeValueForKey:@"showPath"];
}






	
- (void)addSeasons:(NSSet*)value_ {
	[self willChangeValueForKey:@"seasons" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"seasons"] unionSet:value_];
	[self didChangeValueForKey:@"seasons" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeSeasons:(NSSet*)value_ {
	[self willChangeValueForKey:@"seasons" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"seasons"] minusSet:value_];
	[self didChangeValueForKey:@"seasons" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addSeasonsObject:(SapphireSeason*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"seasons" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"seasons"] addObject:value_];
	[self didChangeValueForKey:@"seasons" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeSeasonsObject:(SapphireSeason*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"seasons" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"seasons"] removeObject:value_];
	[self didChangeValueForKey:@"seasons" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)seasonsSet {
	return [self mutableSetValueForKey:@"seasons"];
}
	

	
- (void)addTranslations:(NSSet*)value_ {
	[self willChangeValueForKey:@"translations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"translations"] unionSet:value_];
	[self didChangeValueForKey:@"translations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeTranslations:(NSSet*)value_ {
	[self willChangeValueForKey:@"translations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"translations"] minusSet:value_];
	[self didChangeValueForKey:@"translations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addTranslationsObject:(SapphireTVTranslation*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"translations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"translations"] addObject:value_];
	[self didChangeValueForKey:@"translations" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeTranslationsObject:(SapphireTVTranslation*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"translations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"translations"] removeObject:value_];
	[self didChangeValueForKey:@"translations" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)translationsSet {
	return [self mutableSetValueForKey:@"translations"];
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
	

@end
