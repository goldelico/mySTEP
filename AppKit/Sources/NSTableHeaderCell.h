/*
	NSTableHeaderCell.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	12. December 2007 - aligned with 10.5    

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTableHeaderCell
#define _mySTEP_H_NSTableHeaderCell

#import "AppKit/NSCell.h"
#import "AppKit/NSTextFieldCell.h"

@interface NSTableHeaderCell : NSTextFieldCell

- (void) drawSortIndicatorWithFrame:(NSRect) cellFrame 
							 inView:(NSView *) controlView
						  ascending:(BOOL) ascending 
						   priority:(int) priority;
- (NSRect) sortIndicatorRectForBounds:(NSRect) theRect;

@end


#endif /* _mySTEP_H_NSTableHeaderCell */
