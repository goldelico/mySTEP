//
//  NSSegmentedCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSSegmentedCell
#define _mySTEP_H_NSSegmentedCell

#import "AppKit/NSActionCell.h"

typedef enum _NSSegmentSwitchTracking
{
	NSSegmentSwitchTrackingSelectOne=0,
	NSSegmentSwitchTrackingSelectAny,
	NSSegmentSwitchTrackingMomentary
} NSSegmentSwitchTracking;

@interface NSSegmentedCell : NSActionCell
{
	NSMutableArray *_segments;
	int _lastSelected;
	int _selectedCount;
	NSSegmentSwitchTracking _mode;
}

- (void) drawSegment:(int) segment inFrame:(NSRect) frame withView:(NSView *) view;
- (NSImage *) imageForSegment:(int) segment;
- (BOOL) isEnabledForSegment:(int) segment;
- (BOOL) isSelectedForSegment:(int) segment;
- (NSString *) labelForSegment:(int) segment;
- (void) makeNextSegmentKey;
- (void) makePreviousSegmentKey;
- (NSMenu *) menuForSegment:(int) segment;
- (int) segmentCount;
- (int) selectedSegment;
- (BOOL) selectSegmentWithTag:(int) tag;
- (void) setEnabled:(BOOL) flag forSegment:(int) segment;
- (void) setImage:(NSImage *) image forSegment:(int) segment;
- (void) setLabel:(NSString *) label forSegment:(int) segment;
- (void) setMenu:(NSMenu *) menu forSegment:(int) segment;
- (void) setSegmentCount:(int) count;	// limited to 2049?
- (void) setSelected:(BOOL) flag forSegment:(int) segment;
- (void) setSelectedSegment:(int) segment;
- (void) setTag:(int) tag forSegment:(int) segment;
- (void) setToolTip:(NSString *) tooltip forSegment:(int) segment;
- (void) setTrackingMode:(NSSegmentSwitchTracking) mode;
- (void) setWidth:(float) width forSegment:(int) segment;
- (int) tagForSegment:(int) segment;
- (NSString *) toolTipForSegment:(int) segment;
- (NSSegmentSwitchTracking) trackingMode;
- (float) widthForSegment:(int) segment;

@end

#endif /* _mySTEP_H_NSSegmentedCell */
