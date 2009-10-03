// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireMovieTranslation.m instead.

#import "_SapphireMovieTranslation.h"

@implementation _SapphireMovieTranslation



- (NSString*)IMPLink {
	[self willAccessValueForKey:@"IMPLink"];
	NSString *result = [self primitiveValueForKey:@"IMPLink"];
	[self didAccessValueForKey:@"IMPLink"];
	return result;
}

- (void)setIMPLink:(NSString*)value_ {
	[self willChangeValueForKey:@"IMPLink"];
	[self setPrimitiveValue:value_ forKey:@"IMPLink"];
	[self didChangeValueForKey:@"IMPLink"];
}






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






- (NSString*)IMDBLink {
	[self willAccessValueForKey:@"IMDBLink"];
	NSString *result = [self primitiveValueForKey:@"IMDBLink"];
	[self didAccessValueForKey:@"IMDBLink"];
	return result;
}

- (void)setIMDBLink:(NSString*)value_ {
	[self willChangeValueForKey:@"IMDBLink"];
	[self setPrimitiveValue:value_ forKey:@"IMDBLink"];
	[self didChangeValueForKey:@"IMDBLink"];
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
	

@end
