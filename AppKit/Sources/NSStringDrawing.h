/* 
   NSStringDrawing.h

   Draw and Measure categories of NSString and NSAttributedString 

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    Aug 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5 (NSStringDrawingAdditions)
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSStringDrawing
#define _mySTEP_H_NSStringDrawing

#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSGeometry.h>

typedef enum 
{
    NSStringDrawingUsesLineFragmentOrigin=0x01,
    NSStringDrawingUsesFontLeading=0x02,
    NSStringDrawingDisableScreenFontSubstitution=0x04,
    NSStringDrawingUsesDeviceMetrics=0x08,
    NSStringDrawingOneShot=0x10
} NSStringDrawingOptions;

@interface NSString (NSStringDrawingAdditions)

- (NSRect) boundingRectWithSize:(NSSize) size
						options:(NSStringDrawingOptions) options
					 attributes:(NSDictionary *) attributes;
- (void) drawAtPoint:(NSPoint) point
	  withAttributes:(NSDictionary *) attrs;
- (void) drawInRect:(NSRect) rect
	 withAttributes:(NSDictionary *) attrs;
- (void) drawWithRect:(NSRect) rect
			  options:(NSStringDrawingOptions) options
		   attributes:(NSDictionary *) attributes;
- (NSSize) sizeWithAttributes:(NSDictionary *) attrs;

@end


@interface NSAttributedString (NSAttributedStringDrawingAdditions)

- (NSRect) boundingRectWithSize:(NSSize) size
						options:(NSStringDrawingOptions) options;
- (void) drawAtPoint:(NSPoint) point;
- (void) drawInRect:(NSRect) rect;
- (void) drawWithRect:(NSRect) rect
			  options:(NSStringDrawingOptions) options;
- (NSSize) size;

@end

#endif /* _mySTEP_H_NSStringDrawing */
