//
//  SapphireMediaMenuController.m
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMediaMenuController.h"
#import "SapphireFrontRowCompat.h"

@implementation SapphireMediaMenuController

- (id)initWithScene:(BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(initWithScene:)])
		return [super initWithScene:scene];
	
	return [super init];
}

- (BRRenderScene *)scene
{
	if([[BRMediaMenuController class] instancesRespondToSelector:@selector(scene)])
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

- (int)getSelection
{
	BRListControl *list = [self list];
	int row;
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(selection)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(selection)];
	[selInv invokeWithTarget:list];
	if([signature methodReturnLength] == 8)
	{
		double retDoub = 0;
		[selInv getReturnValue:&retDoub];
		row = retDoub;
	}
	else
		[selInv getReturnValue:&row];
	return row;
}

- (void)setSelection:(int)sel
{
	BRListControl *list = [self list];
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(setSelection:)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(setSelection:)];
	if(strcmp([signature getArgumentTypeAtIndex:2], "l"))
	{
		double dvalue = sel;
		[selInv setArgument:&dvalue atIndex:2];
	}
	else
	{
		long lvalue = sel;
		[selInv setArgument:&lvalue atIndex:2];
	}
	[selInv invokeWithTarget:list];
}

- (BOOL)brEventAction:(BREvent *)event
{
	BREventPageUsageHash hashVal = [event pageUsageHash];
	if ([(BRControllerStack *)[self stack] peekController] != self)
		hashVal = 0;
	
	int itemCount = [[(BRListControl *)[self list] datasource] itemCount];
	switch (hashVal)
	{	
		case kBREventTapUp:
		case kBREventHoldUp:
			if([self getSelection] == 0 && [event value] == 1)
			{
				[self setSelection:itemCount-1];
				return YES;
			}
			break;
		case kBREventTapDown:
		case kBREventHoldDown:
			if([self getSelection] == itemCount-1 && [event value] == 1)
			{
				[self setSelection:0];
				return YES;
			}
			break;
	}
	return [super brEventAction:event];
}
@end
