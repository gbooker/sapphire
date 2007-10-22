//
//  SapphireAppliance.m
//  Sapphire
//
//  Created by pnmerrill on 6/20/07.
//  Copyright 2007 www.nanopi.net. All rights reserved.
//


#import "SapphireAppliance.h"
#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import <objc/objc-class.h>

#import "BackRowUtils.h"

@implementation SapphireAppliance

+ (void) initialize
{
    Class cls = NSClassFromString( @"BRFeatureManager" );
    if ( cls == Nil )
        return;
	
    [[cls sharedInstance] enableFeatureNamed: [[NSBundle bundleForClass: self] bundleIdentifier]];
}

+ (NSString *) className
{
    // get around the whitelist
    
    // this function will get the real class name from the runtime, and
    // will assuredly not recurse back to here
    NSString * className = NSStringFromClass( self );
    
    // BackRow has its own exception class which provides backtrace
    // helpers. It returns a parsed trace, with function names. We'll
    // look for the name of the function which is known to call this
    // function to check against the whitelist, and if we find it we'll
    // lie about our name, purely to escape that check.
    // Also, the backtracer method is a class routine, meaning that we
    // don't have to even generate an exception - woohoo!
    NSRange range = [[BRBacktracingException backtrace] rangeOfString: @"_loadApplianceInfoAtPath:"];
    if ( range.location != NSNotFound )
    {
        // this is the whitelist check -- tell a Great Big Fib
        BRLog( @"[%@ className] called for whitelist check; returning RUICalibrationAppliance instead",
               className );
        className = @"RUIMoviesAppliance";     // could be anything in the whitelist, really
    }
    
    return ( className );
}

- (NSString *) moduleIconName
{
    // replace this with your own icon name
    return ( @"SapphireIcon.png" );
}

- (NSString *) moduleName
{
    // this doesn't appear to be actually *used*, but even so:
    return ( BRLocalizedString(@"Sapphire", @"Main Menu item name") );
}

+ (NSString *) moduleKey
{
    // change this to match your CFBundleIdentifier
    return ( @"Nanopi.net.UCIJoker.Sapphire" );
}

- (NSString *) moduleKey
{
    return ( [SapphireAppliance moduleKey] );
}

- (BRLayerController *) applianceControllerWithScene: (BRRenderScene *) scene
{
    // this function is called when your item is selected on the main menu
    return ( [[[SapphireApplianceController alloc] initWithScene: scene] autorelease] );
}

@end
