/*
 * CMPProgressBarControl.m
 * CommonMediaPlayer
 *
 * Created by nito on Feb. 25 2010
 * Copyright 2010 Common Media Player
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this program; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
 * 02111-1307, USA.
 */


#import "CMPProgressBarControl.h"
#import <BackRow/BackRow.h>

@implementation CMPProgressBarControl

- (id) init
{
	self = [super init];
	
    _widget = [[BRProgressBarWidget alloc] init];
	
    [self addControl: _widget];
	
    // defaults
    _maxValue = 100.0f;
    _minValue = 0.0f;
	
    return self;
}

- (void) dealloc
{
    [_widget release];
    //[_layer release];

    [super dealloc];
}

- (void) setFrame: (NSRect) frame
{
    [super setFrame: frame];
	
    NSRect widgetFrame = NSZeroRect;
    widgetFrame.size.width = frame.size.width;
    widgetFrame.size.height = ceilf( frame.size.width * 0.068f );
    [_widget setFrame: widgetFrame];
}



- (void) setMaxValue: (float) maxValue
{
    @synchronized(self)
    {
        _maxValue = maxValue;
    }
}

- (float) maxValue
{
    return ( _maxValue );
}

- (void) setMinValue: (float) minValue
{
    @synchronized(self)
    {
        _minValue = minValue;
    }
}

- (float) minValue
{
    return ( _minValue );
}

- (void) setCurrentValue: (float) currentValue
{
    @synchronized(self)
    {
        float range = _maxValue - _minValue;
        float value = currentValue - _minValue;
        float percentage = (value / range) * 100.0f;
        [_widget setPercentage: percentage];
    }
}

- (float) currentValue
{
    float result = 0.0f;

    @synchronized(self)
    {
        float percentage = [_widget percentage];
        float range = _maxValue - _minValue;
        result = (percentage / 100.0f) * range;
    }

    return ( result );
}

- (void) setPercentage: (float) percentage
{
    [_widget setPercentage: percentage];
}

- (float) percentage
{
    return ( [_widget percentage] );
}

@end
