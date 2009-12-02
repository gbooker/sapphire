/*
 * SapphireTextEntryController.m
 * Sapphire
 *
 * Created by Graham Booker on Jan. 6, 2009.
 * Copyright 2009 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireTextEntryController.h"
#import "SapphireErrorDisplayController.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@interface BRControl (compat)
- (void)setName:(NSString *)name;
@end

@interface BRLayerController (compat)
- (void)setLayoutManager:(id)layoutManager;
- (void)layoutSubcontrols;
@end


@interface SapphireTextEntryController (private)
- (void)layoutFrame;
@end

@interface BRTextEntryControl (compat)
-(NSSize)preferredFrameSize;
@end


@implementation SapphireTextEntryController

- (id)initWithScene:(BRRenderScene *)scene title:(NSString *)titleText defaultText:(NSString *)defaultText completionInvocation:(NSInvocation *)completetion
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	title = [SapphireFrontRowCompat newTextControlWithScene:scene];
	[SapphireFrontRowCompat setText:titleText withAtrributes:[SapphireFrontRowCompat paragraphTextAttributes] forControl:title];
	[self addControl:title];

	textEntry = [SapphireFrontRowCompat newTextEntryControlWithScene:scene];
	[textEntry setInitialText:defaultText];
	[SapphireFrontRowCompat setDelegate:self forTextEntry:textEntry];
	
	entryComplete = [completetion retain];
	[entryComplete retainArguments];

	[self addControl:textEntry];
	
	//The built in layout manager does a good job here, so fool it with naming of our layers
	Class layoutManagerClass = NSClassFromString(@"BRTextEntryMenuLayoutManager");
	if(layoutManagerClass != nil)
	{
		[title setName:@"header"];
		[textEntry setName:@"editor"];
		id layoutManager = [[layoutManagerClass alloc] init];
		[self setLayoutManager:layoutManager];
		[layoutManager release];
	}
	else
	{
		[self layoutFrame];
	}

	return self;
}

- (void) dealloc
{
	[title release];
	[textEntry release];
	[entryComplete release];
	[super dealloc];
}

NSString *stringOfRect(NSRect rect)
{
	return [NSString stringWithFormat:@"origin:%fx%f size:%fx%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

//ATV 1.1
- (void)layoutFrame
{
#warning These need to be tuned for 1.1, but since I do not have 1.1 here, I cannot test them.
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:title renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 1.0f / 3.0f)];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 1.0f / 3.0f - txtSize.height) * 0.5f + master.size.height * 2.0f/3.0f + master.origin.y;
	frame.size = txtSize;
	[title setFrame:frame];

	frame = master;
	frame.size.height = frame.size.height * 2.0f / 3.0f;
	
	[textEntry setFrame:frame];
	NSLog(@"Setting frame to %@", stringOfRect(frame));
	[textEntry setFrame:frame];
}

//ATV 3
- (void)layoutSubcontrols
{
	[super layoutSubcontrols];
	NSRect master = [SapphireFrontRowCompat frameOfController:self];
	NSSize txtSize = [SapphireFrontRowCompat textControl:title renderedSizeWithMaxSize:NSMakeSize(master.size.width * 2.0f/3.0f, master.size.height * 1.0f/3.0f)];
	
	NSRect frame;
	frame.origin.x = (master.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (master.size.height * 1.0f / 3.0f - txtSize.height) * 0.5f + master.size.height * 2.0f/3.0f + master.origin.y;
	frame.size = txtSize;
	[title setFrame:frame];
	
	frame = master;
	frame.size = [textEntry preferredFrameSize];
	frame.origin.x = (master.size.width - frame.size.width) * 0.5f;
	frame.origin.y = (master.size.height * 2.0f / 3.0f - frame.size.height) * 0.5f;

	[textEntry setFrame:frame];
}

- (void)textDidChange:(id)sender
{
	//Do nothing
}

- (void)textDidEndEditing:(id)sender
{
	NSString *str = [sender stringValue];
	[entryComplete setArgument:&str atIndex:2];
	[entryComplete invoke];
	
	NSString *errorString = nil;
	[entryComplete getReturnValue:&errorString];
	if(errorString != nil)
	{
		SapphireErrorDisplayController *display = [[SapphireErrorDisplayController alloc] initWithScene:[self scene] error:BRLocalizedString(@"Error", @"Short message indicating error condition") longError:errorString];
		[[self stack] pushController:display];
		[display autorelease];
	}
	else
		[[self stack] popController];
}

@end
