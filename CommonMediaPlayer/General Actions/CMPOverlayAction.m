/*
 * CMPOverlayAction.m
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Jun. 22 2010
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

#import "CMPOverlayAction.h"
#import "CoreGraphicsServices.h"
#import "CMPATVVersion.h"

#define ANIMATE_TIME_INTERVAL 0.02

@implementation CMPOverlayWindow

- (id)initWithContentRect:(NSRect)contentRect overWindow:(int)windowID
{
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	if(!self)
		return self;
	
	screenRect = contentRect;
	overWindowID = windowID;
	[self setReleasedWhenClosed:NO];
	
	[self setBackgroundColor:[NSColor blackColor]];
	[[self contentView] setNeedsDisplay:YES];
	
	return self;
}

- (void) dealloc
{
	[opacityChangeTimer invalidate];
	[opacityChangeStartTime release];
	[super dealloc];
}

- (void)display
{
	CGSSetWindowLevel(_CGSDefaultConnection(), [self windowNumber], CGShieldingWindowLevel()+1);
	CGSOrderWindow(_CGSDefaultConnection(), [self windowNumber], kCGSOrderAbove, overWindowID);
	[super display];
}

- (void)closeWithFadeTime:(NSNumber *)aFadeTimeNumber
{
	float aFadeTime = [aFadeTimeNumber floatValue];
	//Alpha is horrible on the ATV since it displays grey, but this one step fade forces everything to draw in the background before it is displayed.
	if(![CMPATVVersion usingLeopard])
		aFadeTime = ANIMATE_TIME_INTERVAL / 2;
	if(aFadeTime == 0)
	{
		[self close];
		return;
	}
	initialOpacity = [self alphaValue];
	finalOpacity = 0;
	fadeTime = aFadeTime;
	[opacityChangeStartTime release];
	opacityChangeStartTime = [[NSDate date] retain];
	[opacityChangeTimer invalidate];
	opacityChangeTimer = [NSTimer scheduledTimerWithTimeInterval:ANIMATE_TIME_INTERVAL target:self selector:@selector(opacityTimerFire) userInfo:nil repeats:YES];
}

- (void)displayWithFadeTime:(float)aFadeTime
{
	if(finalOpacity == 1)
		//Already displayed
		return;
	//Same as above
	if(![CMPATVVersion usingLeopard])
		aFadeTime = ANIMATE_TIME_INTERVAL / 2;
	if(aFadeTime)
		[self setAlphaValue:0];
	[self display];
	if(aFadeTime)
	{
		initialOpacity = 0;
		finalOpacity = 1;
		fadeTime = aFadeTime;
		opacityChangeStartTime = [[NSDate date] retain];
		opacityChangeTimer = [NSTimer scheduledTimerWithTimeInterval:ANIMATE_TIME_INTERVAL target:self selector:@selector(opacityTimerFire) userInfo:nil repeats:YES];		
	}
}

- (void)opacityTimerFire
{
	double interval = -[opacityChangeStartTime timeIntervalSinceNow];
	float currentOpacity;
	if(interval > fadeTime)
	{
		[[self retain] autorelease];	//Prevent us from being released with the invalidate
		currentOpacity = finalOpacity;
		[opacityChangeTimer invalidate];
		opacityChangeTimer = nil;
		if(finalOpacity == 0)
		{
			[self close];
			return;
		}
	}
	else
		currentOpacity = initialOpacity + (finalOpacity - initialOpacity) * interval / fadeTime;
	[self setAlphaValue:currentOpacity];
}

@end

@implementation CMPTextView

- (id)initWithContentRect:(NSRect)contentRect position:(CMPOverlayPosition)aPosition overWindow:(int)windowID
{
	self = [super initWithContentRect:contentRect overWindow:windowID];
	if(!self)
		return nil;
	
	position = aPosition;
	textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
	[[self contentView] addSubview:textField];
	[textField setStringValue:@""];
	[textField setTextColor:[NSColor colorWithDeviceHue:227.0f/360.0f saturation:.60f brightness:1 alpha:1]];
	[textField setBackgroundColor:[NSColor blackColor]];
	NSFont *font = [textField font];
	NSFont *newFont = [NSFont fontWithName:[font fontName] size:contentRect.size.height / 15];
	[textField setFont:newFont];
	[textField setBezeled:NO];
	[textField setBordered:NO];
	
	return self;
}

- (void)dealloc
{
	[textField release];
	[super dealloc];
}

- (void)setText:(NSString *)text
{
	[textField setStringValue:text];
	[textField sizeToFit];
	NSRect frameRect;
	frameRect.size = [textField frame].size;
	//NSLog(@"Size is %fx%f", frameRect.size.width, frameRect.size.height);
	float distanceFromEdge = screenRect.size.height / 15;
	if(position == CMPOverlayUpperLeft || position == CMPOverlayUpperRight)
		frameRect.origin.y = screenRect.size.height - frameRect.size.height - distanceFromEdge;
	else
		frameRect.origin.y = distanceFromEdge;
	if(position == CMPOverlayUpperRight || position == CMPOverlayLowerRight)
		frameRect.origin.x = screenRect.size.width - frameRect.size.width - distanceFromEdge;
	else
		frameRect.origin.x = distanceFromEdge;
	[self setFrame:frameRect display:YES];	
}

@end


@interface CMPPlayerPlayHeadView : NSView
{
	float			playHeadLocation;
}
- (void)setPlayHeadLocation:(float)playHeadLocation;

@end

@implementation CMPPlayerPlayHeadView

- (void)drawRect:(NSRect)rect
{
	NSRect myFrame = [self frame];
	float height = myFrame.size.height;
	float width = myFrame.size.width;
	[[NSColor blackColor] set];
	NSRectFill(rect);
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(height/2, height)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(height/2, height/2) radius:height/2 startAngle:90 endAngle:270];
	[path lineToPoint:NSMakePoint(width-height/2, 0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(width-height/2, height/2) radius:height/2 startAngle:270 endAngle:90];
	[path closePath];
	[[NSColor colorWithDeviceHue:227.0f/360.0f saturation:.60f brightness:1 alpha:1] set];
	[path fill];
	
	path = [NSBezierPath bezierPath];
	float position = playHeadLocation * (width - height) + height/2;
	float border = height / 20;
	[path moveToPoint:NSMakePoint(position, border)];
	[path lineToPoint:NSMakePoint(position-height/2+border, height/2)];
	[path lineToPoint:NSMakePoint(position, height-border)];
	[path lineToPoint:NSMakePoint(position+height/2-border, height/2)];
	[path closePath];
	[[NSColor blackColor] set];
	[path fill];
}

- (void)setPlayHeadLocation:(float)aPlayHeadLocation
{
	playHeadLocation = aPlayHeadLocation;
	[self setNeedsDisplay:YES];
}

@end


@implementation CMPPlayerPlayHead

- (id)initWithContentRect:(NSRect)contentRect overWindow:(int)windowID
{
	self = [super initWithContentRect:contentRect overWindow:windowID];
	if(!self)
		return self;
	
	float myWidth = contentRect.size.width * 27 / 32;
	float textHeight = contentRect.size.height * 3 / 72;
	float textWidth = textHeight * 3;
	float textBuffer = textHeight / 2;
	float textSize = contentRect.size.height / 33;
	elapsedField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, (textSize-textHeight)/7, textWidth, textHeight)];
	[[self contentView] addSubview:elapsedField];
	[elapsedField setStringValue:@""];
	[elapsedField setTextColor:[NSColor whiteColor]];
	[elapsedField setBackgroundColor:[NSColor blackColor]];
	NSFont *font = [elapsedField font];
	NSFont *newFont = [NSFont fontWithName:[font fontName] size:textSize];
	[elapsedField setFont:newFont];
	[elapsedField setBezeled:NO];
	[elapsedField setBordered:NO];
	[elapsedField setSelectable:NO];
	[elapsedField setAlignment:NSRightTextAlignment];
	
	durationField = [[NSTextField alloc] initWithFrame:NSMakeRect(myWidth-textWidth, (textSize-textHeight)/7, textWidth, textHeight)];
	[[self contentView] addSubview:durationField];
	[durationField setStringValue:@""];
	[durationField setTextColor:[NSColor whiteColor]];
	[durationField setBackgroundColor:[NSColor blackColor]];
	[durationField setFont:newFont];
	[durationField setBezeled:NO];
	[durationField setBordered:NO];
	[durationField setSelectable:NO];
	
	playView = [[CMPPlayerPlayHeadView alloc] initWithFrame:NSMakeRect(textWidth + textBuffer, textHeight / 5, myWidth-textWidth*2-textBuffer*2, textHeight * 3 /5)];
	[[self contentView] addSubview:playView];
	[self setFrame:NSMakeRect(contentRect.size.width * 5 / 64, textHeight*2, myWidth, textHeight) display:NO];
	
	return self;
}

- (void) dealloc
{
	[durationField release];
	[playView release];
	[super dealloc];
}

static NSString *timeStringForTime(int time)
{
	int seconds = time % 60;
	time /= 60;
	int minutes = time % 60;
	time /= 60;
	int hours = time;
	
	if(hours == 0)
		return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
	
	return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
}

- (void)updateDisplayWithElapsed:(int)elapsedTime duration:(int)durationTime
{
	[elapsedField setStringValue:timeStringForTime(elapsedTime)];
	[durationField setStringValue:timeStringForTime(durationTime)];
	[playView setPlayHeadLocation:((float)elapsedTime)/((float)durationTime)];
}

@end

@interface CMPSelectionView : NSView
{
	NSTimer			*moveTimer;
	float			initialY, finalY;
	NSDate			*startTime;
}
@end

@implementation CMPSelectionView

#define CMPSelectionViewMoveTime 0.2

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if(!self)
		return self;
	
	initialY = finalY = frame.origin.y;
	
	return self;
}

- (void)dealloc
{
	[moveTimer invalidate];
	[startTime release];
	[super dealloc];
}

static void Interpolate (void* info, float const* inData, float* outData)
{
	float value = sin(M_PI_2 * inData[0])/2;
	outData[0] = value;
	outData[1] = value;
	outData[2] = value;
	outData[3] = 1.0;
}

- (void)drawRect:(NSRect)rect
{
	NSRect frame = [self frame];
	NSRect drawPath = frame;
	drawPath.origin.x = frame.size.height/8;
	drawPath.origin.y = frame.size.height/8;
	drawPath.size.width -= frame.size.height/4;
	drawPath.size.height -= frame.size.height/4;
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:drawPath];
	
	NSShadow *theShadow = [[NSShadow alloc] init];
	[theShadow setShadowOffset:NSMakeSize(0, 0)];
	[theShadow setShadowBlurRadius:frame.size.height/8];
	[theShadow setShadowColor:[NSColor blueColor]];
	[NSGraphicsContext saveGraphicsState];
	[theShadow set];
	[[NSColor blueColor] set];
	[path fill];
	
	[NSGraphicsContext restoreGraphicsState];
	[theShadow release];

	[[NSColor blackColor] set];
	NSRectFill(drawPath);
	
	//Gradient
	struct CGFunctionCallbacks callbacks = { 0, Interpolate, NULL };
	
	CGFunctionRef function = CGFunctionCreate(NULL, 1, NULL, 4, NULL, &callbacks);
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
	
	CGPoint start = CGPointMake(drawPath.origin.x, drawPath.origin.y + drawPath.size.height);
	CGPoint end = CGPointMake(drawPath.origin.x, drawPath.origin.y + drawPath.size.height/2);
	CGShadingRef shading = CGShadingCreateAxial(cspace, start, end, function, false, false);
	
	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	CGContextClipToRect(context, CGRectMake(drawPath.origin.x, drawPath.origin.y, drawPath.size.width, drawPath.size.height));
	CGContextDrawShading(context, shading);
	CGContextRestoreGState(context);
	
	CGShadingRelease(shading);
	CGColorSpaceRelease(cspace);
	CGFunctionRelease(function);
	[[NSColor blackColor] set];
	[path stroke];
}

- (void)moveTimerFire
{
	double interval = -[startTime timeIntervalSinceNow];
	float currentY;
	if(interval > CMPSelectionViewMoveTime)
	{
		currentY = finalY;
		[moveTimer invalidate];
		moveTimer = nil;
	}
	else
		currentY = initialY + (finalY - initialY) * interval / CMPSelectionViewMoveTime;
	NSRect frame = [self frame];
	NSRect newFrame = frame;
	newFrame.origin.y = currentY;
	[self setFrame:newFrame];
	[[self superview] setNeedsDisplayInRect:frame];
	[self setNeedsDisplay:YES];
}

- (void)animateMoveToYDelta:(float)newY
{
	[moveTimer invalidate];
	finalY += newY;
	initialY = [self frame].origin.y;
	[startTime release];
	startTime = [[NSDate date] retain];
	moveTimer = [NSTimer scheduledTimerWithTimeInterval:ANIMATE_TIME_INTERVAL target:self selector:@selector(moveTimerFire) userInfo:nil repeats:YES];
}

@end



@implementation CMPBlurredMenu

- (id)initWithItems:(NSArray*)anItems contentRect:(NSRect)contentRect overWindow:(int)windowID
{
	self = [super initWithContentRect:contentRect overWindow:windowID];
	if(!self)
		return self;
	
	imageView = [[NSImageView alloc] initWithFrame:contentRect];
	[[self contentView] addSubview:imageView];
	
	NSMutableArray *items = [[NSMutableArray alloc] init];
	
	int itemCount = [anItems count];
	itemHeight = contentRect.size.height / 12;
	int itemWidth = itemHeight * 10;
	int bottom = (contentRect.size.height - itemHeight * itemCount) / 2;
	int left = (contentRect.size.width - itemWidth) / 2;
	
	float inset = contentRect.size.height * 5 / 144;
	float borderSize = contentRect.size.height / 72;
	selectionView = [[CMPSelectionView alloc] initWithFrame:NSMakeRect(left, bottom + itemHeight * (itemCount-1) - borderSize, itemWidth, itemHeight+borderSize*2)];
	[[self contentView] addSubview:selectionView];
	
	NSFont *newFont = nil;
	for(int i=0; i<itemCount; i++)
	{
		NSTextField *menuItem = [[NSTextField alloc] initWithFrame:NSMakeRect(left+inset, bottom+itemHeight*(itemCount-1-i), itemWidth-inset, itemHeight)];
		[menuItem setStringValue:[anItems objectAtIndex:i]];
		[[self contentView] addSubview:menuItem];
		[menuItem setTextColor:[NSColor whiteColor]];
		[menuItem setDrawsBackground:NO];
		[menuItem setBezeled:NO];
		[menuItem setBordered:NO];
		[menuItem setSelectable:NO];
		if(newFont == nil)
		{
			NSFont *font = [menuItem font];
			newFont = [NSFont fontWithName:[font fontName] size:contentRect.size.height / 20];
		}
		[menuItem setFont:newFont];
		
		[menuItem sizeToFit];
		NSRect frame = [menuItem frame];
		frame.origin.y += (itemHeight - frame.size.height) / 2;
		[menuItem setFrame:frame];
		
		[items addObject:menuItem];
		[menuItem release];
	}
	
	menuItems = [items copy];
	[items release];
	
	[self setFrame:contentRect display:YES];
	
	return self;
}

- (void) dealloc
{
	[menuItems release];
	[selectionView release];
	[imageView release];
	[super dealloc];
}


- (void)display
{
	if(!overWindowID)
		return;
	CGSConnectionID cid = _CGSDefaultConnection();
	CGRect bounds;
	CGSGetWindowBounds(cid, overWindowID, &bounds);
	//NSLog(@"Bounds is %fx%f - %fx%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	//	CGLGetCurrentContext()
	//NSLog(@"bounds is %fx%f-%fx%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	CGRect imageBounds = bounds;
	if(bounds.size.height > 480 || bounds.size.width > 720)
	{
		float py = bounds.size.height / 480;
		float px = bounds.size.width / 720;
		float divisor = MIN(py, px);
		imageBounds.size.width = floorf(imageBounds.size.width / divisor);
		imageBounds.size.height = floorf(imageBounds.size.height / divisor);
	}
	int bitmapSize = imageBounds.size.width *imageBounds.size.height * 4;
	char *bitmap = malloc(bitmapSize);
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef context = CGBitmapContextCreate(bitmap, imageBounds.size.width, imageBounds.size.height, 8, imageBounds.size.width * 4, colorspace, kCGImageAlphaNoneSkipFirst);
    // Copy the contents of the window to the graphic context
	CGContextCopyWindowCaptureContentsToRect(context, imageBounds, cid, overWindowID, 0);	
	
	NSData *bitmapData = [NSData dataWithBytesNoCopy:bitmap length:bitmapSize];
	CIImage *myCIImage = [[CIImage alloc] initWithBitmapData:bitmapData bytesPerRow:imageBounds.size.width * 4 size:imageBounds.size format:kCIFormatARGB8 colorSpace:colorspace];
	CIFilter *gaussianBlur = [CIFilter filterWithName:@"CIGaussianBlur"];
	[gaussianBlur setDefaults];
	[gaussianBlur setValue:myCIImage forKey:@"inputImage"];
	[myCIImage release];
	
	CIImage *result = [gaussianBlur valueForKey:@"outputImage"];
	CIFilter *crop = [CIFilter filterWithName:@"CICrop"];
	[crop setDefaults];
	[crop setValue:result forKey:@"inputImage"];
	[crop setValue:[CIVector vectorWithX:0 Y:0 Z:imageBounds.size.width W:imageBounds.size.height] forKey:@"inputRectangle"];
	result = [crop valueForKey:@"outputImage"];
	NSImage *resultAsNSImage;
	if([result isKindOfClass:[CIImage class]])
	{
		resultAsNSImage = [[NSImage alloc] initWithSize:NSMakeSize([result extent].size.width, [result extent].size.height)];
		[resultAsNSImage addRepresentation:[NSCIImageRep imageRepWithCIImage:result]];
		[resultAsNSImage autorelease];
	}
	else
		resultAsNSImage = (NSImage *)result;
	
	[resultAsNSImage setScalesWhenResized:YES];
	[resultAsNSImage setSize:NSMakeSize(bounds.size.width, bounds.size.height)];
	[imageView setImage:resultAsNSImage];
	[imageView setImageScaling:NSScaleProportionally];
	
	CGContextRelease(context);
	CGColorSpaceRelease(colorspace);
	
	[super display];
}

- (BOOL)previousItem
{
	if(selectedItem == 0)
		return NO;
	[selectionView animateMoveToYDelta:itemHeight];
	selectedItem--;
	return YES;
}

- (BOOL)nextItem
{
	if(selectedItem == [menuItems count]-1)
		return NO;
	[selectionView animateMoveToYDelta:-itemHeight];
	selectedItem++;
	return YES;
}

- (int)selectedItem
{
	return selectedItem;
}

@end

NSString *CMPOverlayActionWindowNumberKey = @"windowNumber";
NSString *CMPOverlayActionWindowRectKey = @"windowNumber";

@interface BRDisplayManager (compat)
+ (BRDisplayManager *)sharedInstance;
@end

@implementation CMPOverlayAction

- (id)initWithController:(id <CMPPlayerController>)controller andSettings:(NSDictionary *)settings
{
	NSNumber *windowNum = [settings objectForKey:CMPOverlayActionWindowNumberKey];
	if(windowNum == nil)
		return [self autorelease];
	
	self = [super init];
	if(!self)
		return self;
	
	windowNumber = [windowNum intValue];
	NSValue *windowRectValue = [settings objectForKey:CMPOverlayActionWindowRectKey];
	if(windowRectValue != nil)
		windowRect = [windowRectValue rectValue];
	else {
		CGDirectDisplayID display = [(BRDisplayManager *)[BRDisplayManager sharedInstance] display];
		CGRect frame = CGDisplayBounds(display);
		frame.size.width = CGDisplayPixelsWide(display);
		frame.size.height = CGDisplayPixelsHigh(display);
		
		if(frame.size.width < 0.0f)
			frame.size.width = ABS(frame.size.width);
		if(frame.size.height < 0.0f)
			frame.size.height = ABS(frame.size.height);
		
		windowRect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);		
	}
	overlays = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) dealloc
{
	[overlays release];
	[super dealloc];
}

- (BOOL)openWithError:(NSError **)error
{
	return YES;
}

- (CMPOverlayWindow *)addBlackShieldWindow
{
	CMPOverlayWindow *ret = [[CMPOverlayWindow alloc] initWithContentRect:windowRect overWindow:windowNumber];
	
	[overlays addObject:ret];
	[ret release];
	
	return ret;
}

- (CMPTextView *)addTextOverlayInPosition:(CMPOverlayPosition)position
{
	CMPTextView *ret = [[CMPTextView alloc] initWithContentRect:windowRect position:position overWindow:windowNumber];
	
	[overlays addObject:ret];
	[ret release];
	
	return ret;
}

- (CMPPlayerPlayHead *)addPlayheadOverlay
{
	CMPPlayerPlayHead *ret = [[CMPPlayerPlayHead alloc] initWithContentRect:windowRect overWindow:windowNumber];
	
	[overlays addObject:ret];
	[ret release];
	
	return ret;
}

- (CMPBlurredMenu *)addBlurredMenuOverlayWithItems:(NSArray *)items
{
	CMPBlurredMenu *ret = [[CMPBlurredMenu alloc] initWithItems:items contentRect:windowRect overWindow:windowNumber];
	
	[overlays addObject:ret];
	[ret release];
	
	return ret;
}

- (void)closeOverlay:(CMPOverlayWindow *)overlay
{
	[self closeOverlay:overlay withFade:[NSNumber numberWithFloat:0]];
}

- (void)closeOverlay:(CMPOverlayWindow *)overlay withFade:(NSNumber *)fadeTimeNumber
{
	[overlay closeWithFadeTime:fadeTimeNumber];
	[overlays removeObject:overlay];
}

- (void)closeAllOverlays
{
	[overlays makeObjectsPerformSelector:@selector(close)];
	[overlays removeAllObjects];
}

- (void)closeAllOverlaysWithFadeTime:(float)fadeTime
{
	if(fadeTime > 0.0f)
		[overlays makeObjectsPerformSelector:@selector(closeWithFadeTime:) withObject:[NSNumber numberWithFloat:fadeTime]];
	else
		[overlays makeObjectsPerformSelector:@selector(close)];
	[overlays removeAllObjects];
}

- (BOOL)closeWithError:(NSError **)error
{
	[self closeAllOverlays];
	return YES;
}
@end
