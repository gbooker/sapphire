//
//  SapphirePopulateDataMenu.m
//  Sapphire
//
//  Created by pnmerrill on 6/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphirePopulateDataMenu.h"
#import <BackRow/BackRow.h>


@implementation SapphirePopulateDataMenu
- (id) initWithScene: (BRRenderScene *) scene
{
	if ( [super initWithScene: scene] == nil )
	return ( nil );
	// Setup the Header Control with default contents
	_title = [[BRHeaderControl alloc] initWithScene: scene];
	[_title setTitle: @"Populate Show Data"];
	NSRect frame = [[self masterLayer] frame];
	frame.origin.y = frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[_title setFrame: frame];

	// setup the button control
	frame = [[self masterLayer] frame];
	_button = [[BRButtonControl alloc] initWithScene: scene masterLayerSize: frame.size];
	[_button setYPosition: frame.origin.y + (frame.size.height * (1.0f / 8.0f))];
	[_button setTitle: @"Edit Page Title"];
	[_button setTarget: self];
	[_button setAction: @selector(editTitle)];

	// setup the text entry control
	_entry = [[BRTextEntryControl alloc] initWithScene: scene];
	[_entry setFrameFromScreenSize: [[self masterLayer] frame].size];
	[_entry setTextFieldLabel: @"New Title"];
	[_entry setInitialText: [_title title]];
	[_entry setTextEntryCompleteDelegate: self];
	
	_bar = [[BRProgressBarLayer alloc] initWithScene: scene];
	[_bar setValue:0 maxValue:1000] ;
//	[_bar renderInContext];
	[_bar setFrame: frame] ;
	
	
	// add controls
	[self addControl: _title];
//	[self addControl: _bar] ;
	[self addControl: _button];

    return ( self );
}

- (void) dealloc
{
    [_entry setTextEntryCompleteDelegate: nil];
    [_title release];
    [_entry release];
    [_button release];

    [super dealloc];
}

- (void) textDidChange: (id<BRTextContainer>) sender
{
    // do nothing for now
}

- (void) textDidEndEditing: (id<BRTextContainer>) sender
{
    [_title setTitle: [sender stringValue]];
    [self fadeFrom: _entry to: _button];
}

- (void) editTitle
{
    // switch between showing the button and the text entry control
    [self fadeFrom: _button to: _entry];
}

- (void) removeControl: (BRControl *) control
{
    NSMutableArray * array = [NSMutableArray arrayWithArray: [self controls]];
    if ( [array containsObject: control] )
    {
        [[control layer] removeFromSuperlayer];
        [array removeObject: control];
        [self setControls: array];
    }
}

- (void) fadeFrom: (BRControl *) from to: (BRControl *) to
{
    [to setAlphaValue: 0.0f];
    [self addControl: to];

    BRValueAnimation * valanim = [BRValueAnimation fadeInAnimationWithTarget: to
                                  scene: [self scene]];

    BRAggregateAnimation * animation = [BRAggregateAnimation animationWithScene: [self scene]];
    [animation setDuration: [[BRThemeInfo sharedTheme] fadeThroughBlackDuration]];
    [animation addAnimation: valanim];

    valanim = [BRValueAnimation fadeOutAnimationWithTarget: from
                                                     scene: [self scene]];
    [animation addAnimation: valanim];
    [animation run];

    // remove the leaving control so it doesn't eat events
    [self removeControl: from];
}

@end
