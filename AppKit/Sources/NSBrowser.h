/* 
   NSBrowser.h

   Control to display and access hierarchal data

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:	Felipe A. Rodriguez <far@pcmagic.net>
   Date:	March 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	19. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBrowser
#define _mySTEP_H_NSBrowser

#import <AppKit/NSControl.h>
#import <AppKit/NSDragging.h>

@class NSString;
@class NSArray;
@class NSCell;
@class NSMatrix;
@class NSScroller;

typedef enum _NSBrowserColumnResizingType
{
	NSBrowserNoColumnResizing = 0,
	NSBrowserAutoColumnResizing,
	NSBrowserUserColumnResizing
} NSBrowserColumnResizingType;

enum {
	NSBrowserDropOn,
	NSBrowserDropAbove
};
typedef NSUInteger NSBrowserDropOperation;

@interface NSBrowser : NSControl  <NSCoding>
{
	NSString *_pathSeparator;
    NSMutableArray *_titles;
	NSMutableArray *_columns;
    NSMutableArray *_unusedColumns;
	NSScroller *_scroller;
	SEL _doubleAction;
	Class _matrixClass;
	id _cellPrototype;
	NSSize _columnSize;
	float _minColumnWidth;
	float _preferedColumnWidth;
	NSBrowserColumnResizingType _columnResizing;
	int _numberOfVisibleColumns;
	int _firstVisibleColumn;
	int _maxVisibleColumns;
	BOOL _isLoaded;
	
	struct __BrowserFlags {
		unsigned int allowsMultipleSelection:1;
		unsigned int allowsBranchSelection:1;
		unsigned int allowsEmptySelection:1;
		unsigned int reuseColumns:1;
		unsigned int isTitled:1;
		unsigned int hasHorizontalScroller:1;
		unsigned int sendActionOnArrowKeys:1;
		unsigned int separatesColumns:1;
		unsigned int titleFromPrevious:1;
		unsigned int acceptArrowKeys:1;
		unsigned int delegateCreatesRowsInMatrix:1;			// NO if passive
		unsigned int delegateImplementsWillDisplayCell:1;
		unsigned int delegateSelectsCellsByRow:1;
		unsigned int delegateSelectsCellsByString:1;
		unsigned int delegateSetsTitles:1;
		unsigned int reserved:1;
		} _br;
}

+ (Class) cellClass;									// Component Classes
+ (void) removeSavedColumnsWithAutosaveName:(NSString *) autosaveName;

- (BOOL) acceptsArrowKeys;								// Arrow Key Behavior
- (void) addColumn;										
- (BOOL) allowsBranchSelection;							// Selection behavior
- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (BOOL) allowsTypeSelect;
- (NSColor *) backgroundColor;
- (BOOL) canDragRowsWithIndexes:(NSIndexSet *) rowIds inColumn:(NSInteger) colId withEvent:(NSEvent *) event;
- (id) cellPrototype;
- (CGFloat)columnContentWidthForColumnWidth:(CGFloat)width;
- (NSInteger) columnOfMatrix:(NSMatrix *) mtx;				// Manipulating Columns
- (NSBrowserColumnResizingType) columnResizingType;
- (NSString *) columnsAutosaveName;
- (CGFloat) columnWidthForColumnContentWidth:(CGFloat) colWith;
- (id) delegate;										// delegate
- (void) displayAllColumns;
- (void) displayColumn:(int) col;
- (void) doClick:(id) sender;							// Event Handling
- (void) doDoubleClick:(id) sender;
- (SEL) doubleAction;	// Target / Action
- (NSImage *) draggingImageForRowsWithIndexes:(NSIndexSet *) rowIds 
									 inColumn:(NSInteger) colId 
									withEvent:(NSEvent *) event 
									   offset:(NSPointPointer) offset;
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) dest;
- (void) drawTitleOfColumn:(NSInteger) col inRect:(NSRect) rect;
- (void) drawTitle:(NSString *) title inRect:(NSRect) rect ofColumn:(int) col; /* THIS METHOD DOESNT EXIST IN API */
- (NSInteger) firstVisibleColumn;
- (NSRect) frameOfColumn:(NSInteger) col;					// Column Frames
- (NSRect) frameOfInsideOfColumn:(NSInteger) col;
- (BOOL) hasHorizontalScroller;
- (BOOL) isLoaded;
- (BOOL) isTitled;										// Column Titles
- (NSInteger) lastColumn;
- (NSInteger) lastVisibleColumn;
- (void) loadColumnZero;
- (id) loadedCellAtRow:(NSInteger) row column:(NSInteger) col;		// Matrices and Cells
- (Class) matrixClass;
- (NSMatrix *) matrixInColumn:(NSInteger) col;
- (NSInteger) maxVisibleColumns;								// NSBrowser Appearance
- (CGFloat) minColumnWidth;
- (NSArray *) namesOfPromisedFilesDroppedAtDestination:(NSURL *) dest;
- (NSInteger) numberOfVisibleColumns;
- (NSString *) path;										// Manipulating Paths
- (NSString *) pathSeparator;
- (NSString *) pathToColumn:(NSInteger) col;
- (BOOL) prefersAllColumnUserResizing;
- (void) reloadColumn:(NSInteger) col;
- (BOOL) reusesColumns;									// NSBrowser Behavior
- (void) scrollColumnsLeftBy:(NSInteger) amount;			// NSBrowser Scrolling
- (void) scrollColumnsRightBy:(NSInteger) amount;
- (void) scrollColumnToVisible:(NSInteger) col;
- (void) scrollViaScroller:(NSScroller *) sender;
- (void) selectAll:(id) sender;
- (id) selectedCell;
- (id) selectedCellInColumn:(NSInteger) col;
- (NSArray *) selectedCells;
- (NSInteger) selectedColumn;
- (NSInteger) selectedRowInColumn:(NSInteger) col;
- (NSIndexSet *) selectedRowIndexesInColumn:(NSInteger) col;
- (void) selectRow:(NSInteger) row inColumn:(NSInteger) col;
- (BOOL) sendAction;
- (BOOL) sendsActionOnArrowKeys;
- (BOOL) separatesColumns;
- (void) setAcceptsArrowKeys:(BOOL) flag;
- (void) setAllowsBranchSelection:(BOOL) flag;
- (void) setAllowsEmptySelection:(BOOL) flag;
- (void) setAllowsMultipleSelection:(BOOL) flag;
- (void) setAllowsTypeSelect:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color; 
- (void) setCellClass:(Class) classId;
- (void) setCellPrototype:(NSCell *) cell;
- (void) setColumnResizingType:(NSBrowserColumnResizingType) type;
- (void) setColumnsAutosaveName:(NSString *) autosaveName;
- (void) setDelegate:(id) delegate;
- (void) setDoubleAction:(SEL) sel;
- (void) setDraggingSourceOperationMask:(NSDragOperation) opMask forLocal:(BOOL) dest;
- (void) setHasHorizontalScroller:(BOOL) flag;			// Horizontal Scroller
- (void) setLastColumn:(NSInteger) col;
- (void) setMatrixClass:(Class) classId;
- (void) setMaxVisibleColumns:(NSInteger) colCount;
- (void) setMinColumnWidth:(CGFloat) colWidth;
- (BOOL) setPath:(NSString *) path;
- (void) setPathSeparator:(NSString *) string;
- (void) setPrefersAllColumnUserResizing:(BOOL) flag;
- (void) setReusesColumns:(BOOL) flag;
- (void) setSendsActionOnArrowKeys:(BOOL) flag;
- (void) setSeparatesColumns:(BOOL) flag;
- (void) setTakesTitleFromPreviousColumn:(BOOL) flag;
- (void) setTitle:(NSString *) title ofColumn:(NSInteger) col;
- (void) setTitled:(BOOL) flag;
- (void) setWidth:(CGFloat) colWidth ofColumn:(NSInteger) colIndex;
- (BOOL) takesTitleFromPreviousColumn;
- (void) tile;											// Layout support
- (NSRect) titleFrameOfColumn:(NSInteger) col;
- (CGFloat) titleHeight;
- (NSString *) titleOfColumn:(NSInteger) col;
- (void) updateScroller;
- (void) validateVisibleColumns;
- (CGFloat) widthOfColumn:(NSInteger) col;

