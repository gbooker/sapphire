//
//  BRLayerController.h
//  Sapphire
//
//  Created by Graham Booker on 11/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Backrow/BRControllerStack.h>
#import <Backrow/BRPanel.h>

@interface BRController : BRPanel
{
    NSMutableDictionary *_labels;
    BRControllerStack *_stack;
}
@end

@interface BRLayerController : BRController {
}

@end
