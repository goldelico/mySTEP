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
+ (void) removeSavedColumnsWithAutosaveName:(NSString *) autosaveName;

- (BOOL) acceptsArrowKeys;								// Arrow Key Behavior
- (void) addColumn;										
- (BOOL) allowsBranchSelection;							// Selection behavior
- (BOOL) allowsEmptySelection;
- (BOOL) allowsMultipleSelection;
- (id) cellPrototype;
- (float)columnContentWidthForColumnWidth:(float)width;
- (int) columnOfMatrix:(NSMatrix *) mtx;				// Manipulating Columns
- (NSBrowserColumnResizingType) columnResizingType;
- (NSString *) columnsAutosaveName;
- (float) columnWidthForColumnContentWidth:(float) colWith;
- (id) delegate;										// delegate
- (void) displayAllColumns;
- (void) displayColumn:(int) col;
- (void) doClick:(id) sender;							// Event Handling
- (void) doDoubleClick:(id) sender;
- (SEL) doubleAction;									// Target / Action
- (void) drawTitleOfColumn:(int)col inRect:(NSRect)rect;
- (void) drawTitle:(NSString *) title inRect:(NSRect) rect ofColumn:(int) col; /* THIS METHOD DOESNT EXIST IN API */
- (int) firstVisibleColumn;
- (NSRect) frameOfColumn:(int) col;					// Column Frames
- (NSRect) frameOfInsideOfColumn:(int) col;
- (BOOL) hasHorizontalScroller;
- (BOOL) isLoaded;
- (BOOL) isTitled;										// Column Titles
- (int) lastColumn;
- (int) lastVisibleColumn;
- (void) loadColumnZero;
- (id) loadedCellAtRow:(int) row column:(int) col;		// Matrices and Cells
- (Class) matrixClass;
- (NSMatrix *) matrixInColumn:(int) col;
- (int) maxVisibleColumns;								// NSBrowser Appearance
- (float) minColumnWidth;
- (int) numberOfVisibleColumns;
- (NSString*) path;										// Manipulating Paths
- (NSString*) pathSeparator;
- (NSString*) pathToColumn:(int) col;
- (BOOL) prefersAllColumnUserResizing;
- (void) reloadColumn:(int) col;
- (BOOL) reusesColumns;									// NSBrowser Behavior
- (void) scrollColumnsLeftBy:(int) amount;			// NSBrowser Scrolling
- (void) scrollColumnsRightBy:(int) amount;
- (void) scrollColumnToVisible:(int) col;
- (void) scrollViaScroller:(NSScroller *) sender;
- (void) selectAll:(id) sender;
- (id) selectedCell;
- (id) selectedCellInColumn:(int) col;
- (NSArray *) selectedCells;
- (int) selectedColumn;
- (int) selectedRowInColumn:(int) col;
- (void) selectRow:(int) row inColumn:(int) col;
- (BOOL) sendAction;
- (BOOL) sendsActionOnArrowKeys;
- (BOOL) separatesColumns;
- (void) setAcceptsArrowKeys:(BOOL) flag;
- (void) setAllowsBranchSelection:(BOOL) flag;
- (void) setAllowsEmptySelection:(BOOL) flag;
- (void) setAllowsMultipleSelection:(BOOL) flag;
- (void) setCellClass:(Class) classId;
- (void) setCellPrototype:(NSCell *) cell;
- (void) setColumnResizingType:(NSBrowserColumnResizingType) type;
- (void) setColumnsAutosaveName:(NSString *) autosaveName;
- (void) setDelegate:(id) delegate;
- (void) setDoubleAction:(SEL) sel;
- (void) setHasHorizontalScroller:(BOOL) flag;			// Horizontal Scroller
- (void) setLastColumn:(int) col;
- (void) setMatrixClass:(Class) classId;
- (void) setMaxVisibleColumns:(int) colCount;
- (void) setMinColumnWidth:(float) colWidth;
- (BOOL) setPath:(NSString *) path;
- (void) setPathSeparator:(NSString *) string;
- (void) setPrefersAllColumnUserResizing:(BOOL) flag;
- (void) setReusesColumns:(BOOL) flag;
- (void) setSendsActionOnArrowKeys:(BOOL) flag;
- (void) setSeparatesColumns:(BOOL) flag;
- (void) setTakesTitleFromPreviousColumn:(BOOL) flag;
- (void) setTitle:(NSString *) title ofColumn:(int) col;
- (void) setTitled:(BOOL) flag;
- (void) setWidth:(float)colWidth ofColumn:(int)colIndex;
- (BOOL) takesTitleFromPreviousColumn;
- (void) tile;											// Layout support
- (NSRect) titleFrameOfColumn:(int) col;
- (float) titleHeight;
- (NSString *) titleOfColumn:(int) col;
- (void) updateScroller;
- (void) validateVisibleColumns;
- (float) widthOfColumn:(int) col;

@end


@interface NSObject (NSBrowserDelegate)					// to be implemented by
														// the delegate
- (void) browser:(NSBrowser *) sender createRowsForColumn:(int) col inMatrix:(NSMatrix *) mtx;
- (BOOL) browser:(NSBrowser *) sender isColumnValid:(int) col;
- (int) browser:(NSBrowser *) sender numberOfRowsInColumn:(int) col;
- (BOOL) browser:(NSBrowser *) sender selectCellWithString:(NSString *) title inColumn:(int) col;
- (BOOL) browser:(NSBrowser *) sender selectRow:(int) row inColumn:(int) col;
- (NSString*) browser:(NSBrowser *) sender titleOfColumn:(int) col;
- (void) browser:(NSBrowser *) sender willDisplayCell:(id) cell atRow:(int) row column:(int) col;
- (void) browserDidScroll:(NSBrowser *) sender;
- (void) browserWillScroll:(NSBrowser *) sender;
- (float) browser:(NSBrowser *) sender shouldSizeColumn:(int) col forUserResize:(BOOL) flag toWidth:(float) w;
- (float) browser:(NSBrowser *) sender sizeToFitWidthOfColumn:(int) colIndex;
- (void) browserColumnConfigurationDidChange:(NSNotification *) notif;

@end

extern NSString *NSBrowserIllegalDelegateException;
extern NSString *NSBrowserColumnConfigurationDidChangeNotification;

#endif /* _mySTEP_H_NSBrowser */
