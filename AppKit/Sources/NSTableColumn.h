/* 
   NSTableColumn.h

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

#ifndef _mySTEP_H_NSTableColumn
#define _mySTEP_H_NSTableColumn

#import <AppKit/NSControl.h>
#import <AppKit/NSTextFieldCell.h>

@class NSCell;
@class NSTableHeaderCell;
@class NSTableView;
@class NSSortDescriptor;

enum
{
    NSTableColumnNoResizing=		0x00,
    NSTableColumnAutoresizingMask=	0x01,
    NSTableColumnUserResizingMask=	0x02
};

@interface NSTableColumn : NSObject
{
    id _identifier;
    CGFloat _minWidth;
    CGFloat _maxWidth;
    NSTableView *_tableView;
    NSTableHeaderCell *_headerCell;
    NSCell *_dataCell;
    NSSortDescriptor *_sortDescriptor;
    struct __colFlags {
        unsigned int resizingMask:2;
        unsigned int isEditable:1;
        unsigned int reserved:5;
    } _cFlags;

@public
    CGFloat _width;
}

- (id) dataCell;
- (id) dataCellForRow:(NSInteger) row;
- (id) headerCell;
- (NSString *) headerToolTip;
- (id) identifier;
- (id) initWithIdentifier:(id) identifier;
- (BOOL) isEditable;
- (BOOL) isHidden;
- (BOOL) isResizable;	// deprecated in 10.4
- (CGFloat) maxWidth;
- (CGFloat) minWidth;
- (NSUInteger) resizingMask;
- (void) setDataCell:(NSCell *) cell;
- (void) setEditable:(BOOL) flag;
- (void) setHeaderCell:(NSCell *) cell;
- (void) setHeaderToolTip:(NSString *) str;
- (void) setHidden:(BOOL) flag;
- (void) setIdentifier:(id) identifier;
- (void) setMaxWidth:(CGFloat) maxWidth;
- (void) setMinWidth:(CGFloat) minWidth;
- (void) setResizable:(BOOL) flag;	// deprecated in 10.4
- (void) setResizingMask:(NSUInteger) mask;
- (void) setSortDescriptorPrototype:(NSSortDescriptor *) desc;
- (void) setTableView:(NSTableView *) tableView;
- (void) setWidth:(CGFloat) width;
- (void) sizeToFit;
- (NSSortDescriptor *) sortDescriptorPrototype;
- (NSTableView *) tableView;
- (CGFloat) width;

@end

#endif /* _mySTEP_H_NSTableColumn */
