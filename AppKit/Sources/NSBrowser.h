/* 
   NSBrowser.h

   Control to display and access hierarchal data

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:	Felipe A. Rodriguez <far@pcmagic.net>
   Date:	March 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBrowser
#define _mySTEP_H_NSBrowser

#import <AppKit/NSControl.h>

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
+ (void) removeSavedColumnsWithAutosaveName:(NSString *) name;

- (BOOL) acceptsArrowKeys;								// Arrow Key Behavior
- (void) addColumn;										
- (BOOL) allowsBranchSelection;							// Selection behavior
- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (id) cellPrototype;
- (int) columnOfMatrix:(NSMatrix *)matrix;				// Manipulating Columns
- (NSBrowserColumnResizingType) columnResizingType;
- (NSString *) columnsAutosaveName;
- (float) columnWidthForColumnContentWidth:(float) columnContentWidth;
- (id) delegate;										// delegate
- (void) displayAllColumns;
- (void) displayColumn:(int)column;
- (void) doClick:(id)sender;							// Event Handling
- (void) doDoubleClick:(id)sender;
- (SEL) doubleAction;									// Target / Action
- (void) drawTitle:(NSString *)title inRect:(NSRect)aRect ofColumn:(int)column;
- (int) firstVisibleColumn;
- (NSRect) frameOfColumn:(int)column;					// Column Frames
- (NSRect) frameOfInsideOfColumn:(int)column;
- (BOOL) hasHorizontalScroller;
- (BOOL) isLoaded;
- (BOOL) isTitled;										// Column Titles
- (int) lastColumn;
- (int) lastVisibleColumn;
- (void) loadColumnZero;
- (id) loadedCellAtRow:(int)row column:(int)column;		// Matrices and Cells
- (Class) matrixClass;
- (NSMatrix *) matrixInColumn:(int)column;
- (int) maxVisibleColumns;								// NSBrowser Appearance
- (float) minColumnWidth;
- (int) numberOfVisibleColumns;
- (NSString*) path;										// Manipulating Paths
- (NSString*) pathSeparator;
- (NSString*) pathToColumn:(int)column;
- (BOOL) prefersAllColumnUserResizing;
- (void) reloadColumn:(int)column;
- (BOOL) reusesColumns;									// NSBrowser Behavior
- (void) scrollColumnsLeftBy:(int)shiftAmount;			// NSBrowser Scrolling
- (void) scrollColumnsRightBy:(int)shiftAmount;
- (void) scrollColumnToVisible:(int)column;
- (void) scrollViaScroller:(NSScroller *)sender;
- (void) selectAll:(id)sender;
- (id) selectedCell;
- (id) selectedCellInColumn:(int)column;
- (NSArray *) selectedCells;
- (int) selectedColumn;
- (int) selectedRowInColumn:(int)column;
- (void) selectRow:(int)row inColumn:(int)column;
- (BOOL) sendAction;
- (BOOL) sendsActionOnArrowKeys;
- (BOOL) separatesColumns;
- (void) setAcceptsArrowKeys:(BOOL)flag;
- (void) setAllowsBranchSelection:(BOOL)flag;
- (void) setAllowsEmptySelection:(BOOL)flag;
- (void) setAllowsMultipleSelection:(BOOL)flag;
- (void) setCellClass:(Class)classId;
- (void) setCellPrototype:(NSCell *)aCell;
- (void) setColumnResizingType:(NSBrowserColumnResizingType) type;
- (void) setColumnsAutosaveName:(NSString *)name;
- (void) setDelegate:(id)anObject;
- (void) setDoubleAction:(SEL)aSelector;
- (void) setHasHorizontalScroller:(BOOL)flag;			// Horizontal Scroller
- (void) setLastColumn:(int)column;
- (void) setMatrixClass:(Class)classId;
- (void) setMaxVisibleColumns:(int)columnCount;
- (void) setMinColumnWidth:(float)columnWidth;
- (BOOL) setPath:(NSString *)path;
- (void) setPathSeparator:(NSString *)aString;
- (void) setPrefersAllColumnUserResizing:(BOOL)flag;
- (void) setReusesColumns:(BOOL)flag;
- (void) setSendsActionOnArrowKeys:(BOOL)flag;
- (void) setSeparatesColumns:(BOOL)flag;
- (void) setTakesTitleFromPreviousColumn:(BOOL)flag;
- (void) setTitle:(NSString *)aString ofColumn:(int)column;
- (void) setTitled:(BOOL)flag;
- (void) setWidth:(float)columnWidth ofColumn:(int)columnIndex;
- (BOOL) takesTitleFromPreviousColumn;
- (void) tile;											// Layout support
- (NSRect) titleFrameOfColumn:(int)column;
- (float) titleHeight;
- (NSString *) titleOfColumn:(int)column;
- (void) updateScroller;
- (void) validateVisibleColumns;
- (float) widthOfColumn:(int)column;

@end


@interface NSObject (NSBrowserDelegate)					// to be implemented by
														// the delegate
- (void) browser:(NSBrowser *)sender
		 createRowsForColumn:(int)column
		 inMatrix:(NSMatrix *)matrix;
- (BOOL) browser:(NSBrowser *)sender isColumnValid:(int)column;
- (int) browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
- (BOOL) browser:(NSBrowser *)sender
		 selectCellWithString:(NSString *)title
		 inColumn:(int)column;
- (BOOL) browser:(NSBrowser *)sender selectRow:(int)row inColumn:(int)column;
- (NSString*) browser:(NSBrowser *)sender titleOfColumn:(int)column;
- (void) browser:(NSBrowser *)sender
		 willDisplayCell:(id)cell
		 atRow:(int)row
		 column:(int)column;
- (void) browserDidScroll:(NSBrowser *)sender;
- (void) browserWillScroll:(NSBrowser *)sender;
- (float) browser:(NSBrowser *)browser
		  shouldSizeColumn:(int)column
		  forUserResize:(BOOL)flag
		  toWidth:(float)width;
- (float) browser:(NSBrowser *)browser
		  sizeToFitWidthOfColumn:(int)column;
- (void) browserColumnConfigurationDidChange:(NSNotification *)notification;

@end

extern NSString *NSBrowserIllegalDelegateException;
extern NSString *NSBrowserColumnConfigurationDidChangeNotification;

#endif /* _mySTEP_H_NSBrowser */
