// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireDirector.m instead.

#import "_SapphireDirector.h"

@implementation _SapphireDirector



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






	
- (void)addMovies:(NSSet*)value_ {
	[self willChangeValueForKey:@"movies" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"movies"] unionSet:value_];
	[self didChangeValueForKey:@"movies" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value_];
}

-(void)removeMovies:(NSSet*)value_ {
	[self willChangeValueForKey:@"movies" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
	[[self primitiveValueForKey:@"movies"] minusSet:value_];
	[self didChangeValueForKey:@"movies" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value_];
}
	
- (void)addMoviesObject:(SapphireMovie*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"movies" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"movies"] addObject:value_];
	[self didChangeValueForKey:@"movies" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (void)removeMoviesObject:(SapphireMovie*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"movies" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"movies"] removeObject:value_];
	[self didChangeValueForKey:@"movies" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)moviesSet {
	return [self mutableSetValueForKey:@"movies"];
}
	

@end
