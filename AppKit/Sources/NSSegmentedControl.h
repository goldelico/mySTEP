//
//  NSSegmentedControl.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSSegmentedControl
#define _mySTEP_H_NSSegmentedControl

#import "AppKit/NSControl.h"

@interface NSSegmentedControl : NSControl
{ // controls an NSSegmentedCell
}

- (NSImage *) imageForSegment:(int) segment;
- (BOOL) isEnabledForSegment:(int) segment;
- (BOOL) isSelectedForSegment:(int) segment;
- (NSString *) labelForSegment:(int) segment;
- (NSMenu *) menuForSegment:(int) segment;
- (int) segmentCount;
- (int) selectedSegment;
- (BOOL) selectSegmentWithTag:(int) tag;
- (void) setEnabled:(BOOL) flag forSegment:(int) segment;
- (void) setImage:(NSImage *) image forSegment:(int) segment;
- (void) setLabel:(NSString *) label forSegment:(int) segment;
- (void) setMenu:(NSMenu *) menu forSegment:(int) segment;
- (void) setSegmentCount:(int) count;
- (void) setSelected:(BOOL) flag forSegment:(int) segment;
- (void) setSelectedSegment:(int) segment;
- (void) setWidth:(float) width forSegment:(int) segment;
- (float) widthForSegment:(int) segment;

@end

#endif /* _mySTEP_H_NSSegmentedControl */
