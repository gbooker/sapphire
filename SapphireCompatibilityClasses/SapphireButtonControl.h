/*
 * SapphireButtonControl.h
 * Sapphire
 *
 * Created by Graham Booker on Jan. 6, 2008.
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

/*!
 * @brief A compatibility class to fix broken class in frontrow
 *
 * Frontrow's BRButtonControl is somewhat broken.  It does not display the little "selection glowing box" around the button, thus not indicating to the user that they should press this button.  This class overrides the frame, setHidden:, and setTitle: functions so that the selection box can be properly displayed.
 */
@interface SapphireButtonControl : BRButtonControl{
}
@end
