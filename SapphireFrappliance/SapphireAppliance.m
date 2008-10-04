/*
 * SapphireAppliance.m
 * Sapphire
 *
 * Created by pnmerrill on Jun. 20, 2007.
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


#import "SapphireAppliance.h"
#import "SapphireApplianceController.h"
#import <BackRow/BackRow.h>
#import <objc/objc-class.h>
#import <SapphireCompatClasses/SapphireFrontRowCompat.h>

#import <SapphireCompatClasses/BackRowUtils.h>

// BRAppliance protocol
@interface BRApplianceInfo
+(id)infoForApplianceBundle:(id)bundle;
-(id)applianceCategoryDescriptors;
@end

@interface BRApplianceCategory
+(id)categoryWithName:(NSString *)name identifier:(NSString *)identifier preferredOrder:(float)order;
-(void)setIsStoreCategory:(BOOL)isStoreCategory;
-(void)setIsDefaultCategory:(BOOL)isDefaultCategory;
-(void)setShouldDisplayOnStartup:(BOOL)shouldDisplayOnStartup;
@end


@implementation SapphireAppliance

+ (void) initialize
{
	NSString *myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
	NSString *frameworkPath = [myBundlePath stringByAppendingPathComponent:@"Contents/Frameworks"];
	SapphireLoadFramework(frameworkPath);
	Class cls = NSClassFromString( @"BRFeatureManager" );
	if ( cls == Nil )
		return;
	[[cls sharedInstance] enableFeatureNamed: [[NSBundle bundleForClass: self] bundleIdentifier]];
	[[SapphireFrontRowCompat sharedFrontRowPreferences] setBool:YES forKey:@"AllowAllVideoToPlay"];  //Workaround 2.2.
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
	NSString *backtrace = [BRBacktracingException backtrace];
	NSRange range = [backtrace rangeOfString: @"_loadApplianceInfoAtPath:"];
	if ( range.location != NSNotFound )
	{
		// this is the whitelist check -- tell a Great Big Fib
		className = @"RUIMoviesAppliance";     // could be anything in the whitelist, really
	}
	if (range.location == NSNotFound)
	{
		//code from ATVFiles. Thx!
		range = [backtrace rangeOfString: @"(in BackRow)"];
		if(range.location != NSNotFound) {
			NSLog(@"+[%@ className] called for Leopard/ATV2 whitelist check, so I'm lying, m'kay?", className);
			// 10.5/ATV2 (and 1.1, but that's handled above)
			className = @"RUIDVDAppliance";
		}
	}
	return ( className );
}

-(NSString *)applianceKey {
	return @"SapphireAppliance";
}

-(NSString *)applianceName {
	return @"SapphireAppliance";
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

- (id)applianceController
{
	SapphireApplianceController *cont = nil;
	@try {
		cont = [[[SapphireApplianceController alloc] initWithScene: nil] autorelease];
	}
	@catch (NSException * e) {
		[SapphireApplianceController logException:e];
	}
	
	return cont;
}

- (id) applianceControllerWithScene: (id) scene
{
	// this function is called when your item is selected on the main menu
	return ( [[[SapphireApplianceController alloc] initWithScene: scene] autorelease] );
}

/**
 * This implements the BRAppliance protocol from ATV2.
 */
-(id)applianceInfo {
	BRApplianceInfo* p = [BRApplianceInfo infoForApplianceBundle:[NSBundle bundleForClass:[self class]]];
	NSMutableArray *categories = [NSMutableArray array];
	
	NSEnumerator *enumerator = [[p applianceCategoryDescriptors] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		BRApplianceCategory *category = [BRApplianceCategory categoryWithName:[obj valueForKey:@"name"] identifier:[obj valueForKey:@"identifier"] preferredOrder:[[obj valueForKey:@"preferred-order"] floatValue]];
		[categories addObject:category];
	}
	return [BRApplianceInfo infoForApplianceBundle:[NSBundle bundleForClass:[self class]]];
}

-(id)applianceCategories {
	NSMutableArray *categories = [NSMutableArray array];
	
	NSEnumerator *enumerator = [[[self applianceInfo] applianceCategoryDescriptors] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		BRApplianceCategory *category = [BRApplianceCategory categoryWithName:[obj valueForKey:@"name"] identifier:[obj valueForKey:@"identifier"] preferredOrder:[[obj valueForKey:@"preferred-order"] floatValue]];
		[categories addObject:category];
	}
	return categories;
}

-(id)identifierForContentAlias:(id)fp8 {
	return @"Sapphire";
}

-(id)controllerForIdentifier:(id)fp8 {
	return [self applianceController];
}

-(id)initWithSettings:(id)settings {
	return [super init];
}

-(id)version {
	return @"1.0";
}

@end
