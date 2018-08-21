/*
	NSTextList.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	12. December 2007 - aligned with 10.5
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTextList
#define _mySTEP_H_NSTextList

#import "AppKit/NSController.h"

enum _NSTextListOptions
{
	NSTextListPrependEnclosingMarker = 0x01
};

@interface NSTextList : NSObject <NSCoding>
{
	NSString *_markerFormat;
	NSUInteger _listOptions;
	NSInteger _startingItemNumber;
}

- (id) initWithMarkerFormat:(NSString *) format options:(NSUInteger) mask;
- (NSUInteger) listOptions;
- (NSString *) markerForItemNumber:(NSInteger) item;
- (NSString *) markerFormat;
- (void) setStartingItemNumber:(NSInteger) item;
- (NSInteger) startingItemNumber;

@end

#endif /* _mySTEP_H_NSTextList */
