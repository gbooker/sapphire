/*
 * CMPDVDWindowCreationAction.h
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 2 2010
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

@class CMPScreenReleaseAction, CMPDVDPlayer, CMPDVDPlayerPlayHeadView, CMPDVDSelectionView;

typedef enum {
	CMPDVDOverlayUpperLeft,
	CMPDVDOverlayUpperRight,
	CMPDVDOverlayLowerLeft,
	CMPDVDOverlayLowerRight,
} CMPDVDOverlayPosition;

@interface CMPDVDOverlayWindow : NSWindow
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

@interface CMPDVDTextView : CMPDVDOverlayWindow
{
	CMPDVDOverlayPosition	position;
	NSTextField				*textField;
}

- (void)setText:(NSString *)text;

@end

@interface CMPDVDPlayerPlayHead : CMPDVDOverlayWindow {
	NSTextField							*elapsedField;
	NSTextField							*durationField;
	CMPDVDPlayer						*player;
	CMPDVDPlayerPlayHeadView			*playView;
	NSTimer								*updateTimer;
}
- (void)setPlayer:(CMPDVDPlayer *)player;

@end

@interface CMPDVDBlurredMenu : CMPDVDOverlayWindow
{
	NSArray					*menuItems;
	CMPDVDSelectionView		*selectionView;
	NSImageView				*imageView;
	int						selectedItem;
	int						itemHeight;
}
- (BOOL)previousItem;
- (BOOL)nextItem;
- (int)selectedItem;
@end


@interface CMPDVDWindowCreationAction : NSObject <CMPActionController>{
	CMPScreenReleaseAction	*screenRelease;
	NSWindow				*dvdWindow;
	NSMutableArray			*overlays;
}

- (void)setWindowAlpha:(float)alpha;
- (CMPDVDOverlayWindow *)addBlackShieldWindow;
- (CMPDVDTextView *)addTextOverlayInPosition:(CMPDVDOverlayPosition)position;
- (CMPDVDPlayerPlayHead *)addPlayheadOverlay;
- (CMPDVDBlurredMenu *)addBlurredMenuOverlayWithItems:(NSArray *)items;
- (void)closeOverlay:(CMPDVDOverlayWindow *)overlay;
- (void)closeAllOverlays;
- (void)closeAllOverlaysWithFadeTime:(float)fadeTime;

@end