@end


@interface NSObject (NSBrowserDelegate)					// to be implemented by
														// the delegate
- (BOOL) browser:(NSBrowser *) sender 
	  acceptDrop:(id <NSDraggingInfo>) info 
		   atRow:(NSInteger) rowId 
		  column:(NSInteger) colId 
   dropOperation:(NSBrowserDropOperation) dropOp;
- (BOOL) browser:(NSBrowser *) sender canDragRowsWithIndexes:(NSIndexSet *) rowIds inColumn:(NSInteger) col withEvent:(NSEvent *) event;
- (void) browser:(NSBrowser *) sender createRowsForColumn:(NSInteger) col inMatrix:(NSMatrix *) mtx;
- (NSImage *) browser:(NSBrowser *) sender 
draggingImageForRowsWithIndexes:(NSIndexSet *) rowIds 
			 inColumn:(NSInteger) col 
			withEvent:(NSEvent *) event 
			   offset:(NSPointPointer) offset;
- (BOOL) browser:(NSBrowser *) sender isColumnValid:(NSInteger) col;
- (NSArray *) browser:(NSBrowser *) sender namesOfPromisedFilesDroppedAtDestination:(NSURL *) url forDraggedRowsWithIndexes:(NSIndexSet *) rowIds inColumn:(NSInteger) col;
- (NSInteger) browser:(NSBrowser *) sender nextTypeSelectMatchFromRow:(NSInteger) startRow toRow:(NSInteger) endRow inColumn:(NSInteger) col forString:(NSString *) keyword;
- (NSInteger) browser:(NSBrowser *) sender numberOfRowsInColumn:(NSInteger) col;
- (BOOL) browser:(NSBrowser *) sender selectCellWithString:(NSString *) title inColumn:(NSInteger) col;
- (BOOL) browser:(NSBrowser *) sender selectRow:(NSInteger) row inColumn:(NSInteger) col;
- (BOOL) browser:(NSBrowser *) sender shouldShowCellExpansionForRow:(NSInteger) row column:(NSInteger) col;
- (CGFloat) browser:(NSBrowser *) sender shouldSizeColumn:(NSInteger) col forUserResize:(BOOL) flag toWidth:(CGFloat) width;
- (BOOL) browser:(NSBrowser *) sender shouldTypeSelectForEvent:(NSEvent *) event withCurrentSearchString:(NSString *) keyword;
- (CGFloat) browser:(NSBrowser *) sender sizeToFitWidthOfColumn:(NSInteger) colIndex;
- (NSString *) browser:(NSBrowser *) sender titleOfColumn:(NSInteger) col;
- (NSString *) browser:(NSBrowser *) sender typeSelectStringForRow:(NSInteger) row inColumn:(NSInteger) col;
- (NSDragOperation) browser:(NSBrowser *) sender 
			   validateDrop:(id <NSDraggingInfo>) info 
				proposedRow:(NSInteger *) row 
					 column:(NSInteger *) col 
			  dropOperation:(NSBrowserDropOperation *) dropOp;
- (void) browser:(NSBrowser *) sender willDisplayCell:(id) cell atRow:(NSInteger) row column:(NSInteger) col;
- (BOOL) browser:(NSBrowser *) sender writeRowsWithIndexes:(NSIndexSet *) rowIds inColumn:(NSInteger) col toPasteboard:(NSPasteboard *) pboard;
- (void) browserColumnConfigurationDidChange:(NSNotification *) notif;
- (void) browserDidScroll:(NSBrowser *) sender;
- (void) browserWillScroll:(NSBrowser *) sender;

@end

extern NSString *NSBrowserIllegalDelegateException;
extern NSString *NSBrowserColumnConfigurationDidChangeNotification;

#endif /* _mySTEP_H_NSBrowser */
