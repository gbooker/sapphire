// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMovieTranslation.m instead.

#import "_SapphireMovieTranslation.h"

@implementation _SapphireMovieTranslation



- (NSNumber*)selectedPosterIndex {
	[self willAccessValueForKey:@"selectedPosterIndex"];
	NSNumber *result = [self primitiveValueForKey:@"selectedPosterIndex"];
	[self didAccessValueForKey:@"selectedPosterIndex"];
	return result;
}

- (void)setSelectedPosterIndex:(NSNumber*)value_ {
	[self willChangeValueForKey:@"selectedPosterIndex"];
	[self setPrimitiveValue:value_ forKey:@"selectedPosterIndex"];
	[self didChangeValueForKey:@"selectedPosterIndex"];
}



- (short)selectedPosterIndexValue {
	NSNumber *result = [self selectedPosterIndex];
	return result ? [result shortValue] : 0;
}

- (void)setSelectedPosterIndexValue:(short)value_ {
	[self setSelectedPosterIndex:[NSNumber numberWithShort:value_]];
}






	
- (void)addPosters:(NSSet*)value_ {
	[self willChangeValueForKey:@"posters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"posters"] unionSet:value_];
	[self didChangeValueForKey:@"posters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removePosters:(NSSet*)value_ {
	[self willChangeValueForKey:@"posters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"posters"] minusSet:value_];
	[self didChangeValueForKey:@"posters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addPostersObject:(SapphireMoviePoster*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"posters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"posters"] addObject:value_];
	[self didChangeValueForKey:@"posters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removePostersObject:(SapphireMoviePoster*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"posters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"posters"] removeObject:value_];
	[self didChangeValueForKey:@"posters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)postersSet {
	return [self mutableSetValueForKey:@"posters"];
}
	

	

- (SapphireMovie*)movie {
	[self willAccessValueForKey:@"movie"];
	SapphireMovie *result = [self primitiveValueForKey:@"movie"];
	[self didAccessValueForKey:@"movie"];
	return result;
}

- (void)setMovie:(SapphireMovie*)value_ {
	[self willChangeValueForKey:@"movie"];
	[self setPrimitiveValue:value_ forKey:@"movie"];
	[self didChangeValueForKey:@"movie"];
}

	

@end
