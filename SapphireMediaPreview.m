//
//  SapphireMediaPreview.m
//  Sapphire
//
//  Created by Graham Booker on 6/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SapphireMediaPreview.h"


@implementation SapphireMediaPreview

- (id) initWithScene: (BRRenderScene *) scene
{
	self = [super initWithScene:scene];
	if(!self)
		return nil;
	
	textLayer = [[BRTextLayer alloc] initWithScene:scene];
	imageLayer = [[BRImageLayer alloc] initWithScene:scene];
	
	[self addSublayer:textLayer];
	[self addSublayer:imageLayer];
	
	return self;
}

- (void)dealloc
{
	[textLayer release];
	[imageLayer release];
	[super dealloc];
}

- (void)setText:(NSAttributedString *)text
{
	[textLayer setAttributedString:text];
	[self setFrame:[self frame]];
}


- (void)setFileProgress:(NSAttributedString *)fileProgress
{
	[textLayer setAttributedString:fileProgress];
	[self setFrame:[self frame]];
}

- (void)setImage:(CGImageRef)image
{
	[imageLayer setImage:image];
}

- (void)setFrame:(NSRect)frame
{
	frame.origin.x += frame.size.width / 12.0f;
	frame.size.width *= 2.0f / 3.0f;
	frame.origin.y += frame.size.height / 24.0f;
	frame.size.height *= 5.0f/6.0f;
	[super setFrame:frame];
	
	[textLayer setMaxSize:frame.size];
	NSSize txtSize = [textLayer renderedSize];
	
	NSRect textRect = frame;
	textRect.size.height = txtSize.height;
	[textLayer setFrame:textRect];
	
	NSRect imageRect = frame;
	long shrink = textRect.size.height + frame.size.height * 0.05f;
	imageRect.origin.y += shrink;
	imageRect.size.height -= shrink;
	
	NSSize scaled = [imageLayer pixelBounds];
	double xscale = imageRect.size.width / scaled.width;
	double yscale = imageRect.size.height / scaled.height;
	if(xscale < yscale)
		yscale = xscale;
	scaled.width *= yscale;
	scaled.height *= yscale;
	imageRect.origin.y += (imageRect.size.height - scaled.height) / 2.0f;
	imageRect.origin.x += (imageRect.size.width - scaled.width) / 2.0f;
	imageRect.size = scaled;
	
	[imageLayer setFrame:imageRect];
}

- (id)layer
{
	return self;
}

- (void)activate
{
}

- (void)willLoseFocus
{
}

- (void)willRegainFocus
{
}

- (void)willDeactivate
{
}

- (void)deactivate
{
}

- (BOOL)fadeLayerIn
{
	return NO;
}

@end
