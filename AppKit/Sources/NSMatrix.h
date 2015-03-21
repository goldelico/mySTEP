/* 
   NSMatrix.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	13. November 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSMatrix
#define _mySTEP_H_NSMatrix

#import <AppKit/NSControl.h>

@class NSArray;
@class NSMutableArray;
@class NSNotification;
@class NSCell;
@class NSColor;
@class NSText;
@class NSEvent;

typedef enum _NSMatrixMode {
    NSRadioModeMatrix	  = 0,
    NSHighlightModeMatrix = 1,
    NSListModeMatrix	  = 2,
    NSTrackModeMatrix	  = 3
} NSMatrixMode;


@interface NSMatrix : NSControl  <NSCoding>
{
	NSMutableArray *_cells;
	Class _cellClass;
	NSColor *backgroundColor;
	NSColor *cellBackgroundColor;
	id _cellPrototype;
	id _target;
	NSSize _cellSize;
	NSSize _interCell;
	SEL _action;
	SEL _doubleAction;
	SEL _errorAction;
	NSInteger _numRows;
	NSInteger _numCols;
	NSInteger _mouseDownFlags;

	struct __MatrixFlags {
		UIBITFIELD(unsigned int, allowsEmptySelect, 1);
		UIBITFIELD(unsigned int, selectionByRect, 1);
		UIBITFIELD(unsigned int, drawsBackground, 1);
		UIBITFIELD(unsigned int, drawsCellBackground, 1);
		UIBITFIELD(unsigned int, autosizesCells, 1);
		UIBITFIELD(unsigned int, autoscroll, 1);
		TYPEDBITFIELD(NSMatrixMode, mode, 2);
		UIBITFIELD(unsigned int, reserved, 24);
		} _m;
}

//+ (void) setCellClass:(Class) classId;
//+ (Class) cellClass;

- (BOOL) acceptsFirstMouse:(NSEvent *) event;			// Event processing
- (void) addColumn;
- (void) addColumnWithCells:(NSArray *) cellArray;		// Matrix layout
- (void) addRow;
- (void) addRowWithCells:(NSArray *) cellArray;
- (BOOL) allowsEmptySelection;							// Matrix Configuration
- (BOOL) autosizesCells;								// Resizing Matrix
- (NSColor *) backgroundColor;							// Graphic Attributes
- (id) cellAtRow:(NSInteger) row column:(NSInteger) column;			// Locate Cells
- (NSColor *) cellBackgroundColor;
- (Class) cellClass;
- (NSRect) cellFrameAtRow:(NSInteger) row column:(NSInteger) column;
- (NSArray *) cells;
- (NSSize) cellSize;
- (id) cellWithTag:(NSInteger) anInt;
- (id) delegate;
- (void) deselectAllCells;								// Selected Cells
- (void) deselectSelectedCell;
- (SEL) doubleAction;
- (void) drawCellAtRow:(NSInteger) row column:(NSInteger) column;		// Drawing
- (BOOL) drawsBackground;
- (BOOL) drawsCellBackground;
- (void) getNumberOfRows:(NSInteger *) rowCount columns:(NSInteger *) columnCount;
- (BOOL) getRow:(NSInteger *) row column:(NSInteger *) column forPoint:(NSPoint) aPoint;
- (BOOL) getRow:(NSInteger *) row column:(NSInteger *) column ofCell:(NSCell *) aCell;
- (void) highlightCell:(BOOL) flag atRow:(NSInteger) row column:(NSInteger) column;
- (id) initWithFrame:(NSRect) frameRect;
- (id) initWithFrame:(NSRect) frameRect
				mode:(NSInteger) aMode
		   cellClass:(Class) classId
		numberOfRows:(NSInteger) rowsHigh
	 numberOfColumns:(NSInteger) colsWide;
- (id) initWithFrame:(NSRect) frameRect
				mode:(NSInteger) aMode
		   prototype:(NSCell *) aCell
		numberOfRows:(NSInteger) rowsHigh
	 numberOfColumns:(NSInteger) colsWide;
- (void) insertColumn:(NSInteger) column;
- (void) insertColumn:(NSInteger) column withCells:(NSArray *) cellArray;
- (void) insertRow:(NSInteger) row;
- (void) insertRow:(NSInteger) row withCells:(NSArray *) cellArray;
- (NSSize) intercellSpacing;
- (BOOL) isAutoscroll;									// Scrolling
- (BOOL) isSelectionByRect;
- (id) keyCell; 
- (NSCell *) makeCellAtRow:(NSInteger) row column:(NSInteger) column;
- (NSMatrixMode) mode;
- (void) mouseDown:(NSEvent *) event;
- (NSInteger) mouseDownFlags;
- (NSInteger) numberOfColumns;
- (NSInteger) numberOfRows;
- (BOOL) performKeyEquivalent:(NSEvent *) event; 
- (id) prototype;
- (void) putCell:(NSCell *) newCell atRow:(NSInteger) row column:(NSInteger) column;
- (void) removeColumn:(NSInteger) column;
- (void) removeRow:(NSInteger) row;
- (void) renewRows:(NSInteger) newRows columns:(NSInteger) newColumns;
- (void) resetCursorRects;								// Managing Cursor
- (void) scrollCellToVisibleAtRow:(NSInteger) row column:(NSInteger) column;
- (void) selectAll:(id) sender;
- (void) selectCellAtRow:(NSInteger) row column:(NSInteger) column;
- (BOOL) selectCellWithTag:(NSInteger) anInt;
- (id) selectedCell;
- (NSArray *) selectedCells;
- (NSInteger) selectedColumn;
- (NSInteger) selectedRow;
- (void) selectText:(id) sender;							// Editing Text
- (id) selectTextAtRow:(NSInteger) row column:(NSInteger) column;
- (BOOL) sendAction;
- (void) sendAction:(SEL) aSelector to:(id) anObject forAllCells:(BOOL) flag;
- (void) sendDoubleAction;
- (void) setAllowsEmptySelection:(BOOL) flag;
- (void) setAutoscroll:(BOOL) flag;
- (void) setAutosizesCells:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) aColor;
- (void) setCellBackgroundColor:(NSColor *) aColor;
- (void) setCellClass:(Class) classId;
- (void) setCellSize:(NSSize) aSize;
- (void) setDelegate:(id) anObject;						// Delegate
- (void) setDoubleAction:(SEL) aSelector;
- (void) setDrawsBackground:(BOOL) flag;
- (void) setDrawsCellBackground:(BOOL) flag;
- (void) setIntercellSpacing:(NSSize) aSize;
- (void) setKeyCell:(NSCell *) cell; 
- (void) setMode:(NSMatrixMode) aMode;					// Selection Mode
- (void) setPrototype:(NSCell *) aCell;					// Cell Class
- (void) setScrollable:(BOOL) flag;
- (void) setSelectionByRect:(BOOL) flag;
- (void) setSelectionFrom:(NSInteger) startPos
					   to:(NSInteger) endPos
				   anchor:(NSInteger) anchorPos
				highlight:(BOOL) flag;
- (void) setState:(NSInteger) value atRow:(NSInteger) row column:(NSInteger) column;
- (void) setTabKeyTraversesCells:(BOOL) flag; 
- (void) setToolTip:(NSString *) string forCell:(NSCell *) cell; 
- (void) setValidateSize:(BOOL) flag;
- (void) sizeToCells;
- (void) sortUsingFunction:(NSInteger(*)(id element1, id element2, void *userData)) cp
				   context:(void *) context;
- (void) sortUsingSelector:(SEL) comparator;
- (BOOL) tabKeyTraversesCells; 
- (void) textDidBeginEditing:(NSNotification *) notification;
- (void) textDidChange:(NSNotification *) notification;
- (void) textDidEndEditing:(NSNotification *) notification;
- (BOOL) textShouldBeginEditing:(NSText *) textObject;
- (BOOL) textShouldEndEditing:(NSText *) textObject;
- (NSString *) toolTipForCell:(NSCell *) cell;

@end

#endif /* _mySTEP_H_NSMatrix */
