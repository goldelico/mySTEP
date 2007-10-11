/* 
   NSImageCell.h

   Image View Cell class

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	Jan 2004
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Sep 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSImageCell
#define _mySTEP_H_NSImageCell

#import <AppKit/NSCell.h>

typedef enum {
	NSScaleProportionally = 0,
	NSScaleToFit,
	NSScaleNone
} NSImageScaling;

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
	int tag;
	id target;
	SEL action;
	struct __ImageCellFlags {
		TYPEDBITFIELD(NSImageScaling, imageScaling, 2);
		TYPEDBITFIELD(NSImageAlignment, imageAlignment, 4);
		TYPEDBITFIELD(NSImageFrameStyle, imageFrameStyle, 3);
		UIBITFIELD(unsigned int, imageAnimates, 1);
		UIBITFIELD(unsigned int, reserved, 6);
		} _ic;
}

- (NSImageScaling) imageScaling;
- (NSImageAlignment) imageAlignment;
- (NSImageFrameStyle) imageFrameStyle;

- (void) setImageScaling:(NSImageScaling)newScaling;
- (void) setImageAlignment:(NSImageAlignment)newAlign;
- (void) setImageFrameStyle:(NSImageFrameStyle)newStyle;

@end

#endif /* _mySTEP_H_NSImageCell */
