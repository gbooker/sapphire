//
//  SapphireAudioMedia.h
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//

#import "SapphireMedia.h"

@interface SapphireAudioMedia : SapphireMedia {
	QTMovie		*movie;
	CGImageRef	coverArt;
}
- (void)setMovie:(QTMovie *)newMovie;

@end
