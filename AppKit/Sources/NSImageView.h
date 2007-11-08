/*
   NSImageView.h

   Image View class

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

#ifndef _mySTEP_H_NSImageView
#define _mySTEP_H_NSImageView

#import <AppKit/NSControl.h>
#import <AppKit/NSImageCell.h>

@interface NSImageView : NSControl
{
	BOOL _allowsCutCopyPaste;
}

- (BOOL) allowsCutCopyPaste;
- (BOOL) animates;
- (NSImage *) image;
- (NSImageAlignment) imageAlignment;
- (NSImageFrameStyle) imageFrameStyle;
- (NSImageScaling) imageScaling;
- (BOOL) isEditable;
- (void) setAllowsCutCopyPaste:(BOOL) flag;
- (void) setAnimates:(BOOL) flag;
- (void) setEditable:(BOOL) flag;
- (void) setImage:(NSImage *) image;
- (void) setImageAlignment:(NSImageAlignment) align;
- (void) setImageFrameStyle:(NSImageFrameStyle) style;
- (void) setImageScaling:(NSImageScaling) scaling;

@end

#endif /* _mySTEP_H_NSImageView */
