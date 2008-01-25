/*
 * SLoadAppliance.m
 * Software Loader
 *
 * Created by Graham Booker on Dec. 22 2007.
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

#import "SLoadAppliance.h"

#import "SLoadApplianceController.h"
#import <BackRow/BackRow.h>
#import <objc/objc-class.h>
#import <Security/Security.h>

#import <SapphireCompatClasses/BackRowUtils.h>
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

@implementation SLoadAppliance

+ (void) initialize
{
    Class cls = NSClassFromString( @"BRFeatureManager" );
    if ( cls == Nil )
        return;
	
    [[cls sharedInstance] enableFeatureNamed: [[NSBundle bundleForClass: self] bundleIdentifier]];
	NSString *myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
	NSString *frameworkPath = [myBundlePath stringByAppendingPathComponent:@"Contents/Frameworks"];
	SapphireLoadFramework(frameworkPath);
}

+ (NSString *) className
{
	static BOOL checked = NO;
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
	NSString *backtrace = [BRBacktracingException backtrace];
    NSRange range = [backtrace rangeOfString: @"_loadApplianceInfoAtPath:"];
	if (range.location == NSNotFound && !checked)
	{
		range = [backtrace rangeOfString: @"(in BackRow)"];
		checked = YES;
	}
    if ( range.location != NSNotFound )
    {
        // this is the whitelist check -- tell a Great Big Fib
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
    return ( @"Nanopi.net.UCIJoker.SoftwareLoader" );
}

- (NSString *) moduleKey
{
    return ( [SLoadAppliance moduleKey] );
}

- (BRLayerController *)myApplianceController
{
	NSString *path = [[NSBundle bundleForClass:[SLoadAppliance class]] pathForResource:@"InstallHelper" ofType:@""];
	NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	if(![[attrs objectForKey:NSFileOwnerAccountName] isEqualToString:@"root"] || !([[attrs objectForKey:NSFilePosixPermissions] intValue] | S_ISUID))
	{
		/* Permissions are incorrect */
		AuthorizationItem authItems[2] = {
			{kAuthorizationEnvironmentUsername, strlen("frontrow"), "frontrow", 0},
			{kAuthorizationEnvironmentPassword, strlen("frontrow"), "frontrow", 0},
		};
		AuthorizationEnvironment environ = {2, authItems};
		AuthorizationItem rightSet[] = {{kAuthorizationRightExecute, 0, NULL, 0}};
		AuthorizationRights rights = {1, rightSet};
		AuthorizationRef auth;
		OSStatus result = AuthorizationCreate(&rights, &environ, kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights, &auth);
		if(result == errAuthorizationSuccess)
		{
			char *command = "chown root:admin \"$HELP\" && chmod 4755 \"$HELP\"";
			setenv("HELP", [path fileSystemRepresentation], 1);
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			unsetenv("HELP");
		}
		if(result != errAuthorizationSuccess)
		{
			/*Need to present the error dialog here telling the user to fix the permissions*/
			return nil;
		}
	}
    return [[[SLoadApplianceController alloc] initWithScene: nil] autorelease];
}

- (BRLayerController *)applianceController
{
    return [self myApplianceController];
}

- (BRLayerController *) applianceControllerWithScene: (BRRenderScene *) scene
{
    return [self myApplianceController];
}

@end
