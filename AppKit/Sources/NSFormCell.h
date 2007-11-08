/* 
   NSFormCell.h

   Cell class for the NSForm control

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	March 1997
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSFormCell
#define _mySTEP_H_NSFormCell

#import <AppKit/NSActionCell.h>


@interface NSFormCell : NSActionCell
{
	NSCell *_titleCell;
	float _titleWidth;
}

- (NSAttributedString *) attributedTitle;
- (id) initTextCell:(NSString *) str;
- (BOOL) isOpaque;								// Graphic Attributes
- (NSAttributedString *) placeholderAttributedString;
- (NSString *) placeholderString;
- (void) setAttributedTitle:(NSAttributedString *) attrStr;
- (void) setPlaceholderAttributedString:(NSAttributedString *) attrStr;
- (void) setPlaceholderString:(NSString *) str; 
- (void) setTitle:(NSString *) str;					// Title management
- (void) setTitleAlignment:(NSTextAlignment) mode;
- (void) setTitleBaseWritingDirection:(NSWritingDirection) direction;
- (void) setTitleFont:(NSFont *) fontObject;
- (void) setTitleWidth:(CGFloat) width;
- (void) setTitleWithMnemonic:(NSString *) title;
- (NSString *) title;
- (NSTextAlignment) titleAlignment;
- (NSWritingDirection) titleBaseWritingDirection;
- (NSFont *) titleFont;
- (CGFloat) titleWidth;
- (CGFloat) titleWidth:(NSSize) aSize;

@end

#endif /* _mySTEP_H_NSFormCell */
