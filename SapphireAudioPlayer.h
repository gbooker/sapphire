//
//  SapphireAudioPlayer.h
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

@class QTMovie;

@interface SapphireAudioPlayer : BRMusicPlayer {
	QTMovie		*movie;
	int			state;
	NSTimer		*updateTimer;
}

@end
