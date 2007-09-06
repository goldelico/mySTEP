/* 
   NSTableView.h

   Interface to NSTableView classes

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date:    June 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Aug 2006 - aligned with 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSTableView
#define _mySTEP_H_NSTableView

#import <AppKit/NSControl.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSTableColumn.h>

@class NSCell;
@class NSColor;
@class NSCursor;
@class NSImage;
@class NSTableView;

typedef enum NSTableViewColumnAutoresizingStyle
{
    NSTableViewNoColumnAutoresizing=0,
    NSTableViewUniformColumnAutoresizingStyle,
    NSTableViewSequentialColumnAutoresizingStyle,
    NSTableViewReverseSequentialColumnAutoresizingStyle,
    NSTableViewLastColumnOnlyAutoresizingStyle,
    NSTableViewFirstColumnOnlyAutoresizingStyle
} NSTableViewColumnAutoresizingStyle;

enum
{
    NSTableViewGridNone                    = 0,
    NSTableViewSolidVerticalGridLineMask   = 0x01,
    NSTableViewSolidHorizontalGridLineMask = 0x02
};

typedef enum NSTableViewDropOperation {
	NSTableViewDropOn,
	NSTableViewDropAbove
} NSTableViewDropOperation;

@interface NSTableView : NSControl
{
	NSTableHeaderView *_headerView;
	NSView *_cornerView;
    NSCell *_editingCell;
    NSColor *_backgroundColor;
    NSColor *_gridColor;
	NSString *_autosaveName;
    NSMutableArray *_tableColumns;
	NSMutableArray *_indicatorImages;
	NSMutableIndexSet *_selectedColumns; 
	NSMutableIndexSet *_selectedRows;
	NSTableColumn *_highlightedTableColumn;	// weak reference
    id _dataSource;
    id _target;
    SEL _action;
    SEL _doubleAction;
    NSSize _intercellSpacing;
	NSRange _columnRange;
    float _rowHeight;
	float _cacheOrigin;
	float _cacheWidth;
	float _cachedColOrigin;
	unsigned int _draggingSourceOperationMaskForLocal;		// we have a dynamic mask
	unsigned int _draggingSourceOperationMaskForRemote;
    int _lastSelectedColumn;
    int _lastSelectedRow;
    int _editingColumn;
    int _editingRow;
    int _clickedColumn;
    int _clickedRow;

	struct __TableViewFlags {
		UIBITFIELD(unsigned int, delegateSelectionShouldChangeInTableView, 1);
		UIBITFIELD(unsigned int, delegateShouldSelectTableColumn, 1);
		UIBITFIELD(unsigned int, delegateShouldSelectRow, 1);
		UIBITFIELD(unsigned int, delegateShouldEditTableColumn, 1);
		UIBITFIELD(unsigned int, delegateWillDisplayCell, 1);
		UIBITFIELD(unsigned int, allowsColumnSelection, 1);
		UIBITFIELD(unsigned int, allowsMultipleSelection, 1);
		UIBITFIELD(unsigned int, allowsEmptySelection, 1);
		UIBITFIELD(unsigned int, usesAlternatingRowBackgroundColors, 1);
		UIBITFIELD(unsigned int, gridStyleMask, 2);
		UIBITFIELD(unsigned int, allowsColumnResizing, 1);
		UIBITFIELD(unsigned int, allowsColumnReordering, 1);
		TYPEDBITFIELD(NSTableViewColumnAutoresizingStyle, autoResizingStyle, 3);
		UIBITFIELD(unsigned int, autosaveTableColumns, 1);
		UIBITFIELD(unsigned int, verticalMotionCanBeginDrag, 1);
		} _tv;
}

- (void) addTableColumn:(NSTableColumn *)column;
- (BOOL) allowsColumnReordering;
- (BOOL) allowsColumnResizing;
- (BOOL) allowsColumnSelection;
- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (BOOL) autoresizesAllColumnsToFit;
- (NSString *) autosaveName;
- (BOOL) autosaveTableColumns;
- (NSColor*) backgroundColor;
- (BOOL) canDragRowsWithIndexes:(NSIndexSet *) indexes atPoint:(NSPoint) point;
- (int) clickedColumn;
- (int) clickedRow;
- (int) columnAtPoint:(NSPoint)point;
- (NSTableViewColumnAutoresizingStyle) columnAutoresizingStyle;
- (NSRange) columnsInRect:(NSRect)rect;
- (int) columnWithIdentifier:(id)identifier;
- (NSView*) cornerView;
- (id) dataSource;
- (id) delegate;
- (void) deselectAll:(id)sender;
- (void) deselectColumn:(int)column;
- (void) deselectRow:(int)row;
- (SEL) doubleAction;
- (NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) rows
							 tableColumns:(NSArray *) cols
									event:(NSEvent*) event
								   offset:(NSPointPointer) offset;
- (void) drawBackgroundInClipRect:(NSRect) rect;
- (void) drawGridInClipRect:(NSRect)rect;
- (void) drawRow:(int)row clipRect:(NSRect)rect;
- (BOOL) drawsGrid;
- (void) editColumn:(int)column
				row:(int)row 
		  withEvent:(NSEvent *)event 
			 select:(BOOL)select;
- (NSRect) frameOfCellAtColumn:(int) col row:(int) row;
- (int) editedColumn;
- (int) editedRow;
- (NSRect) frameOfCellAtColumn:(int)column row:(int)row;
- (NSColor*) gridColor;
- (unsigned int) gridStyleMask;
- (NSTableHeaderView*) headerView;
- (NSTableColumn *) highlightedTableColumn;
- (void) highlightSelectionInClipRect:(NSRect)rect;
- (NSImage *) indicatorImageInTableColumn:(NSTableColumn *) col;
- (NSSize) intercellSpacing;
- (BOOL) isColumnSelected:(int)columnIndex;
- (BOOL) isRowSelected:(int)rowIndex;
- (void) moveColumn:(int)column toColumn:(int)newIndex;
- (void) noteHeightOfRowsWithIndexesChanged:(NSIndexSet *) indexes;
- (void) noteNumberOfRowsChanged;
- (int) numberOfColumns;
- (int) numberOfRows;
- (int) numberOfSelectedColumns;
- (int) numberOfSelectedRows;
- (NSRect) rectOfColumn:(int)column;
- (NSRect) rectOfRow:(int)row;
- (void) reloadData;
- (void) removeTableColumn:(NSTableColumn *)column;
- (int) rowAtPoint:(NSPoint)point;
- (float) rowHeight;
- (NSRange) rowsInRect:(NSRect)rect;
- (void) scrollColumnToVisible:(int)column;
- (void) scrollRowToVisible:(int)row;
- (void) selectAll:(id)sender;
- (void) selectColumn:(int)column byExtendingSelection:(BOOL)extend;
- (void) selectColumnIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL)extend;
- (int) selectedColumn;
- (NSEnumerator*) selectedColumnEnumerator;
- (NSIndexSet *) selectedColumnIndexes;
- (int) selectedRow;
- (NSEnumerator*) selectedRowEnumerator;
- (NSIndexSet *) selectedRowIndexes;
- (void) selectRow:(int)row byExtendingSelection:(BOOL)extend;
- (void) selectRowIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL)extend;
- (void) setAllowsColumnReordering:(BOOL)flag;
- (void) setAllowsColumnResizing:(BOOL)flag;
- (void) setAllowsColumnSelection:(BOOL)flag;
- (void) setAllowsEmptySelection:(BOOL)flag;
- (void) setAllowsMultipleSelection:(BOOL)flag;
- (void) setAutoresizesAllColumnsToFit:(BOOL)flag;
- (void) setAutosaveName:(NSString *)name;
- (void) setAutosaveTableColumns:(BOOL)flag;
- (void) setBackgroundColor:(NSColor *)color;
- (void) setColumnAutoresizingStyle:(NSTableViewColumnAutoresizingStyle) style;
- (void) setCornerView:(NSView *)cornerView;
- (void) setDataSource:(id)aSource;
- (void) setDelegate:(id)delegate;
- (void) setDoubleAction:(SEL)aSelector;
- (void) setDraggingSourceOperationMask:(unsigned int) mask forLocal:(BOOL)isLocal;
- (void) setDrawsGrid:(BOOL)flag;
- (void) setDropRow:(int)row dropOperation:(NSTableViewDropOperation)op;
- (void) setGridColor:(NSColor *)color;
- (void) setGridStyleMask:(unsigned int) mask;
- (void) setHeaderView:(NSTableHeaderView *)headerView;
- (void) setHighlightedTableColumn:(NSTableColumn *)col;
- (void) setIndicatorImage:(NSImage *)img inTableColumn:(NSTableColumn *)col;
- (void) setIntercellSpacing:(NSSize)aSize;
- (void) setRowHeight:(float)rowHeight;
- (void) setSortDescriptors:(NSArray *)array;
- (void) setUsesAlternatingRowBackgroundColors:(BOOL) flag;
- (void) setVerticalMotionCanBeginDrag:(BOOL)flag;
- (void) sizeLastColumnToFit;
- (void) sizeToFit;
- (NSArray *) sortDescriptors;
- (NSArray*) tableColumns;
- (NSTableColumn*) tableColumnWithIdentifier:(id)identifier;
- (void) textDidBeginEditing:(NSNotification *)notification;
- (void) textDidChange:(NSNotification *)notification;
- (void) textDidEndEditing:(NSNotification *)notification;
- (BOOL) textShouldBeginEditing:(NSText *)textObject;
- (BOOL) textShouldEndEditing:(NSText *)textObject;
- (void) tile;
- (BOOL) usesAlternatingRowBackgroundColors;
- (BOOL) verticalMotionCanBeginDrag;

@end

@interface NSTableView (NSTableViewPrivate) 
+ (NSImage *) _defaultTableHeaderReverseSortImage; 
+ (NSImage *) _defaultTableHeaderSortImage; 
@end

@interface NSObject (NSTableViewDelegate)					// Implemented by
															// the delegate
- (BOOL) selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (void) tableView:(NSTableView *)tableView
		 didClickTableColumn:(NSTableColumn *)col;
- (void) tableView:(NSTableView *)tableView
		 didDragTableColumn:(NSTableColumn *)col;
- (float) tableView:(NSTableView *)tableView
		 heightOfRow:(int)row;
- (void) tableView:(NSTableView *)tableView
		 mouseDownInHeaderOfTableColumn:(NSTableColumn *)col;
- (BOOL) tableView:(NSTableView *)tableView 
		 shouldEditTableColumn:(NSTableColumn *)tableColumn 
		 row:(int)row;
- (BOOL) tableView:(NSTableView *)tableView
		 shouldSelectRow:(int)row;
- (BOOL) tableView:(NSTableView *)tableView 
		 shouldSelectTableColumn:(NSTableColumn *)tableColumn;
- (NSString *) tableView:(NSTableView *)tableView
		 toolTipForCell:(NSCell *)cell
		 rect:(NSRectPointer)rect
		 tableColumn:(NSTableColumn *)col
		 row:(int)row
		   mouseLocation:(NSPoint)mouse;
- (void) tableView:(NSTableView *)tableView 
		 willDisplayCell:(id)cell 
		 forTableColumn:(NSTableColumn *)tableColumn 
		 row:(int)row;

@end


@interface NSObject (NSTableViewNotifications)

- (void) tableViewColumnDidMove:(NSNotification *)notification;
- (void) tableViewColumnDidResize:(NSNotification *)notification;
- (void) tableViewSelectionDidChange:(NSNotification *)notification;
- (void) tableViewSelectionIsChanging:(NSNotification *)notification;

@end

															// Notifications
extern NSString *NSTableViewColumnDidMoveNotification;		// @"NSOldColumn", @"NSNewColumn"
extern NSString *NSTableViewColumnDidResizeNotification;	// @"NSTableColumn", @"NSOldWidth"
extern NSString *NSTableViewSelectionDidChangeNotification;
extern NSString *NSTableViewSelectionIsChangingNotification;


@interface NSObject (NSTableDataSource)						// Implemented by
															// the datasource
- (int) numberOfRowsInTableView:(NSTableView *)tableView;
- (id) tableView:(NSTableView *)tableView 
	   objectValueForTableColumn:(NSTableColumn *)tableColumn 
	   row:(int)row;
- (void) tableView:(NSTableView *)tableView 
		 setObjectValue:(id)object 
		 forTableColumn:(NSTableColumn *)tableColumn 
		 row:(int)row;
@end

#endif /* _mySTEP_H_NSTableView */
