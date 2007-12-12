/* 
   NSTableHeaderView.h

   Interface to NSTableView classes

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date:    June 1999
    
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Aug 2006 - aligned with 10.4

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSTableHeaderView
#define _mySTEP_H_NSTableHeaderView

#import <AppKit/NSControl.h>

@class NSCursor;
@class NSImage;
@class NSTableView;

@interface NSTableHeaderView : NSView
{
    NSTableView *_tableView;
    NSImage *_headerDragImage;
    NSCursor *_resizeCursor;
    float _draggedDistance;
    int _resizedColumn;
    int _draggedColumn;
    int _mayDragColumn;
    BOOL _drawingLastColumn;
}

- (NSInteger) columnAtPoint:(NSPoint) point;
- (NSInteger) draggedColumn;
- (CGFloat) draggedDistance;
- (NSRect) headerRectOfColumn:(NSInteger) column;
- (NSInteger) resizedColumn;
- (void) setTableView:(NSTableView *) tableView;
- (NSTableView *) tableView;

@end

#endif /* _mySTEP_H_NSTableHeaderView */
