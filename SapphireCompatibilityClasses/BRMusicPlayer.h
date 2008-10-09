/*
 * BRMusicPlayer.h
 * Sapphire
 *
 * Created by Eric Steil III on Oct. 8, 2008.
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

#import <BackRow/BRMediaPlayer.h>

/*!
 * @brief Provide a BRMusicPlayer for ATV2.2.
 *
 * ATV2.2 doesn't have a BRMusicPlayer, but it has BRMediaPlayer.  Use that one instead.
 */

@interface BRMusicPlayer : BRMediaPlayer {

}

@end
