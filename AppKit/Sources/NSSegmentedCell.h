/*
    NSSegmentedCell.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	05. December 2007 - aligned with 10.5   
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

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

- (void) drawSegment:(NSInteger) segment inFrame:(NSRect) frame withView:(NSView *) view;
- (NSImage *) imageForSegment:(NSInteger) segment;
- (BOOL) isEnabledForSegment:(NSInteger) segment;
- (BOOL) isSelectedForSegment:(NSInteger) segment;
- (NSString *) labelForSegment:(NSInteger) segment;
- (void) makeNextSegmentKey;
- (void) makePreviousSegmentKey;
- (NSMenu *) menuForSegment:(NSInteger) segment;
- (NSInteger) segmentCount;
- (NSInteger) selectedSegment;
- (BOOL) selectSegmentWithTag:(NSInteger) tag;
- (void) setEnabled:(BOOL) flag forSegment:(NSInteger) segment;
- (void) setImage:(NSImage *) image forSegment:(NSInteger) segment;
- (void) setLabel:(NSString *) label forSegment:(NSInteger) segment;
- (void) setMenu:(NSMenu *) menu forSegment:(NSInteger) segment;
- (void) setSegmentCount:(NSInteger) count;	// limited to 2049?
- (void) setSelected:(BOOL) flag forSegment:(NSInteger) segment;
- (void) setSelectedSegment:(NSInteger) segment;
- (void) setTag:(NSInteger) tag forSegment:(NSInteger) segment;
- (void) setToolTip:(NSString *) tooltip forSegment:(NSInteger) segment;
- (void) setTrackingMode:(NSSegmentSwitchTracking) mode;
- (void) setWidth:(CGFloat) width forSegment:(NSInteger) segment;
- (NSInteger) tagForSegment:(NSInteger) segment;
- (NSString *) toolTipForSegment:(NSInteger) segment;
- (NSSegmentSwitchTracking) trackingMode;
- (CGFloat) widthForSegment:(NSInteger) segment;

@end

#endif /* _mySTEP_H_NSSegmentedCell */
