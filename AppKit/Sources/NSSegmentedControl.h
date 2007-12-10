/*
	NSSegmentedControl.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	05. December 2007 - aligned with 10.5   
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSSegmentedControl
#define _mySTEP_H_NSSegmentedControl

#import "AppKit/NSControl.h"

@interface NSSegmentedControl : NSControl
{ // controls an NSSegmentedCell
}

- (NSImage *) imageForSegment:(NSInteger) segment;
- (BOOL) isEnabledForSegment:(NSInteger) segment;
- (BOOL) isSelectedForSegment:(NSInteger) segment;
- (NSString *) labelForSegment:(NSInteger) segment;
- (NSMenu *) menuForSegment:(NSInteger) segment;
- (NSInteger) segmentCount;
- (NSInteger) selectedSegment;
- (BOOL) selectSegmentWithTag:(NSInteger) tag;
- (void) setEnabled:(BOOL) flag forSegment:(NSInteger) segment;
- (void) setImage:(NSImage *) image forSegment:(NSInteger) segment;
- (void) setLabel:(NSString *) label forSegment:(NSInteger) segment;
- (void) setMenu:(NSMenu *) menu forSegment:(NSInteger) segment;
- (void) setSegmentCount:(NSInteger) count;
- (void) setSelected:(BOOL) flag forSegment:(NSInteger) segment;
- (void) setSelectedSegment:(NSInteger) segment;
- (void) setWidth:(CGFloat) width forSegment:(NSInteger) segment;
- (CGFloat) widthForSegment:(NSInteger) segment;

@end

#endif /* _mySTEP_H_NSSegmentedControl */
