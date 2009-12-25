/*
 * Regex_TesterAppDelegate.h
 * Regex Tester
 *
 * Created by Graham Booker on Dec. 24 2009.
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

#import <Cocoa/Cocoa.h>
#import "pcre.h"

@interface Regex_TesterAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow			*window;
	NSString			*regex;
	NSString			*escapedRegex;
	NSAttributedString	*haystack;
	NSString			*output;
	NSString			*escapedOutput;
	BOOL				setting;
	pcre				*reg;
	NSString			*errorMessage;
	IBOutlet NSTextView	*haystackView;
	NSString			*finalOutput;
}

@property (assign) IBOutlet NSWindow *window;
@property (readwrite, retain) IBOutlet NSString *regex;
@property (readwrite, retain) IBOutlet NSString *escapedRegex;
@property (readwrite, retain) IBOutlet NSAttributedString *haystack;
@property (readonly, retain) IBOutlet NSString *errorMessage;
@property (readwrite, retain) IBOutlet NSString *output;
@property (readwrite, retain) IBOutlet NSString *escapedOutput;
@property (readonly, retain) IBOutlet NSString *finalOutput;

@end
