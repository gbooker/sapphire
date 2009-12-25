/*
 * Regex_TesterAppDelegate.m
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

#import "Regex_TesterAppDelegate.h"

@interface Regex_TesterAppDelegate ()
- (void)processHaystack;
- (void)regexChanged;
- (void)escapedRegexChanged;
- (void)haystackChanged;
- (void)outputChanged;
- (void)escapedOutputChanged;
@property (readwrite, retain) IBOutlet NSString *errorMessage;
@property (readwrite, retain) IBOutlet NSString *finalOutput;
@end


@implementation Regex_TesterAppDelegate

@synthesize window;
@synthesize regex;
@synthesize escapedRegex;
@synthesize haystack;
@synthesize errorMessage;
@synthesize output;
@synthesize escapedOutput;
@synthesize finalOutput;

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self addObserver:self forKeyPath:@"regex" options:0 context:NULL];
		[self addObserver:self forKeyPath:@"escapedRegex" options:0 context:NULL];
		[self addObserver:self forKeyPath:@"output" options:0 context:NULL];
		[self addObserver:self forKeyPath:@"escapedOutput" options:0 context:NULL];
		[self addObserver:self forKeyPath:@"haystack" options:0 context:NULL];
		self.output = @"";
	}
	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"regex"])
		[self regexChanged];
	else if([keyPath isEqualToString:@"escapedRegex"])
		[self escapedRegexChanged];
	if([keyPath isEqualToString:@"output"])
		[self outputChanged];
	else if([keyPath isEqualToString:@"escapedOutput"])
		[self escapedOutputChanged];
	else if([keyPath isEqualToString:@"haystack"])
		[self haystackChanged];
}

- (void)regexChanged
{
	if(!setting)
	{
		setting = YES;
		if([regex length])
		{
			CFStringRef newEscaped = CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)regex, nil);
			self.escapedRegex = (NSString *)newEscaped;
			CFRelease(newEscaped);
		}
		else
			self.escapedRegex = @"";
		setting = NO;
	}
	
	if(reg)
	{
		pcre_free(reg);
		reg = NULL;
	}
	
	const char *errMsg = NULL;
	int errOffset = 0;
	if([regex length])
	{
		reg = pcre_compile([regex UTF8String], PCRE_DOTALL, &errMsg, &errOffset, NULL);
		if(!reg)
			self.errorMessage = [NSString stringWithFormat:@"Error at %d: %s", errOffset, errMsg];
		else
			self.errorMessage = @"";
	}
	if(reg)
		[self processHaystack];
}

- (void)escapedRegexChanged
{
	if(!setting)
	{
		setting = YES;
		if([escapedRegex length])
		{
			CFStringRef newUnescaped = CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)escapedRegex, nil);
			self.regex = (NSString *)newUnescaped;
			CFRelease(newUnescaped);
		}
		else
			self.regex = @"";
		setting = NO;
	}
}

- (void)outputChanged
{
	if(!setting)
	{
		setting = YES;
		if([output length])
		{
			CFStringRef newEscaped = CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)output, nil);
			self.escapedOutput = (NSString *)newEscaped;
			CFRelease(newEscaped);
		}
		else
			self.escapedOutput = @"";
		setting = NO;
	}
	
	if(reg)
		[self processHaystack];
}

- (void)escapedOutputChanged
{
	if(!setting)
	{
		setting = YES;
		if([escapedOutput length])
		{
			CFStringRef newUnescaped = CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)escapedOutput, nil);
			self.output = (NSString *)newUnescaped;
			CFRelease(newUnescaped);
		}
		else
			self.output = @"";
		setting = NO;
	}
}

- (void)haystackChanged
{
	if(!setting)
		[self processHaystack];
}

NSString *storedMatches[10] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};

- (void)setStoredMatch:(int)index toString:(NSString *)str
{
	[storedMatches[index] release];
	storedMatches[index] = [str retain];
}

- (void)clearStorchMatches
{
	for(int i=0; i<10; i++)
	{
		[storedMatches[i] release];
		storedMatches[i] = nil;
	}
}

- (NSString *)replacementStrForInputStr:(const char *)input matches:(int *)matches count:(int)matchCount
{
	NSMutableString *mutStr = [output mutableCopy];
	
	NSRange range = NSMakeRange(0, [mutStr length]);
	while((range = [mutStr rangeOfString:@"\\" options:0 range:range]).location != NSNotFound)
	{
		BOOL storedMatch = ([mutStr characterAtIndex:range.location + 1] == '$');
		int index = [[mutStr substringFromIndex:range.location + 1 + storedMatch] intValue];
		NSString *replacement;
		if(index > 0 && index < matchCount)
		{
			range.length++;
		}
		range.length += storedMatch;
		int start = matches[index<<1];
		int end = matches[(index<<1) + 1];
		if(range.length > 1 && start != -1)
		{
			replacement = [[[NSString alloc] initWithBytes:input+start length:end-start encoding:NSUTF8StringEncoding] autorelease];
			if(storedMatch)
				[self setStoredMatch:index toString:replacement];
		}
		else if(range.length > 1 && storedMatch)
			replacement = storedMatches[index];
		else
			replacement = @"";
		[mutStr replaceCharactersInRange:range withString:replacement];
		range.location += [replacement length];
		range.length = [mutStr length] - range.location;
	}
	
	NSString *ret = [NSString stringWithString:mutStr];
	[mutStr release];
	return ret;
}

- (void)processHaystack
{
	int matchCount = 0;
	int match[30];
	const char *inputStr = [[haystack string] UTF8String];
	int inputLength = 0;
	if(inputStr)
		inputLength = strlen(inputStr);
	setting = YES;
	NSTextStorage *txtStorage = [haystackView textStorage];
	[txtStorage removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [haystack length])];
	[txtStorage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [haystack length])];
	int offset = 0;
	NSString *result = @"";
	while((matchCount = pcre_exec(reg, NULL, inputStr, inputLength, offset, 0, match, 30)) >= 0)
	{
		int start = match[0];
		int end = match[1];
		[txtStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithDeviceRed:0.75 green:0.75 blue:1 alpha:1] range:NSMakeRange(start, end-start)];
		int i;
		for(i=1; i<matchCount; i++)
		{
			start = match[i<<1];
			end = match[(i<<1) + 1];
			NSString *matchStr = [[NSString alloc] initWithBytes:inputStr+start length:end-start encoding:NSUTF8StringEncoding];
			[txtStorage addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1] range:NSMakeRange(start, end-start)];
			[matchStr release];
		}
		NSString *replacementStr = [self replacementStrForInputStr:inputStr matches:match count:matchCount];
		result = [result stringByAppendingFormat:@"\n%@", replacementStr];
		offset = match[1];
	}
	self.finalOutput = result;
	setting = NO;
}

@end
