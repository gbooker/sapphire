/*
 * SapphireWaitDisplay.m
 * Sapphire
 *
 * Created by Graham Booker on Feb. 11 2009.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SapphireWaitDisplay.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>
#import "SapphireApplianceController.h"


@implementation SapphireWaitDisplay

- (id) initWithScene:(BRRenderScene *)scene title:(NSString *)title invocation:(NSInvocation *)invocation
{
	self = [super initWithScene:scene];
	if(self == nil)
		return self;
	
	[self setListTitle:title];
	invoke = [invocation retain];
	[invoke retainArguments];
	
	status = [SapphireFrontRowCompat newTextControlWithScene:scene];
	if([BRWaitSpinnerControl instancesRespondToSelector:@selector(initWithScene:)])
		spinner = [[BRWaitSpinnerControl alloc] initWithScene:scene];
	else
		spinner = [[BRWaitSpinnerControl alloc] init];
	
	if([SapphireFrontRowCompat usingLeopard])
	{
		[spinner release];
		spinner = [[BRWaitSpinnerLayer alloc] init];
	}
	
	[self doMyLayout];
	
	[self addControl:status];
	if([SapphireFrontRowCompat usingLeopard])
		[SapphireFrontRowCompat addSublayer:spinner toControl:self];
	else
		[self addControl:spinner];
	
	[SapphireLayoutManager setCustomLayoutOnControl:self];
	
	return self;
	
}

- (void)doMyLayout
{
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	NSRect newFrame;
	newFrame.size.width = newFrame.size.height = frame.size.height / 6.0f;
	newFrame.origin.y += (frame.size.height - newFrame.size.height) / 2.0f;
	newFrame.origin.x = (frame.size.width - newFrame.size.width) / 2.0f;
	[spinner setFrame:newFrame] ;
}

- (void) dealloc
{
	[spinner release];
	[status release];
	[invoke release];
	[super dealloc];
}

- (void)realCurrentStatus:(NSString *)stat;
{
	if(stat == nil)
		stat = @"";
	[SapphireFrontRowCompat setText:stat withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:status];
	
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize progressSize = [SapphireFrontRowCompat textControl:status renderedSizeWithMaxSize:NSMakeSize(master.size.width, master.size.height * 0.3f)];
	
	NSRect frame;
	frame.origin.x =  (master.size.width) * 0.1f;
	frame.origin.y = (master.size.height * 0.12f) + master.origin.y;
	frame.size = progressSize;
	[status setFrame:frame];
}

- (void)setCurrentStatus:(NSString *)stat;
{
	if(runInThread)
		[self performSelectorOnMainThread:@selector(realCurrentStatus:) withObject:stat waitUntilDone:YES];
	else
	{
		[self realCurrentStatus:stat];
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:1]];
	}
}

- (void)finished
{
	BRControl *ret = nil;
	[invoke getReturnValue:&ret];
	completed = YES;
	
	if(!noPopWhenComplete)
	{
		if(ret == nil)
			[[self stack] popController];
		else
			[[self stack] swapController:ret];
	}
	else if(ret != nil)
		[[self stack] pushController:ret];
}

- (void)start
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[invoke invoke];
	
	[self performSelectorOnMainThread:@selector(finished) withObject:nil waitUntilDone:YES];
	[pool drain];
}

- (void)wasPushed
{
	[super wasPushed];
	[SapphireFrontRowCompat setSpinner:spinner toSpin:YES];
	if(runInThread)
		[NSThread detachNewThreadSelector:@selector(start) toTarget:self withObject:nil];
	else
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(start) userInfo:nil repeats:NO];
}

- (BOOL)brEventAction:(BREvent *)event
{
	if(!completed)
		return YES;
	return [super brEventAction:event];
}

@end
