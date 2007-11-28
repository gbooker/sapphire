//
//  SapphireCenteredMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireCenteredMenuController.h"
#import "SapphireFrontRowCompat.h"

@interface SapphireWideCenteredLayout : NSObject
{
	id		realLayout;
}
@end

@interface SapphireCenteredMenuController (compat)
- (id)firstSublayerNamed:(NSString *)name;
- (void)setLayoutManager:(id)newLayout;
- (id)layoutManager;
@end

@implementation SapphireWideCenteredLayout
- (id)initWithReal:(id)real
{
	self = [super init];
	if(self == nil)
		return self;
	realLayout = [real retain];
	return self;
}

- (void) dealloc
{
	[realLayout release];
	[super dealloc];
}

- (void)layoutSublayersOfLayer:(id)layer
{
	[realLayout layoutSublayersOfLayer:layer];
	NSRect master = [layer frame];
	id listLayer = [layer firstSublayerNamed:@"list"];
	NSRect listFrame = [listLayer frame];
	listFrame.size.height -= 2.5f*listFrame.origin.y;
	listFrame.size.width*=2.0f;
	listFrame.origin.x = (master.size.width - listFrame.size.width) * 0.5f;
	listFrame.origin.y *= 2.0f;
	[listLayer setFrame:listFrame];
}
- (NSSize)preferredSizeOfLayer:(id)layer
{
	return [realLayout preferredSizeOfLayer:layer];
}

@end

@implementation SapphireCenteredMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRCenteredMenuController class] instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	self = [super init];
	SapphireWideCenteredLayout *newLayout = [[SapphireWideCenteredLayout alloc] initWithReal:[self layoutManager]];
	[self setLayoutManager:newLayout];
	[newLayout release];
	return self;
}

- (BRRenderScene *)scene
{
	if([[BRCenteredMenuController class] instancesRespondToSelector:@selector(scene)])
		return [super scene];
	
	return [BRRenderScene sharedInstance];
}

/*Just because so many classes use self as the list data source*/
- (float)heightForRow:(long)row
{
	return 50.0f;
}

- (BOOL)rowSelectable:(long)row
{
	return YES;
}

@end
