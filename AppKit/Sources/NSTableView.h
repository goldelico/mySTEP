/* 
   NSTableView.h

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

#ifndef _mySTEP_H_NSTableView
#define _mySTEP_H_NSTableView

#import <AppKit/NSControl.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSTableColumn.h>

@class NSCell;
@class NSColor;
@class NSCursor;
@class NSImage;
@class NSTableView;

enum NSTableViewColumnAutoresizingStyle
{
    NSTableViewNoColumnAutoresizing=0,
    NSTableViewUniformColumnAutoresizingStyle,
    NSTableViewSequentialColumnAutoresizingStyle,
    NSTableViewReverseSequentialColumnAutoresizingStyle,
    NSTableViewLastColumnOnlyAutoresizingStyle,
    NSTableViewFirstColumnOnlyAutoresizingStyle
};
typedef NSUInteger NSTableViewColumnAutoresizingStyle;

enum 
{
	NSTableViewSelectionHighlightStyleRegular = 0,
	NSTableViewSelectionHighlightStyleSourceList = 1,
};
typedef NSInteger NSTableViewSelectionHighlightStyle;

enum
{
    NSTableViewGridNone                    = 0,
    NSTableViewSolidVerticalGridLineMask   = 0x01,
    NSTableViewSolidHorizontalGridLineMask = 0x02
};

enum NSTableViewDropOperation {
	NSTableViewDropOn,
	NSTableViewDropAbove
};
typedef NSUInteger NSTableViewDropOperation;

@interface NSTableView : NSControl
{
	NSTableHeaderView *_headerView;
	NSView *_cornerView;
	NSTableDataCell *_clickedCell;
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
	NSRect _clickedCellFrame;
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
	int _numberOfRows;	// cached value

	struct __TableViewFlags {
		TYPEDBITFIELD(NSTableViewColumnAutoresizingStyle, autoResizingStyle, 3);
		UIBITFIELD(unsigned int, gridStyleMask, 2);
		UIBITFIELD(unsigned int, delegateSelectionShouldChangeInTableView, 1);
		UIBITFIELD(unsigned int, delegateShouldSelectTableColumn, 1);
		UIBITFIELD(unsigned int, delegateShouldSelectRow, 1);
		UIBITFIELD(unsigned int, delegateShouldEditTableColumn, 1);
		UIBITFIELD(unsigned int, delegateWillDisplayCell, 1);
		UIBITFIELD(unsigned int, delegateProvidesHeightOfRow, 1);
		UIBITFIELD(unsigned int, allowsColumnSelection, 1);
		UIBITFIELD(unsigned int, allowsMultipleSelection, 1);
		UIBITFIELD(unsigned int, allowsEmptySelection, 1);
		UIBITFIELD(unsigned int, usesAlternatingRowBackgroundColors, 1);
		UIBITFIELD(unsigned int, allowsColumnResizing, 1);
		UIBITFIELD(unsigned int, allowsColumnReordering, 1);
		UIBITFIELD(unsigned int, autosaveTableColumns, 1);
		UIBITFIELD(unsigned int, verticalMotionCanBeginDrag, 1);
		} _tv;
}

- (void) addTableColumn:(NSTableColumn *) column;
- (BOOL) allowsColumnReordering;
- (BOOL) allowsColumnResizing;
- (BOOL) allowsColumnSelection;
- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (BOOL) allowsTypeSelect; 
- (BOOL) autoresizesAllColumnsToFit; /* DEPRECATED */
- (NSString *) autosaveName;
- (BOOL) autosaveTableColumns;
- (NSColor *) backgroundColor;
- (BOOL) canDragRowsWithIndexes:(NSIndexSet *) indexes atPoint:(NSPoint) point;
- (NSInteger) clickedColumn;
- (NSInteger) clickedRow;
- (NSInteger) columnAtPoint:(NSPoint) point;
- (NSTableViewColumnAutoresizingStyle) columnAutoresizingStyle;
- (NSIndexSet *)columnIndexesInRect:(NSRect) rect;
- (NSRange) columnsInRect:(NSRect) rect;
- (NSInteger) columnWithIdentifier:(id) identifier;
- (NSView *) cornerView;
- (id) dataSource;
- (id) delegate;
- (void) deselectAll:(id) sender;
- (void) deselectColumn:(NSInteger) column;
- (void) deselectRow:(NSInteger) row;
- (SEL) doubleAction;
- (NSImage *) dragImageForRows:(NSArray *) rows 
						 event:(NSEvent *) event 
			   dragImageOffset:(NSPointPointer) offset; /* DEPRECATED */
