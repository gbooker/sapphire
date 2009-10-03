/*
 * SapphireLogging.h
 * Sapphire
 *
 * Created by Graham Booker on Nov. 15 2008.
 * Copyright 2008 Sapphire Development Team and/or www.nanopi.net
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

#import "SapphireLogging.h"

@implementation SapphireLogging

+ (void)setLogLevel:(SapphireLogLevel)level forType:(SapphireLogType)type
{
	SapphireSetLogLevel(type, level);
}

@end

SapphireLogLevel SapphireLoggingLevels[SAPPHIRE_LOG_ALL] = {
	SAPPHIRE_LOG_LEVEL_ERROR,
	SAPPHIRE_LOG_LEVEL_ERROR,
	SAPPHIRE_LOG_LEVEL_ERROR,
	SAPPHIRE_LOG_LEVEL_ERROR,
	SAPPHIRE_LOG_LEVEL_ERROR,
};

void SapphireLog(SapphireLogType type, SapphireLogLevel level, NSString *format, ...)
{
	if(SapphireLoggingLevels[type] >= level)
	{
		va_list ap;
		va_start(ap, format);
		NSLogv(format, ap);
		va_end(ap);
	}
}

void SapphireSetLogLevel(SapphireLogType type, SapphireLogLevel level)
{
	if(type == SAPPHIRE_LOG_ALL)
	{
		int i;
		for(i=0; i<SAPPHIRE_LOG_ALL; i++)
			SapphireLoggingLevels[i] = level;
	}
	else
		SapphireLoggingLevels[type] = level;
}