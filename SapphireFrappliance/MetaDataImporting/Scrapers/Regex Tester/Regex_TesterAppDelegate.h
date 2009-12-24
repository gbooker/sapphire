//
//  Regex_TesterAppDelegate.h
//  Regex Tester
//
//  Created by Graham Booker on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
