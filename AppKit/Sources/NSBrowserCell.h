/* 
   NSBrowserCell.h

   NSBrowser's default cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    October 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
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
- (NSColor *) highlightColorInView:(NSView *) controlView;
- (NSImage *) image;
- (BOOL) isLeaf;										// cell type in browser
- (BOOL) isLoaded;										// cell load status
- (void) reset;											// cell state
- (void) setAlternateImage:(NSImage *)anImage;
- (void) setImage:(NSImage *)anImage;
- (void) setLeaf:(BOOL)flag;
- (void) setLoaded:(BOOL)flag;
- (void) set;

@end

#endif /* _mySTEP_H_NSBrowserCell */
