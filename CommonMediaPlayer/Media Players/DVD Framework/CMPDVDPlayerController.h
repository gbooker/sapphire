/*
 * CMPDVDPlayerController.h
 * CommonMediaPlayer
 *
 * Created by Graham Booker on Feb. 3 2010
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

#import "CMPPlayerController.h"

@class CMPDVDPlayer, CMPDVDWindowCreationAction, CMPDVDTextView, CMPDVDPlayerPlayHead, CMPDVDBlurredMenu;

typedef enum {
	CMPDVDPlayerControllerOverlayModeNone,
	CMPDVDPlayerControllerOverlayModeStatus,
	CMPDVDPlayerControllerOverlayModeSubAndAudio,
	CMPDVDPlayerControllerOverlayModeChapters,
} CMPDVDPlayerControllerOverlayMode;

@interface CMPDVDPlayerController : BRMenuController <CMPPlayerController> {
	int									padding[16];
	CMPDVDPlayer						*player;
	id <CMPPlayerControllerDelegate>	delegate;
	CMPDVDWindowCreationAction			*windowCreation;
#ifdef PLAY_WITH_OVERLAY
	BOOL								blacked;
#endif
	CMPDVDPlayerControllerOverlayMode	overlayMode;
	NSTimer								*overlayDismiss;
	CMPDVDTextView						*statusOverlay;
	CMPDVDTextView						*subtitlesOverlay;
	CMPDVDTextView						*audioOverlay;
	CMPDVDTextView						*chapterOverlay;
	CMPDVDPlayerPlayHead				*playheadOverlay;
	CMPDVDBlurredMenu					*blurredMenu;
}

- (void)playbackStopped;

@end
