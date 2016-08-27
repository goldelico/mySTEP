/*$Id: SenSortOrdering.h,v 1.1 2002/06/05 08:44:11 phink Exp $*/

// This is Goban, a Go program for Mac OS X.  Contact goban@sente.ch,
// or see http://www.sente.ch/software/goban for more information.
//
// Copyright (c) 1997-2002, Sen:te (Sente SA).  All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation - version 2.
//
// This program is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License in file COPYING
// for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111, USA.

#import <Foundation/Foundation.h>

@interface SenSortOrdering : NSObject
{
    SEL selector;
    NSString *key;
}

+ (id) sortOrderingWithKey:(NSString *) aKey selector:(SEL) aSelector;

- (id) initWithKey:(NSString *) aKey selector:(SEL) aSelector;
- (NSString *) key;
- (SEL) selector;
@end


@interface NSArray (SenKeyBasedSorting)
- (NSArray *) arrayBySortingOnKeyOrderArray:(NSArray *) orderArray;
@end


@interface NSMutableArray (SenKeyBasedSorting)
- (void) sortOnKeyOrderArray:(NSArray *) orderArray;
@end


@interface NSObject (SenSortOrderingComparison)
- (NSComparisonResult) compareAscending:(id) other;
- (NSComparisonResult) compareDescending:(id) other;
@end


#define SenCompareAscending @selector(compareAscending:)
#define SenCompareDescending @selector(compareDescending:)