- (NSImage *) dragImageForRowsWithIndexes:(NSIndexSet *) rows
							 tableColumns:(NSArray *) cols
									event:(NSEvent *) event
								   offset:(NSPointPointer) offset;
- (void) drawBackgroundInClipRect:(NSRect) rect;
- (void) drawGridInClipRect:(NSRect) rect;
- (void) drawRow:(NSInteger) row clipRect:(NSRect) rect;
- (BOOL) drawsGrid; /* DEPRECATED */
- (void) editColumn:(NSInteger) column
				row:(NSInteger) row 
		  withEvent:(NSEvent *) event 
			 select:(BOOL) select;
- (NSInteger) editedColumn;
- (NSInteger) editedRow;
- (NSRect) frameOfCellAtColumn:(NSInteger) column row:(NSInteger) row;
- (NSColor *) gridColor;
- (NSUInteger) gridStyleMask;
- (NSTableHeaderView *) headerView;
- (NSTableColumn *) highlightedTableColumn;
- (void) highlightSelectionInClipRect:(NSRect) rect;
- (NSImage *) indicatorImageInTableColumn:(NSTableColumn *) col;
- (NSSize) intercellSpacing;
- (BOOL) isColumnSelected:(NSInteger) columnIndex;
- (BOOL) isRowSelected:(NSInteger) rowIndex;
- (void) moveColumn:(NSInteger) column toColumn:(NSInteger) newIndex;
- (void) noteHeightOfRowsWithIndexesChanged:(NSIndexSet *) indexes;
- (void) noteNumberOfRowsChanged;
- (NSInteger) numberOfColumns;
- (NSInteger) numberOfRows;
- (NSInteger) numberOfSelectedColumns;
- (NSInteger) numberOfSelectedRows;
- (NSCell *) preparedCellAtColumn:(NSInteger) col row:(NSInteger) row; 
- (NSRect) rectOfColumn:(NSInteger) column;
- (NSRect) rectOfRow:(NSInteger) row;
- (void) reloadData;
- (void) removeTableColumn:(NSTableColumn *) column;
- (NSInteger) rowAtPoint:(NSPoint) point;
- (CGFloat) rowHeight;
- (NSRange) rowsInRect:(NSRect) rect;
- (void) scrollColumnToVisible:(NSInteger) column;
- (void) scrollRowToVisible:(NSInteger) row;
- (void) selectAll:(id) sender;
- (void) selectColumnIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) extend;
- (void) selectColumn:(int) column byExtendingSelection:(BOOL) extend; /* DEPRECATED */
- (NSInteger) selectedColumn;
- (NSEnumerator *) selectedColumnEnumerator; /* DEPRECATED */
- (NSIndexSet *) selectedColumnIndexes;
- (NSInteger) selectedRow;
- (NSEnumerator *) selectedRowEnumerator; /* DEPRECATED */
- (NSIndexSet *) selectedRowIndexes;
- (NSTableViewSelectionHighlightStyle) selectionHighlightStyle; 
- (void) selectRow:(int) row byExtendingSelection:(BOOL) extend; /* ??? */
- (void) selectRowIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) extend;
- (void) setAllowsColumnReordering:(BOOL) flag;
- (void) setAllowsColumnResizing:(BOOL) flag;
- (void) setAllowsColumnSelection:(BOOL) flag;
- (void) setAllowsEmptySelection:(BOOL) flag;
- (void) setAllowsMultipleSelection:(BOOL) flag;
- (void) setAllowsTypeSelect:(BOOL) flag; 
- (void) setAutoresizesAllColumnsToFit:(BOOL) flag; /* DEPRECATED */
- (void) setAutosaveName:(NSString *) name;
- (void) setAutosaveTableColumns:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setColumnAutoresizingStyle:(NSTableViewColumnAutoresizingStyle) style;
- (void) setCornerView:(NSView *) cornerView;
- (void) setDataSource:(id) aSource;
- (void) setDelegate:(id) delegate;
- (void) setDoubleAction:(SEL) aSelector;
- (void) setDraggingSourceOperationMask:(NSDragOperation) mask forLocal:(BOOL) isLocal;
- (void) setDrawsGrid:(BOOL) flag; /* DEPRECATED */
- (void) setDropRow:(NSInteger) row dropOperation:(NSTableViewDropOperation) op;
- (void) setGridColor:(NSColor *) color;
- (void) setGridStyleMask:(NSUInteger) mask;
- (void) setHeaderView:(NSTableHeaderView *) headerView;
- (void) setHighlightedTableColumn:(NSTableColumn *) col;
- (void) setIndicatorImage:(NSImage *) img inTableColumn:(NSTableColumn *) col;
- (void) setIntercellSpacing:(NSSize) aSize;
- (void) setRowHeight:(CGFloat) rowHeight;
- (void) setSelectionHighlightStyle:(NSTableViewSelectionHighlightStyle) style; 
- (void) setSortDescriptors:(NSArray *) array;
- (void) setUsesAlternatingRowBackgroundColors:(BOOL) flag;
- (void) setVerticalMotionCanBeginDrag:(BOOL) flag;
- (void) sizeLastColumnToFit;
- (void) sizeToFit;
- (NSArray *) sortDescriptors;
- (NSArray *) tableColumns;
- (NSTableColumn *) tableColumnWithIdentifier:(id) identifier;
- (void) textDidBeginEditing:(NSNotification *) notification;
- (void) textDidChange:(NSNotification *) notification;
- (void) textDidEndEditing:(NSNotification *) notification;
- (BOOL) textShouldBeginEditing:(NSText *) textObject;
- (BOOL) textShouldEndEditing:(NSText *) textObject;
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
- (BOOL) selectionShouldChangeInTableView:(NSTableView *) aTableView;
- (NSCell *) tableView:(NSTableView *) tableView 
dataCellForTableColumn:(NSTableColumn *) tableColumn 
				   row:(NSInteger) row; 
