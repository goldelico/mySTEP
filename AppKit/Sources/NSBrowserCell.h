/* 
   NSBrowserCell.h

   NSBrowser's default cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    October 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	19. October 2007  
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBrowserCell
#define _mySTEP_H_NSBrowserCell

#import <AppKit/NSCell.h>

@class NSImage;


@interface NSBrowserCell : NSCell  <NSCoding>
{
	NSImage *_branchImage;
	NSImage *_highlightBranchImage;
}

+ (NSImage *) branchImage;								// Graphic Attributes
+ (NSImage *) highlightedBranchImage;

- (NSImage *) alternateImage;
- (NSColor *) highlightColorInView:(NSView *) view;
- (NSImage *) image;
- (NSImageScaling) imageScaling;
- (BOOL) isLeaf;									// cell type in browser
- (BOOL) isLoaded;										// cell load status
- (void) reset;											// cell state
- (void) set;
- (void) setAlternateImage:(NSImage *) image;
- (void) setImage:(NSImage *) image;
- (void) setImageScaling:(NSImageScaling) scaling;
- (void) setLeaf:(BOOL) flag;
- (void) setLoaded:(BOOL) flag;

@end

#endif /* _mySTEP_H_NSBrowserCell */
