/*
 * SLoadInstallProgress.h
 * Software Loader
 *
 * Created by Graham Booker on Dec 29, 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
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

#import "SLoadInstallProgress.h"
#import "SLoadInstallClient.h"
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SLoadInstallProgress

- (id) initWithScene:(BRRenderScene *)scene
{
	self = [super initWithScene:scene];
	if (self == nil)
		return nil;
	
	NSRect myFrame = [SapphireFrontRowCompat frameOfController:self];
	NSRect frame = myFrame;
	
	title = [SapphireFrontRowCompat newHeaderControlWithScene:scene];
	[title setTitle:BRLocalizedString(@"Install Progress", @"Install title")];
	frame.origin.y += frame.size.height * 0.80f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[title setFrame:frame];
	
	information = [SapphireFrontRowCompat newTextControlWithScene:scene];
	statusText = [SapphireFrontRowCompat newTextControlWithScene:scene];
	
	bar = [SapphireFrontRowCompat newProgressBarWidgetWithScene:scene];
	frame = myFrame;
	frame.origin.y += frame.size.height * 5.0f / 16.0f;
	frame.origin.x = frame.size.width / 6.0f;
	frame.size.height /= 16.0f;
	frame.size.width *= 2.0f / 3.0f;
	[bar setFrame:frame];
	
	[self addControl:title];
	[self addControl:information];
	[self addControl:statusText];
	[SapphireFrontRowCompat addSublayer:bar toControl:self];
	
	return self;
}

- (void) dealloc
{
	[title release];
	[information release];
	[statusText release];
	[bar release];
	[super dealloc];
}


- (void)setInformativeText:(NSString *)text
{
	[SapphireFrontRowCompat setText:text withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:information];
	
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	[information setMaximumSize:NSMakeSize(frame.size.width * 2.0f/3.0f, frame.size.height * 0.4f)];
	NSSize renderSize = [information renderedSize];
	
	frame.origin.x = (frame.size.width - renderSize.width) * 0.5f;
	frame.origin.y += (frame.size.height * 0.4f - renderSize.height) + frame.size.height * 0.3f/0.8f;
	frame.size = renderSize;
	[information setFrame:frame];
}

- (void)setStatus:(NSString *)status
{
	[SapphireFrontRowCompat setText:status withAtrributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes] forControl:statusText];
	
	NSRect frame = [SapphireFrontRowCompat frameOfController:self];
	[statusText setMaximumSize:NSMakeSize(frame.size.width * 0.9f, frame.size.height * 0.3f)];
	NSSize renderSize = [statusText renderedSize];
	
	frame.origin.x = frame.size.width * 0.1f;
	frame.origin.y += frame.size.height * 0.09f;
	frame.size = renderSize;
	[statusText setFrame:frame];
}

- (void)updateBar
{
	float percent = stagePercentage;
	if(hasDownload)
	{
		percent /= 2.0f;
		percent += downloadPercentage / 2.0f;
	}
	[bar setPercentage:percent];
	NSLog(@"Setting bar to %f", percent);
}

- (void)setStage:(int)stage of:(int)totalStages withName:(NSString *)name
{
	stagePercentage = (float)stage / (float)totalStages;
	[self setStatus:name];
	[self updateBar];
	NSLog(@"Got stage %d of %d with name %@", stage, totalStages, name);
}

- (void)setDownloadedBytes:(unsigned int)bytes ofTotal:(unsigned int)total
{
	downloadPercentage = (float)bytes / (float)total;
	[self updateBar];
}

- (void)setHasDownload:(BOOL)download
{
	hasDownload = download;
}

- (void)downloadCompleted
{
	downloadPercentage = 1.0f;
	[self updateBar];
}

- (void)instalFailed:(NSString *)error
{
	[self setInformativeText:[NSString stringWithFormat:BRLocalizedString(@"Install Failed With Error:\n%@", @"install failed message with error string"), error]];
	NSLog(@"Got error %@", error);
}

@end