- (void) tableView:(NSTableView *) tableView didClickTableColumn:(NSTableColumn *) col;
- (void) tableView:(NSTableView *) tableView didDragTableColumn:(NSTableColumn *) col;
- (CGFloat) tableView:(NSTableView *) tableView heightOfRow:(NSInteger) row;
- (BOOL) tableView:(NSTableView *) tableView isGroupRow:(NSInteger) row; 
- (void) tableView:(NSTableView *) tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *) col;
- (NSInteger) tableView:(NSTableView *) tableView 
			  nextTypeSelectMatchFromRow:(NSInteger) fromRow 
				  toRow:(NSInteger) toRow 
			  forString:(NSString *) searchStr; 
- (NSIndexSet *) tableView:(NSTableView *) tableView 
				 selectionIndexesForProposedSelection:(NSIndexSet *) indexes; 
- (BOOL) tableView:(NSTableView *) tableView 
		 shouldEditTableColumn:(NSTableColumn *) tableColumn 
			   row:(NSInteger) row;
- (BOOL) tableView:(NSTableView *) tableView shouldSelectRow:(NSInteger) row;
- (BOOL) tableView:(NSTableView *) tableView shouldSelectTableColumn:(NSTableColumn *) tableColumn;
- (BOOL) tableView:(NSTableView *) tableView 
		 shouldShowCellExpansionForTableColumn:(NSTableColumn *) tableColumn 
			   row:(NSInteger) row; 
