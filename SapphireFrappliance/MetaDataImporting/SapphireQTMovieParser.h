//
//  QTMovieParser.h
//  QT7MiniDemo
//
//  Created by Thomas Cool on 7/19/10.
//  Copyright 2010 tomcool.org. All rights reserved.
//

#import <QTKit/QTKit.h>

extern NSString *TC_QT_TITLE;
extern NSString *TC_QT_LONG_DESC;
extern NSString *TC_QT_DESC;
extern NSString *TC_QT_RELEASE;
extern NSString *TC_QT_COPYRIGHT;
extern NSString *TC_QT_GENRES;
extern NSString *TC_QT_TRACK;
extern NSString *TC_QT_DIRECTORS;
extern NSString *TC_QT_ARTISTS;
extern NSString *TC_QT_TYPE;

extern NSString *TC_QT_TV_SHOW;
extern NSString *TC_QT_TV_SEASON_NB;
extern NSString *TC_QT_TV_EPISODE_NB;
extern NSString *TC_QT_TV_EP_ID;
extern NSString *TC_QT_TV_NETWORK;

@interface SapphireQTMovieParser : NSObject {
    QTMovie					*qtMovie;
    NSData					*imageData;
	NSString				*imageExtension;
    NSMutableDictionary		*info;
}

- (id)initWithFile:(NSString *)file;
- (NSMutableDictionary *)info;
- (NSData *)imageData;
- (NSString *)imageExtension;
@end
