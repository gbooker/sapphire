/*
 * SapphireFileSorter.h
 * Sapphire
 *
 * Created by Graham Booker on Jun. 16, 2008.
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

@interface SapphireFileSorter : NSObject {
}

+ (SapphireFileSorter *)sharedInstance;
+ (BOOL)sortFiles:(NSMutableArray *)files withSorter:(int)sorter inAllowedSorts:(NSArray *)allowed;

- (NSString *)displayName;
- (NSString *)displayDescription;
- (int)sortNumber;
- (void)sortFiles:(NSMutableArray *)files;

@end

@interface SapphireTVEpisodeSorter : SapphireFileSorter {
}

@end

@interface SapphireMovieTitleSorter : SapphireFileSorter {
}

@end

@interface SapphireMovieIMDBTop250RankSorter : SapphireFileSorter {
}

@end

@interface SapphireMovieAcademyAwardSorter : SapphireFileSorter {
}

@end

@interface SapphireDateSorter : SapphireFileSorter {
}

@end

@interface SapphireMovieIMDBRatingSorter : SapphireFileSorter {
}

@end

@interface SapphireDurationSorter : SapphireFileSorter {
}

@end

@interface SapphireFileSizeSorter : SapphireFileSorter {
}

@end
