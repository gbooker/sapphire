/*
 * CMPOverlayAction.h
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

#import "CMPActionController.h"

@class CMPScreenReleaseAction, CMPPlayerPlayHeadView, CMPSelectionView;

typedef enum {
	CMPOverlayUpperLeft,
	CMPOverlayUpperRight,
	CMPOverlayLowerLeft,
	CMPOverlayLowerRight,
} CMPOverlayPosition;

@interface CMPOverlayWindow : NSWindow
{
	NSRect					screenRect;
	int						overWindowID;
	float					initialOpacity, finalOpacity, fadeTime;
	NSTimer					*opacityChangeTimer;
	NSDate					*opacityChangeStartTime;
}

- (void)display;
- (void)displayWithFadeTime:(float)fadeTime;

@end

@interface CMPTextView : CMPOverlayWindow
{
	CMPOverlayPosition		position;
	NSTextField				*textField;
}

- (void)setText:(NSString *)text;

@end

@interface CMPPlayerPlayHead : CMPOverlayWindow {
	NSTextField							*elapsedField;
	NSTextField							*durationField;
	CMPPlayerPlayHeadView				*playView;
}
- (void)updateDisplayWithElapsed:(int)elapsedTime duration:(int)durationTime;

@end

@interface CMPBlurredMenu : CMPOverlayWindow
{
	NSArray					*menuItems;
	CMPSelectionView		*selectionView;
	NSImageView				*imageView;
	int						selectedItem;
	int						itemHeight;
}
- (BOOL)previousItem;
- (BOOL)nextItem;
- (int)selectedItem;
@end

extern NSString *CMPOverlayActionWindowNumberKey;
extern NSString *CMPOverlayActionWindowRectKey;

@interface CMPOverlayAction : NSObject <CMPActionController>{
	NSRect					windowRect;
	int						windowNumber;
	NSMutableArray			*overlays;
}

- (CMPOverlayWindow *)addBlackShieldWindow;
- (CMPTextView *)addTextOverlayInPosition:(CMPOverlayPosition)position;
- (CMPPlayerPlayHead *)addPlayheadOverlay;
- (CMPBlurredMenu *)addBlurredMenuOverlayWithItems:(NSArray *)items;
- (void)closeOverlay:(CMPOverlayWindow *)overlay;
- (void)closeOverlay:(CMPOverlayWindow *)overlay withFade:(NSNumber *)fadeTimeNumber;
- (void)closeAllOverlays;
- (void)closeAllOverlaysWithFadeTime:(float)fadeTime;

@end
