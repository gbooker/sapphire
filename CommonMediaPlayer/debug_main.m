/*
 * debug_main.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 10 2010
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

#import "CMPDVDWindowCreationAction.h"

@interface something : NSObject
{
	float elapsed;
}
@end

@implementation something

- (int)titleElapsedTime
{
	elapsed += 59;
	return elapsed-59;
}

- (int)titleDurationTime
{
	return (2*60+4)*60+45;
}

- (void)randomDirection:(NSTimer *)timer
{
	CMPDVDBlurredMenu *menu = (CMPDVDBlurredMenu *)[timer userInfo];
	if(rand()&1)
		[menu previousItem];
	else
		[menu nextItem];
}

@end



int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	{
		NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[0] length:strlen(argv[0])];
		
		path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"CommonMediaPlayer.framework"];
		
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		[bundle load];		
	}

	NSApplicationLoad();
	
#if 1
	CMPDVDPlayerPlayHead *playhead = [[CMPDVDPlayerPlayHead alloc] initWithContentRect:NSMakeRect(0, 0, 1440, 900) overWindow:0];
	
	[playhead setPlayer:[[something alloc] init]];
	[playhead makeKeyAndOrderFront:nil];
#endif
	
#if 0
	NSArray *items = [NSArray arrayWithObjects:@"Resume Playback", @"Start From Beginning", @"Main Menu", nil];
	CMPDVDBlurredMenu *menu = [[CMPDVDBlurredMenu alloc] initWithItems:items contentRect:NSMakeRect(0, 0, 1440, 900) overWindow:0];
	[menu makeKeyAndOrderFront:nil];
	
	[NSTimer scheduledTimerWithTimeInterval:.2 target:[[something alloc] init] selector:@selector(randomDirection:) userInfo:menu repeats:YES];
#endif
		
	NSRunLoop *currentRL = [NSRunLoop currentRunLoop];
	while([currentRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
		;
	
	[pool drain];
}