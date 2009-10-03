/*
 * SapphireAudioNowPlayingController.h
 * Sapphire
 *
 * Created by Graham Booker on Aug. 22, 2009.
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

/*
 * This class replaces the BRMusicNowPlayingController for leopard and Take 2 since the classes there are broken
 */

@interface BRMusicNowPlayingController (bypassAccess)
- (void)setPlayer:(BRMusicPlayer *)player;
- (BRMusicPlayer *)player;
@end

@class BRMusicNowPlayingControl, BRMediaPlayerEventHandler;

@interface SapphireAudioNowPlayingController : BRLayerController {
	int		padding[16];
	
	BRMusicPlayer				*player;
	BRMusicNowPlayingControl	*nowPlayingControl;
	BRMediaPlayerEventHandler	*eventHandler;
}

- (id)initWithPlayer:(BRMusicPlayer *)player;

- (void)setPlayer:(BRMusicPlayer *)player;
- (BRMusicPlayer *)player;

@end
