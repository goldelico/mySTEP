/* 
   NSImageCell.h

   Image View Cell class

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	Jan 2004
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Sep 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSImageCell
#define _mySTEP_H_NSImageCell

#import <AppKit/NSCell.h>

enum { /* old */
	NSScaleProportionally = NSImageScaleProportionallyDown,
	NSScaleToFit = NSImageScaleAxesIndependently,
	NSScaleNone = NSImageScaleNone
};

typedef enum {
	NSImageAlignCenter = 0,
	NSImageAlignTop,
	NSImageAlignTopLeft,
	NSImageAlignTopRight,
	NSImageAlignLeft,
	NSImageAlignBottom,
	NSImageAlignBottomLeft,
	NSImageAlignBottomRight,
	NSImageAlignRight
} NSImageAlignment;

typedef enum {
	NSImageFrameNone = 0,
	NSImageFramePhoto,
	NSImageFrameGrayBezel,
	NSImageFrameGroove,
	NSImageFrameButton
} NSImageFrameStyle;


@interface NSImageCell : NSCell <NSCopying, NSCoding>
{
	NSInteger tag;
	id target;
	SEL action;
	struct __ImageCellFlags {
		TYPEDBITFIELD(NSImageAlignment, imageAlignment, 4);
		TYPEDBITFIELD(NSImageFrameStyle, imageFrameStyle, 3);
		UIBITFIELD(unsigned int, imageAnimates, 1);
		UIBITFIELD(unsigned int, reserved, 6);
		} _ic;
}

- (NSImageAlignment) imageAlignment;
- (NSImageFrameStyle) imageFrameStyle;
- (NSImageScaling) imageScaling;

- (void) setImageAlignment:(NSImageAlignment) newAlign;
- (void) setImageFrameStyle:(NSImageFrameStyle) newStyle;
- (void) setImageScaling:(NSImageScaling) newScaling;


@end

#endif /* _mySTEP_H_NSImageCell */
