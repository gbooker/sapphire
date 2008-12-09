/*
 * SapphireStackControllerCompatFunctions.h
 * Sapphire
 *
 * Created by Graham Booker on Dec. 7, 2007.
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

- (void)doInitialPush
{
}

/*ATV < 2.3*/
- (void)willBePushed
{
	[self doInitialPush];
	[super willBePushed];
}

/*All ATV*/
- (void)wasPushed
{
	if([SapphireFrontRowCompat usingTakeTwoDotThree])
	/*ATV ≥2.3 doesn't call willBe... so we do it here*/
		[self doInitialPush];
	
    [super wasPushed];
}

- (void)doInitialPop
{
}

- (void)wasPopped
{
	if([SapphireFrontRowCompat usingTakeTwoDotThree])
		[self doInitialPop];
	
    [super wasPopped];
}

- (void)doInitialBury
{
}

- (void)willBeBuried
{
	[self doInitialBury];
	[super willBeBuried];
}

- (void)wasBuried
{
	if([SapphireFrontRowCompat usingTakeTwoDotThree])
	{
		[self doInitialBury];
		[super wasBuried];
	}
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
	[self wasBuried];
	[super wasBuriedByPushingController: controller];
}

- (void)doInitialExhume
{
}

- (void)willBeExhumed
{
	[self doInitialExhume];
	[super willBeExhumed];
}

- (void)wasExhumed
{
	if([SapphireFrontRowCompat usingTakeTwoDotThree])
	{
		[self doInitialExhume];
		[super wasExhumed];
	}
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	[super wasExhumedByPoppingController:controller];
	[self wasExhumed];
}