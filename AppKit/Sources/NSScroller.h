/* 
   NSScroller.h

   The scroller class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSScroller
#define _mySTEP_H_NSScroller

#import <AppKit/NSControl.h>
#import <AppKit/NSCell.h>

@class NSEvent;

typedef enum _NSScrollArrowPosition {
	NSScrollerArrowsMaxEnd,		// deprecated
	NSScrollerArrowsMinEnd,		// deprecated
	NSScrollerArrowsNone,
	NSScrollerArrowsDefaultSetting
} NSScrollArrowPosition;

typedef enum _NSScrollerPart {
	NSScrollerNoPart = 0,
	NSScrollerDecrementPage,
	NSScrollerKnob,
	NSScrollerIncrementPage,
	NSScrollerDecrementLine,
	NSScrollerIncrementLine,
	NSScrollerKnobSlot
} NSScrollerPart;

typedef enum _NSScrollerUsablePart {
	NSNoScrollerParts = 0,
	NSOnlyScrollerArrows,
	NSAllScrollerParts  
} NSUsableScrollerParts;

typedef enum _NSScrollerArrow {
	NSScrollerIncrementArrow,
	NSScrollerDecrementArrow
} NSScrollerArrow;


@interface NSScroller : NSControl  <NSCoding>
{
	float _floatValue;
	float _knobProportion;
	id _target;
	SEL _action;
	NSScrollerPart _hitPart;
	BOOL _isHorizontal;
	BOOL _isEnabled;
	NSScrollArrowPosition _arrowsPosition;
	NSUsableScrollerParts _usableParts;
	NSControlSize _controlSize;
	NSControlTint _controlTint;
}

+ (CGFloat) scrollerWidth;
+ (CGFloat) scrollerWidthForControlSize:(NSControlSize) controlSize;

- (NSScrollArrowPosition) arrowsPosition;
- (void) checkSpaceForParts;
- (NSControlSize) controlSize;
- (NSControlTint) controlTint;
- (void) drawArrow:(NSScrollerArrow) whichButton highlight:(BOOL) flag;
- (void) drawKnob;
- (void) drawParts;
- (void) highlight:(BOOL) flag;
- (NSScrollerPart) hitPart;									// Handling Events
- (CGFloat) knobProportion;									// Attributes
- (NSRect) rectForPart:(NSScrollerPart) partCode;
- (void) setArrowsPosition:(NSScrollArrowPosition) where;
- (void) setControlSize:(NSControlSize) size;
- (void) setControlTint:(NSControlTint) tint;
- (void) setEnabled:(BOOL) flag;
- (void) setFloatValue:(float) aFloat knobProportion:(CGFloat) ratio;
- (NSScrollerPart) testPart:(NSPoint) thePoint;
- (void) trackKnob:(NSEvent *) event;
- (void) trackScrollButtons:(NSEvent *) event;
- (NSUsableScrollerParts) usableParts;

@end

#endif /* _mySTEP_H_NSScroller */