- (BOOL) tableView:(NSTableView *) tableView 
   shouldTrackCell:(NSCell *) cell 
	forTableColumn:(NSTableColumn *) tableColumn 
			   row:(NSInteger) row; 
- (BOOL) tableView:(NSTableView *) tableView 
		 shouldTypeSelectForEvent:(NSEvent *) evt 
		 withCurrentSearchString:(NSString *) searchStr; 
- (NSString *) tableView:(NSTableView *) tableView
		  toolTipForCell:(NSCell *) cell
					rect:(NSRectPointer) rect
			 tableColumn:(NSTableColumn *) col
					 row:(NSInteger) row
		   mouseLocation:(NSPoint) mouse;
- (NSString *) tableView:(NSTableView *) tableView 
			   typeSelectStringForTableColumn:(NSTableColumn *) tableColumn 
					 row:(NSInteger) row; 
- (void) tableView:(NSTableView *) tableView 
   willDisplayCell:(id) cell 
	forTableColumn:(NSTableColumn *) tableColumn 
			   row:(NSInteger) row;

@end

@interface NSObject (NSTableViewNotifications)

- (void) tableViewColumnDidMove:(NSNotification *) notification;
- (void) tableViewColumnDidResize:(NSNotification *) notification;
- (void) tableViewSelectionDidChange:(NSNotification *) notification;
- (void) tableViewSelectionIsChanging:(NSNotification *) notification;

@end

															// Notifications
extern NSString *NSTableViewColumnDidMoveNotification;		// @"NSOldColumn", @"NSNewColumn"
extern NSString *NSTableViewColumnDidResizeNotification;	// @"NSTableColumn", @"NSOldWidth"
extern NSString *NSTableViewSelectionDidChangeNotification;
extern NSString *NSTableViewSelectionIsChangingNotification;


@interface NSObject (NSTableDataSource)						// Implemented by
															// the datasource
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tableView;
- (BOOL) tableView:(NSTableView *) tableView 
		acceptDrop:(id < NSDraggingInfo >) info 
			   row:(NSInteger) row 
	 dropOperation:(NSTableViewDropOperation) op;
- (NSArray *) tableView:(NSTableView *) tableView 
			  namesOfPromisedFilesDroppedAtDestination:(NSURL *) dest 
			  forDraggedRowsWithIndexes:(NSIndexSet *) indexes;
- (id) tableView:(NSTableView *) tableView 
	   objectValueForTableColumn:(NSTableColumn *) tableColumn 
			 row:(NSInteger)row;
- (void) tableView:(NSTableView *) tableView 
	setObjectValue:(id) object 
	forTableColumn:(NSTableColumn *) tableColumn 
			   row:(NSInteger) row;
- (void) tableView:(NSTableView *) tableView 
		 sortDescriptorsDidChange:(NSArray *) descriptors;
- (NSDragOperation) tableView:(NSTableView *) tableView 
				 validateDrop:(id < NSDraggingInfo >) info 
				  proposedRow:(NSInteger) row 
		proposedDropOperation:(NSTableViewDropOperation) op;
- (BOOL) tableView:(NSTableView *) tableView 
		 writeRows:(NSArray *) rows 
	  toPasteboard:(NSPasteboard *) pasteboard; /* DEPRECATED */
- (BOOL) tableView:(NSTableView *) tableView 
		 writeRowsWithIndexes:(NSIndexSet *) indexes 
	  toPasteboard:(NSPasteboard *) pasteboard; 

@end

#endif /* _mySTEP_H_NSTableView */
