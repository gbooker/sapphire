// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SapphireFileSymLink.m instead.

#import "_SapphireFileSymLink.h"

@implementation _SapphireFileSymLink



	

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

	

	

- (SapphireDirectoryMetaData*)containingDirectory {
	[self willAccessValueForKey:@"containingDirectory"];
	SapphireDirectoryMetaData *result = [self primitiveValueForKey:@"containingDirectory"];
	[self didAccessValueForKey:@"containingDirectory"];
	return result;
}

- (void)setContainingDirectory:(SapphireDirectoryMetaData*)value_ {
	[self willChangeValueForKey:@"containingDirectory"];
	[self setPrimitiveValue:value_ forKey:@"containingDirectory"];
	[self didChangeValueForKey:@"containingDirectory"];
}

	

@end
