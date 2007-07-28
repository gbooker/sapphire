//
//  SapphireAudioMedia.h
//  Sapphire
//
//  Created by Graham Booker on 7/28/07.
//  Copyright 2007 __www.nanopi.net__. All rights reserved.
//

#import "SapphireMedia.h"

@interface SapphireAudioMedia : SapphireMedia {
	QTMovie		*movie;
}
- (void)setMovie:(QTMovie *)newMovie;

@end
