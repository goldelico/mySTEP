/* 
   NSActionCell.h

   Abstract cell for target/action paradigm

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

   Author:	Fabian Spillner
   Date:	16. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSActionCell
#define _mySTEP_H_NSActionCell

#import <AppKit/NSCell.h>

@interface NSActionCell : NSCell  <NSCopying, NSCoding>
{
	int tag;
	id target;
	SEL action;
}

- (SEL) action;
- (NSView *) controlView;
- (double) doubleValue;
- (float) floatValue;
- (int) intValue;
- (NSInteger) integerValue;
- (void) setAction:(SEL) sel;						// Target / Action
- (void) setAlignment:(NSTextAlignment) mode;			// graphic attributes
- (void) setBezeled:(BOOL) flag;
- (void) setBordered:(BOOL) flag;
- (void) setControlView:(NSView*) controlView;
- (void) setEnabled:(BOOL) flag;
- (void) setFloatingPointFormat:(BOOL) range left:(NSUInteger) left right:(NSUInteger) right;
- (void) setFont:(NSFont *) font;				// -> NSCell
- (void) setImage:(NSImage *) image;
- (void) setObjectValue:(id <NSCopying>) object;
- (void) setTag:(int) tag;								// Integer Tag
- (void) setTarget:(id) target;
- (NSString *) stringValue;
- (NSInteger) tag;
- (id) target;

@end

#endif /* _mySTEP_H_NSActionCell */
