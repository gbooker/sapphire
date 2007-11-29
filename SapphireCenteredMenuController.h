//
//  SapphireCenteredMenuController.h
//  Sapphire
//
//  Created by Graham Booker on 10/29/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//


@protocol SapphireLayoutDelegate <NSObject>
- (NSRect)listRectWithSize:(NSRect)listFrame inMaster:(NSRect)master;
@end

@interface SapphireCenteredMenuController : BRCenteredMenuController <SapphireLayoutDelegate>{
	int		padding[16];
}

@end
